//
//  DebugAPIKeyView.swift
//  MeetRec
//
//  Temporary view for setting API key during development
//  DELETE BEFORE PRODUCTION
//

import SwiftUI

struct DebugAPIKeyView: View {
    @State private var apiKey: String = ""
    @State private var message: String = ""
    @State private var showMessage: Bool = false
    
    private let aiService = AIService()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Debug: Set OpenAI API Key")
                .font(.headline)
            
            SecureField("Enter OpenAI API Key", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .frame(width: 400)
            
            HStack(spacing: 12) {
                Button("Save API Key") {
                    saveAPIKey()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Check Status") {
                    checkAPIKey()
                }
                
                Button("Clear API Key") {
                    clearAPIKey()
                }
                .foregroundStyle(.red)
            }
            
            if showMessage {
                Text(message)
                    .foregroundStyle(message.contains("✅") ? .green : .orange)
                    .padding()
            }
        }
        .padding()
        .onAppear {
            checkAPIKey()
        }
    }
    
    private func saveAPIKey() {
        guard !apiKey.isEmpty else {
            message = "⚠️ Please enter an API key"
            showMessage = true
            return
        }
        
        do {
            try aiService.saveAPIKey(apiKey)
            message = "✅ API key saved successfully"
            showMessage = true
            apiKey = "" // Clear the field
        } catch {
            message = "❌ Failed to save: \(error.localizedDescription)"
            showMessage = true
        }
    }
    
    private func checkAPIKey() {
        if aiService.hasAPIKey() {
            if let key = aiService.getAPIKey() {
                let masked = String(key.prefix(7)) + "..." + String(key.suffix(4))
                message = "✅ API key configured: \(masked)"
            } else {
                message = "✅ API key exists"
            }
        } else {
            message = "⚠️ No API key configured"
        }
        showMessage = true
    }
    
    private func clearAPIKey() {
        do {
            try KeychainService.shared.delete(key: "openai_api_key")
            message = "✅ API key cleared"
            showMessage = true
        } catch {
            message = "❌ Failed to clear: \(error.localizedDescription)"
            showMessage = true
        }
    }
}

#Preview {
    DebugAPIKeyView()
}
