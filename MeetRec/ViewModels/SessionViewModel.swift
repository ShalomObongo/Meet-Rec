//
//  SessionViewModel.swift
//  MeetRec
//
//  Created by Kiro on 11/16/25.
//

import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
@Observable
final class SessionViewModel {
    var session: Session
    var audioService: AudioService
    var transcriptionService: TranscriptionService
    var aiService: AIService
    var errorMessage: String?
    var showError: Bool = false
    var memosContent: String {
        didSet {
            // Update session and trigger auto-save
            session.rawMarkdown = memosContent
            scheduleAutoSave()
        }
    }
    var selectedEditor: EditorTab = .memos
    var autonomyLevel: AutonomyLevel = .grounded
    var isGeneratingSummary: Bool = false
    var streamingSummary: String = ""
    var summaryError: String?
    
    private let viewContext: NSManagedObjectContext
    private var audioBufferCancellable: AnyCancellable?
    private var autoSaveTask: Task<Void, Never>?
    private var summaryTask: Task<Void, Never>?
    
    init(session: Session, viewContext: NSManagedObjectContext) {
        self.session = session
        self.viewContext = viewContext
        self.audioService = AudioService()
        self.transcriptionService = TranscriptionService()
        self.aiService = AIService()
        self.memosContent = session.rawMarkdown ?? ""
    }
    
    func startRecording() async {
        do {
            // Capture the recording start time
            let recordingStartTime = Date()

            // Start audio recording
            try await audioService.startRecording(source: audioService.audioSource)

            // Start transcription with recording start time
            try await transcriptionService.startTranscription(
                sessionId: session.id!,
                recordingStartTime: recordingStartTime,
                viewContext: viewContext
            )

            // Connect audio buffers to transcription service
            setupAudioBufferForwarding()

            // Update session timestamps
            session.startedAt = recordingStartTime
            saveSession()
        } catch {
            handleError(error)
        }
    }
    
    func stopRecording() {
        // Stop transcription first
        transcriptionService.stopTranscription()
        
        // Stop audio recording
        audioService.stopRecording()
        
        // Cancel audio buffer forwarding
        audioBufferCancellable?.cancel()
        audioBufferCancellable = nil
        
        // Update session timestamps
        session.endedAt = Date()
        saveSession()
    }
    
    func toggleRecording() async {
        if audioService.isRecording {
            stopRecording()
        } else {
            await startRecording()
        }
    }
    
    private func setupAudioBufferForwarding() {
        // Forward audio buffers from AudioService to TranscriptionService
        audioService.onAudioBuffer = { [weak self] buffer in
            guard let self = self else { return }
            self.transcriptionService.appendAudioBuffer(buffer)
        }
    }
    
    private func saveSession() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving session: \(error)")
        }
    }
    
    func handleError(_ error: Error) {
        if let audioError = error as? AudioServiceError {
            errorMessage = audioError.errorDescription
        } else if let transcriptionError = error as? TranscriptionError {
            errorMessage = transcriptionError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }
    
    private func scheduleAutoSave() {
        // Cancel any existing auto-save task
        autoSaveTask?.cancel()
        
        // Schedule a new auto-save after 2 seconds
        autoSaveTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            // Save to Core Data
            saveSession()
        }
    }
    
    func generateSummary() async {
        // Cancel any existing summary generation
        summaryTask?.cancel()
        
        // Reset state
        streamingSummary = ""
        summaryError = nil
        isGeneratingSummary = true
        
        summaryTask = Task { @MainActor in
            do {
                // Get transcript text if needed
                let transcriptText: String? = {
                    guard autonomyLevel == .creative else {
                        print("📝 Grounded mode: Using memos only")
                        return nil
                    }
                    
                    // Fetch all words for this session's transcripts
                    let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
                    fetchRequest.predicate = NSPredicate(
                        format: "transcript.session.id == %@",
                        session.id! as CVarArg
                    )
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startMs", ascending: true)]
                    
                    guard let words = try? viewContext.fetch(fetchRequest) else {
                        print("⚠️ Failed to fetch words from Core Data")
                        return nil
                    }
                    
                    let transcriptText = words.compactMap { $0.text }.joined(separator: " ")
                    print("📝 Creative mode: Found \(words.count) words, transcript length: \(transcriptText.count) characters")
                    
                    if transcriptText.isEmpty {
                        print("⚠️ Transcript is empty - no words recorded yet")
                    }
                    
                    return transcriptText.isEmpty ? nil : transcriptText
                }()
                
                // Generate summary stream
                let stream = aiService.generateSummary(
                    memos: memosContent,
                    transcript: transcriptText,
                    autonomy: autonomyLevel
                )
                
                // Collect streamed content
                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    streamingSummary += chunk
                }
                
                // Save final summary to session
                if !Task.isCancelled && !streamingSummary.isEmpty {
                    session.enhancedMarkdown = streamingSummary
                    saveSession()
                }
                
                isGeneratingSummary = false
            } catch {
                isGeneratingSummary = false
                
                if let aiError = error as? AIServiceError {
                    summaryError = aiError.errorDescription
                } else {
                    summaryError = error.localizedDescription
                }
            }
        }
    }
}
