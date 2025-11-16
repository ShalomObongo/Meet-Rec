//
//  AudioSourcePicker.swift
//  MeetRec
//
//  Created by Kiro on 11/17/25.
//

import SwiftUI

struct AudioSourcePicker: View {
    @Binding var selectedSource: AudioSource
    var isRecording: Bool
    var onSourceChange: (AudioSource) async -> Void
    
    var body: some View {
        Menu {
            ForEach(AudioSource.allCases, id: \.self) { source in
                Button(action: {
                    Task {
                        await onSourceChange(source)
                    }
                }) {
                    HStack {
                        Image(systemName: iconForSource(source))
                        Text(source.displayName)
                        
                        if selectedSource == source {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: iconForSource(selectedSource))
                    .font(.caption)
                Text(selectedSource.displayName)
                    .font(.caption)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)
        }
        .help("Select audio source")
        .disabled(isRecording)
    }
    
    private func iconForSource(_ source: AudioSource) -> String {
        switch source {
        case .micOnly:
            return "mic.fill"
        case .systemOnly:
            return "speaker.wave.2.fill"
        case .micAndSystem:
            return "mic.and.signal.meter.fill"
        }
    }
}

#Preview {
    @Previewable @State var source: AudioSource = .micOnly
    
    AudioSourcePicker(
        selectedSource: $source,
        isRecording: false,
        onSourceChange: { newSource in
            source = newSource
        }
    )
    .padding()
}
