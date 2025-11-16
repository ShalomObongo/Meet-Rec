//
//  TranscriptView.swift
//  MeetRec
//
//  Created by Kiro on 11/16/25.
//

import SwiftUI

struct TranscriptView: View {
    let words: [TranscribedWord]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if words.isEmpty {
                        Text("No transcription yet. Start recording to see live transcription.")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(words) { word in
                            HStack(alignment: .top, spacing: 8) {
                                // Timestamp
                                Text(formatTimestamp(word.startMs))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 60, alignment: .trailing)
                                    .monospacedDigit()
                                
                                // Word text
                                Text(word.text)
                                    .font(.body)
                                
                                Spacer()

                                // Confidence indicator (only show for final results with low confidence)
                                // Partial results always have confidence = 0, so we skip those
                                if word.isFinal && word.confidence < 0.5 {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                        .help("Low confidence: \(String(format: "%.0f%%", word.confidence * 100))")
                                }

                                // Show confidence as percentage for debugging (optional - can remove)
                                if word.isFinal {
                                    Text("\(String(format: "%.0f%%", word.confidence * 100))")
                                        .font(.caption2)
                                        .foregroundStyle(word.confidence < 0.5 ? .orange : .secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 2)
                            .id(word.id)
                        }
                    }
                }
                .padding(.vertical)
            }
            .onChange(of: words.count) { oldValue, newValue in
                // Auto-scroll to latest word
                if let lastWord = words.last {
                    withAnimation {
                        proxy.scrollTo(lastWord.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private func formatTimestamp(_ milliseconds: Int64) -> String {
        let totalSeconds = Double(milliseconds) / 1000.0
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        let ms = Int((totalSeconds.truncatingRemainder(dividingBy: 1.0)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, ms)
    }
}

#Preview {
    TranscriptView(words: [
        TranscribedWord(text: "Hello", startMs: 0, endMs: 500, confidence: 0.95, isFinal: true),
        TranscribedWord(text: "world", startMs: 500, endMs: 1000, confidence: 0.98, isFinal: true),
        TranscribedWord(text: "this", startMs: 1000, endMs: 1300, confidence: 0.92, isFinal: true),
        TranscribedWord(text: "is", startMs: 1300, endMs: 1500, confidence: 0.99, isFinal: true),
        TranscribedWord(text: "a", startMs: 1500, endMs: 1600, confidence: 0.0, isFinal: false),  // Partial result
        TranscribedWord(text: "test", startMs: 1600, endMs: 2000, confidence: 0.35, isFinal: true), // Low confidence final
    ])
}
