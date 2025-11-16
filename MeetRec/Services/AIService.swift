//
//  AIService.swift
//  MeetRec
//
//  Created by Kiro on 11/17/25.
//

import Foundation

enum AutonomyLevel: String, CaseIterable {
    case grounded = "Grounded"
    case creative = "Creative"
    
    var description: String {
        switch self {
        case .grounded:
            return "Uses only your memos"
        case .creative:
            return "Uses memos and full transcript"
        }
    }
}

enum AIServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case networkError(Error)
    case streamingError(String)
    case emptyContent
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is not configured. Please add your API key in Settings."
        case .invalidResponse:
            return "Received an invalid response from the AI service."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .streamingError(let message):
            return "Streaming error: \(message)"
        case .emptyContent:
            return "Cannot generate summary: No content available. Please add some notes first."
        }
    }
}

@MainActor
@Observable
final class AIService {
    var isGenerating: Bool = false
    
    private let apiKeyKey = "openai_api_key"
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini" // Options: gpt-4o-mini, gpt-4o, gpt-4-turbo, gpt-3.5-turbo
    
    /// Generate a summary from memos and optionally transcript
    func generateSummary(
        memos: String,
        transcript: String?,
        autonomy: AutonomyLevel
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                do {
                    isGenerating = true
                    
                    // Validate content
                    guard !memos.isEmpty else {
                        throw AIServiceError.emptyContent
                    }
                    
                    // Get API key
                    guard let apiKey = try? KeychainService.shared.retrieve(key: apiKeyKey),
                          !apiKey.isEmpty else {
                        throw AIServiceError.missingAPIKey
                    }
                    
                    // Build prompt based on autonomy level
                    let prompt = buildPrompt(memos: memos, transcript: transcript, autonomy: autonomy)
                    
                    // Create request
                    var request = try createRequest(apiKey: apiKey, prompt: prompt)
                    
                    // Attempt with retry logic
                    var attempt = 0
                    let maxAttempts = 3
                    
                    while attempt < maxAttempts {
                        do {
                            try await streamCompletion(request: request, continuation: continuation)
                            break // Success, exit retry loop
                        } catch {
                            attempt += 1
                            if attempt >= maxAttempts {
                                throw error
                            }
                            
                            // Exponential backoff
                            let delay = pow(2.0, Double(attempt))
                            try await Task.sleep(for: .seconds(delay))
                        }
                    }
                    
                    continuation.finish()
                    isGenerating = false
                } catch {
                    continuation.finish(throwing: error)
                    isGenerating = false
                }
            }
        }
    }
    
    /// Save API key to keychain
    func saveAPIKey(_ key: String) throws {
        try KeychainService.shared.save(key: apiKeyKey, value: key)
    }
    
    /// Retrieve API key from keychain
    func getAPIKey() -> String? {
        try? KeychainService.shared.retrieve(key: apiKeyKey)
    }
    
    /// Check if API key exists
    func hasAPIKey() -> Bool {
        KeychainService.shared.exists(key: apiKeyKey)
    }
    
    // MARK: - Private Methods
    
    private func buildPrompt(memos: String, transcript: String?, autonomy: AutonomyLevel) -> String {
        let prompt: String
        
        switch autonomy {
        case .grounded:
            prompt = """
            Summarize these memos into a clear, well-structured summary. Maintain the key points and action items.
            
            Memos:
            \(memos)
            """
            print("🤖 Using GROUNDED mode (memos only)")
            
        case .creative:
            let transcriptText = transcript ?? ""
            prompt = """
            Summarize this meeting based on the memos and transcript. Create a comprehensive summary that captures key points, decisions, and action items.
            
            Memos:
            \(memos)
            
            Transcript:
            \(transcriptText)
            """
            
            if transcriptText.isEmpty {
                print("🤖 Using CREATIVE mode but transcript is EMPTY - will only use memos")
            } else {
                print("🤖 Using CREATIVE mode with transcript (\(transcriptText.count) chars)")
            }
        }
        
        return prompt
    }
    
    private func createRequest(apiKey: String, prompt: String) throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw AIServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "stream": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        return request
    }
    
    private func streamCompletion(
        request: URLRequest,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIServiceError.networkError(
                NSError(domain: "AIService", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"
                ])
            )
        }
        
        // Parse Server-Sent Events
        for try await line in bytes.lines {
            // Skip empty lines
            guard !line.isEmpty else { continue }
            
            // Check for data: prefix
            guard line.hasPrefix("data: ") else { continue }
            
            let data = line.dropFirst(6) // Remove "data: " prefix
            
            // Check for [DONE] marker
            if data == "[DONE]" {
                break
            }
            
            // Parse JSON
            guard let jsonData = data.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let delta = firstChoice["delta"] as? [String: Any],
                  let content = delta["content"] as? String else {
                continue
            }
            
            // Yield content delta
            continuation.yield(content)
        }
    }
}
