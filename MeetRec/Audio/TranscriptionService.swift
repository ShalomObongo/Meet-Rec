//
//  TranscriptionService.swift
//  MeetRec
//
//  Created by Kiro on 11/16/25.
//

import Foundation
import Speech
import AVFoundation
import Combine
import CoreData

@MainActor
@Observable
final class TranscriptionService {
    var words: [TranscribedWord] = []
    var isTranscribing: Bool = false
    var errorMessage: String?

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var persistenceQueue: TranscriptPersistenceQueue?
    private var recordingStartTime: Date?
    private var audioStartTime: Date?
    private var segmentIdToWordId: [String: UUID] = [:] // Map segment IDs to word IDs for confidence updates
    
    init() {
        // Initialize with English (US) locale
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    func startTranscription(sessionId: UUID, recordingStartTime: Date, viewContext: NSManagedObjectContext) async throws {
        print("🎙️ Starting transcription")

        // Request speech recognition authorization
        let authStatus = await requestAuthorization()
        guard authStatus == .authorized else {
            throw TranscriptionError.authorizationDenied
        }

        // Check if speech recognizer is available
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }

        // Store recording start time and mark audio as ready
        // Set this BEFORE starting recognition to avoid race conditions
        self.recordingStartTime = recordingStartTime
        self.audioStartTime = Date()

        // Initialize persistence queue if needed
        if persistenceQueue == nil {
            persistenceQueue = TranscriptPersistenceQueue(sessionId: sessionId, viewContext: viewContext)
        }

        // Clear segment tracking only on initial start
        segmentIdToWordId.removeAll()

        isTranscribing = true

        // Start a new recognition segment
        try await startRecognitionSegment()

        print("✅ Transcription started")
    }
    
    private func startRecognitionSegment() async throws {
        guard let recognizer = speechRecognizer else { return }
        
        // Create recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        
        // Enable on-device recognition if available
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
            print("✅ Using on-device speech recognition")
        } else {
            print("⚠️ On-device recognition not available, using server-based recognition")
        }
        
        self.recognitionRequest = request

        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            Task { @MainActor in
                // Early return if we've stopped transcribing (prevents processing stale callbacks)
                guard self.isTranscribing else {
                    return
                }

                if let error = error {
                    let nsError = error as NSError

                    // Ignore cancellation errors (code 301) - these are expected when stopping
                    if nsError.domain == "kLSRErrorDomain" && nsError.code == 301 {
                        print("ℹ️ Recognition request ended (user stopped)")
                        return
                    }

                    // Check if it's a timeout error (code 216 or 203) - 1-minute limit
                    if nsError.domain == "kLSRErrorDomain" && (nsError.code == 216 || nsError.code == 203) {
                        print("⚠️ Recognition segment ended (1-minute limit), restarting...")
                        // Process any final result before restarting
                        if let result = result {
                            self.processTranscriptionResult(result)
                        }
                        // Restart recognition automatically to continue transcription
                        if self.isTranscribing {
                            do {
                                try await self.restartRecognitionSegment()
                                print("✅ Recognition segment restarted successfully")
                            } catch {
                                print("❌ Failed to restart recognition: \(error)")
                                self.errorMessage = "Transcription restart failed: \(error.localizedDescription)"
                            }
                        }
                        return
                    }

                    // Only log unexpected errors
                    print("❌ Recognition error: \(error) (code: \(nsError.code))")
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let result = result else { return }

                // Process transcription results
                self.processTranscriptionResult(result)
            }
        }
    }
    
    private func restartRecognitionSegment() async throws {
        // Important: Do NOT clear processedSegments here - we need to maintain
        // continuity across segment restarts to avoid duplicate processing

        print("🔄 Restarting recognition segment...")

        // Store reference to old task for cleanup
        let oldTask = recognitionTask
        let oldRequest = recognitionRequest

        // Immediately start new segment to minimize audio loss gap
        // This creates a new recognitionRequest that will receive future audio buffers
        try await startRecognitionSegment()

        // Now clean up the old task
        // Signal end of audio to the old request
        oldRequest?.endAudio()

        // Cancel the old task (this will trigger the callback with error 301, which we ignore)
        oldTask?.cancel()

        print("🔄 Recognition segment restart complete - continuing transcription")
    }
    
    func stopTranscription() {
        print("🎙️ Stopping transcription")

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        isTranscribing = false
        recordingStartTime = nil
        audioStartTime = nil
        segmentIdToWordId.removeAll()

        // Flush any remaining words to Core Data
        if let queue = persistenceQueue {
            Task {
                await queue.flush()
            }
        }

        print("✅ Transcription stopped")
    }
    
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Only append if we're actively transcribing
        guard isTranscribing, let request = recognitionRequest else {
            return
        }
        request.append(buffer)
    }
    
    // MARK: - Private Methods
    
    private func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    private func processTranscriptionResult(_ result: SFSpeechRecognitionResult) {
        let transcription = result.bestTranscription
        let segments = transcription.segments

        // Double-check we're still transcribing (defensive check against race conditions)
        guard isTranscribing else {
            return
        }

        // Collect new words and updates
        var newWords: [TranscribedWord] = []
        var updatedWords: [(index: Int, confidence: Double)] = []

        for segment in segments {
            // Create unique ID for this segment based on text, timestamp, and duration
            let segmentId = "\(segment.substring)_\(Int(segment.timestamp * 1000))_\(Int(segment.duration * 1000))"

            // segment.timestamp is in seconds from the start of audio processing
            let startMs = Int64(segment.timestamp * 1000)
            let endMs = Int64((segment.timestamp + segment.duration) * 1000)
            let confidence = Double(segment.confidence)

            // Check if we've seen this segment before
            if let existingWordId = segmentIdToWordId[segmentId] {
                // Found existing word - update confidence if this is a final result
                if result.isFinal {
                    if let index = words.firstIndex(where: { $0.id == existingWordId }) {
                        updatedWords.append((index: index, confidence: confidence))
                    }
                }
                // Skip adding this segment again (already exists)
                continue
            }

            // New segment - create word
            let word = TranscribedWord(
                text: segment.substring,
                startMs: startMs,
                endMs: endMs,
                channel: "mic",
                confidence: confidence,
                isFinal: result.isFinal
            )

            newWords.append(word)
            segmentIdToWordId[segmentId] = word.id
        }

        // Update existing words with final confidence values
        for update in updatedWords {
            words[update.index].confidence = update.confidence
            words[update.index].isFinal = true
            print("✓ Updated word '\(words[update.index].text)' with final confidence: \(String(format: "%.2f", update.confidence))")
        }

        // Add new words
        if !newWords.isEmpty {
            words.append(contentsOf: newWords)

            // Send to persistence queue
            if let queue = persistenceQueue {
                Task {
                    await queue.addWords(newWords)
                }
            }

            // Log with confidence scores
            for word in newWords {
                print("📝 '\(word.text)' - confidence: \(String(format: "%.2f", word.confidence)) [isFinal: \(word.isFinal)]")
            }
            print("📝 Added \(newWords.count) new words (total: \(words.count))")
        }

        // If this is a final result, we might get a restart soon
        if result.isFinal {
            print("✓ Final result received with \(segments.count) total segments")
        }
    }
}

