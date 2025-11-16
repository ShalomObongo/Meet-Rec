//
//  AudioService.swift
//  MeetRec
//
//  Created by Kiro on 11/16/25.
//

import Foundation
import AVFoundation
import Combine

@MainActor
@Observable
final class AudioService {
    var isRecording: Bool = false
    var micLevel: Float = 0.0
    var audioSource: AudioSource = .micOnly

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var levelTimer: Timer?
    private var configChangeObserver: NSObjectProtocol?
    
    // Callback for audio buffer forwarding
    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?

    // Background queue for audio processing
    private let audioQueue = DispatchQueue(label: "com.meetrec.audio", qos: .userInitiated)

    init() {
        setupConfigurationChangeObserver()
    }

    deinit {
        // Note: Observer is automatically removed when deallocated
        // No need to manually remove since we're using a stored observer reference
    }
    
    func startRecording(source: AudioSource) async throws {
        print("🎤 Starting recording with source: \(source)")

        // Update audio source
        self.audioSource = source

        // Set up audio engine
        do {
            try await setupAudioEngine()
        } catch {
            print("❌ Failed to setup audio engine: \(error)")
            throw error
        }

        // Start the engine
        do {
            try audioEngine?.start()
            print("✅ Audio engine started successfully")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
            throw AudioServiceError.engineStartFailed
        }

        isRecording = true
        print("🎤 Recording started")
    }
    
    func stopRecording() {
        print("🎤 Stopping recording")
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        levelTimer?.invalidate()
        levelTimer = nil
        
        isRecording = false
        micLevel = 0.0
        
        print("🎤 Recording stopped")
    }
    
    func setAudioSource(_ source: AudioSource) async throws {
        let wasRecording = isRecording
        
        if wasRecording {
            stopRecording()
        }
        
        audioSource = source
        
        if wasRecording {
            try await startRecording(source: source)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioEngine() async throws {
        // Clean up existing engine first
        if let existingEngine = audioEngine {
            existingEngine.stop()
            if existingEngine.inputNode.numberOfInputs > 0 {
                existingEngine.inputNode.removeTap(onBus: 0)
            }
        }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode

        // Get the native input format from the hardware
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Validate format
        guard inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 else {
            print("❌ Invalid input format: \(inputFormat.sampleRate)Hz, \(inputFormat.channelCount) channels")
            throw AudioServiceError.invalidAudioFormat
        }

        print("🎤 Input format: \(inputFormat.sampleRate)Hz, \(inputFormat.channelCount) channels")

        // Install tap on input node with buffer size 4096
        // Use the native format to avoid conversion issues
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, time in
            guard let self = self else { return }

            // Process audio buffer directly (already on audio thread)
            self.processAudioBufferSync(buffer)
        }

        // Prepare the engine
        engine.prepare()

        self.audioEngine = engine
        self.inputNode = inputNode

        print("🎤 Audio engine setup complete")
    }

    private func setupConfigurationChangeObserver() {
        configChangeObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            print("⚠️ Audio configuration changed - restarting engine")

            Task { @MainActor in
                if self.isRecording {
                    // Restart recording with new configuration
                    do {
                        try await self.setupAudioEngine()
                        try self.audioEngine?.start()
                        print("✅ Audio engine restarted after configuration change")
                    } catch {
                        print("❌ Failed to restart audio engine: \(error)")
                        self.isRecording = false
                    }
                }
            }
        }
    }
    
    private func processAudioBufferSync(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else {
            print("⚠️ No channel data in buffer")
            return
        }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
        // Calculate RMS amplitude for mic level visualization
        var sum: Float = 0.0
        
        for channel in 0..<channelCount {
            let samples = channelData[channel]
            for frame in 0..<frameLength {
                let sample = samples[frame]
                sum += sample * sample
            }
        }
        
        let rms = sqrt(sum / Float(frameLength * channelCount))
        
        // Normalize to 0.0-1.0 range
        // Typical RMS values range from 0.0 to ~0.5 for normal speech
        let normalizedLevel = min(rms * 2.0, 1.0)
        
        // Debug: Print level occasionally
        if Int.random(in: 0..<100) == 0 {
            print("🎤 Audio level: \(normalizedLevel) (RMS: \(rms))")
        }
        
        // Update on main thread
        Task { @MainActor in
            self.micLevel = normalizedLevel
            
            // Forward audio buffer to transcription service
            self.onAudioBuffer?(buffer)
        }
    }
}

// MARK: - Error Types

enum AudioServiceError: LocalizedError {
    case microphonePermissionDenied
    case invalidAudioFormat
    case engineStartFailed
    
    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is required to record audio. Please grant permission in System Settings."
        case .invalidAudioFormat:
            return "Failed to configure audio format."
        case .engineStartFailed:
            return "Failed to start audio engine."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Open System Settings > Privacy & Security > Microphone and enable access for MeetRec."
        default:
            return nil
        }
    }
}
