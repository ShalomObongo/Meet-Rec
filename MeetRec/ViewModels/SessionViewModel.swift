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
    var errorMessage: String?
    var showError: Bool = false
    
    private let viewContext: NSManagedObjectContext
    private var audioBufferCancellable: AnyCancellable?
    
    init(session: Session, viewContext: NSManagedObjectContext) {
        self.session = session
        self.viewContext = viewContext
        self.audioService = AudioService()
        self.transcriptionService = TranscriptionService()
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
    
    private func handleError(_ error: Error) {
        if let audioError = error as? AudioServiceError {
            errorMessage = audioError.errorDescription
        } else if let transcriptionError = error as? TranscriptionError {
            errorMessage = transcriptionError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }
}