// MARK: - Error Types

enum TranscriptionError: LocalizedError {
    case authorizationDenied
    case recognizerUnavailable
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Speech recognition permission is required for transcription. Please grant permission in System Settings."
        case .recognizerUnavailable:
            return "Speech recognizer is not available. Please check your internet connection or try again later."
        }
    }
}

// MARK: - Persistence Queue Actor

actor TranscriptPersistenceQueue {
    private let sessionId: UUID
    private let viewContext: NSManagedObjectContext
    private var pendingWords: [TranscribedWord] = []
    private var transcript: Transcript?
    private let batchSize = 100
    
    init(sessionId: UUID, viewContext: NSManagedObjectContext) {
        self.sessionId = sessionId
        self.viewContext = viewContext
    }
    
    func addWords(_ words: [TranscribedWord]) async {
        pendingWords.append(contentsOf: words)
        
        // Batch save every 100 words
        if pendingWords.count >= batchSize {
            await savePendingWords()
        }
    }
    
    func flush() async {
        if !pendingWords.isEmpty {
            await savePendingWords()
        }
    }
    
    private func savePendingWords() async {
        let wordsToSave = pendingWords
        pendingWords.removeAll()
        
        await viewContext.perform {
            // Get or create transcript
            if self.transcript == nil {
                let fetchRequest: NSFetchRequest<Session> = Session.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", self.sessionId as CVarArg)
                
                if let session = try? self.viewContext.fetch(fetchRequest).first {
                    let newTranscript = Transcript(context: self.viewContext)
                    newTranscript.id = UUID()
                    newTranscript.createdAt = Date()
                    newTranscript.startedAt = Date()
                    newTranscript.session = session
                    self.transcript = newTranscript
                }
            }
            
            guard let transcript = self.transcript else {
                print("❌ Failed to get or create transcript")
                return
            }
            
            // Create Word entities
            for transcribedWord in wordsToSave {
                let word = Word(context: self.viewContext)
                word.id = transcribedWord.id
                word.text = transcribedWord.text
                word.startMs = transcribedWord.startMs
                word.endMs = transcribedWord.endMs
                word.channel = transcribedWord.channel
                word.confidence = transcribedWord.confidence
                word.createdAt = Date()
                word.transcript = transcript
            }
            
            // Save context
            do {
                try self.viewContext.save()
                print("💾 Saved \(wordsToSave.count) words to Core Data")
            } catch {
                print("❌ Failed to save words: \(error)")
            }
        }
    }
}
