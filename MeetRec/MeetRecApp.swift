//
//  MeetRecApp.swift
//  MeetRec
//
//  Created by Shalom .O on 11/15/25.
//

import SwiftUI
import CoreData

@main
struct MeetRecApp: App {
    let persistenceController = PersistenceController.shared
    @State private var appState = AppState()

    init() {
        // TEMPORARY: Set API key for testing
        // Remove this before production!
        #if DEBUG
        setupAPIKeyForTesting()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(appState)
        }
        .commands {
            #if DEBUG
            CommandGroup(after: .appSettings) {
                Button("Debug: Set API Key...") {
                    openDebugAPIKeyWindow()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
            }
            #endif
        }
    }
    
    #if DEBUG
    private func openDebugAPIKeyWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Debug: API Key Configuration"
        window.contentView = NSHostingView(rootView: DebugAPIKeyView())
        window.makeKeyAndOrderFront(nil)
    }
    #endif
    
    // MARK: - Debug Helper
    #if DEBUG
    private func setupAPIKeyForTesting() {
        let aiService = AIService()
        
        // Check if API key already exists
        if !aiService.hasAPIKey() {
            // TODO: Replace with your actual OpenAI API key
            let apiKey = "sk-YOUR-API-KEY-HERE"
            
            if apiKey != "sk-YOUR-API-KEY-HERE" {
                try? aiService.saveAPIKey(apiKey)
                print("✅ API key saved to Keychain")
            } else {
                print("⚠️ Please set your OpenAI API key in MeetRecApp.swift")
            }
        } else {
            print("✅ API key already configured")
        }
    }
    #endif
}
