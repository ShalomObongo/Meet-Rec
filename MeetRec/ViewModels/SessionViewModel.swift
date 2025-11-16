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
    var errorMessage: String?
    var showError: Bool = false
    
    private let viewContext: NSManagedObjectContext
    
    init(session: Session, viewContext: NSManagedObjectContext) {
        self.session = session
        self.viewContext = viewContext
        self.audioService = AudioService()
    }
    
    func startRecording() async {
        do {
            try await audioService.startRecording(source: audioService.audioSource)
            
            // Update session timestamps
            session.startedAt = Date()
            saveSession()
        } catch {
            handleError(error)
        }
    }
    
    func stopRecording() {
        audioService.stopRecording()
        
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
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }
}
