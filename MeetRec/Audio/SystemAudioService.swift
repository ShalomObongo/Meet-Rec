//
//  SystemAudioService.swift
//  MeetRec
//
//  Created by Kiro on 11/17/25.
//

import Foundation
import ScreenCaptureKit
import AVFoundation
import Combine

@available(macOS 13.0, *)
final class SystemAudioService: NSObject {
    @MainActor var isCapturing: Bool = false
    @MainActor var speakerLevel: Float = 0.0
    
    private var stream: SCStream?
    private var availableContent: SCShareableContent?
    
    // Callback for audio buffer forwarding
    @MainActor var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?
    
    // Background queue for audio processing
    private let audioQueue = DispatchQueue(label: "com.meetrec.systemaudio", qos: .userInitiated)
    
    override init() {
        super.init()
    }
    
    deinit {
        Task {
            await stopCaptureAsync()
        }
    }
    
    func startCapture() async throws {
        print("🔊 Starting system audio capture")
        
        // Get available content
        do {
            availableContent = try await SCShareableContent.current
            print("✅ Got shareable content")
        } catch {
            print("❌ Failed to get shareable content: \(error)")
            throw SystemAudioError.contentAccessFailed
        }
        
        guard let display = availableContent?.displays.first else {
            print("❌ No displays available")
            throw SystemAudioError.noDisplaysAvailable
        }
        
        print("📺 Using display: \(display.displayID)")
        
        // Create content filter for the display
        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        
        // Configure stream
        let config = SCStreamConfiguration()
        
        // Audio configuration (available in macOS 13.0+)
        if #available(macOS 13.0, *) {
            config.capturesAudio = true
            config.sampleRate = 48000
            config.channelCount = 2
            config.excludesCurrentProcessAudio = true
            print("✅ Audio capture configured (macOS 13.0+)")
        } else {
            // For macOS 12.3-12.x, we need to capture video to get audio
            // This is a limitation of earlier ScreenCaptureKit versions
            print("⚠️ macOS 12.x detected - audio-only capture not supported")
            throw SystemAudioError.notAvailable
        }
        
        // Minimal video configuration (required even for audio-only)
        // Set to minimal size and low frame rate since we only want audio
        config.width = 1
        config.height = 1
        config.minimumFrameInterval = CMTime(value: 1, timescale: 1) // 1 fps
        config.pixelFormat = kCVPixelFormatType_32BGRA
        
        print("📐 Stream config: \(config.width)x\(config.height), audio: \(config.capturesAudio)")
        
        // Create stream
        let newStream = SCStream(filter: filter, configuration: config, delegate: nil)
        stream = newStream
        
        guard stream != nil else {
            print("❌ Failed to create stream")
            throw SystemAudioError.streamSetupFailed
        }
        
        print("✅ Stream created successfully")
        
        // Add screen output handler (to prevent "stream output NOT found" errors)
        // We discard video frames since we only want audio
        do {
            try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: audioQueue)
            print("✅ Added screen output handler (discarding frames)")
        } catch {
            print("❌ Failed to add screen output: \(error)")
            throw SystemAudioError.streamSetupFailed
        }
        
        // Add audio output handler
        do {
            try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: audioQueue)
            print("✅ Added audio output handler")
        } catch {
            print("❌ Failed to add audio output: \(error)")
            throw SystemAudioError.streamSetupFailed
        }
        
        // Start capture
        do {
            try await stream?.startCapture()
            print("✅ System audio capture started")
            await MainActor.run {
                isCapturing = true
            }
        } catch {
            print("❌ Failed to start capture: \(error)")
            throw SystemAudioError.captureStartFailed
        }
    }
    
    @MainActor
    func stopCapture() {
        Task {
            await stopCaptureAsync()
        }
    }
    
    private func stopCaptureAsync() async {
        print("🔊 Stopping system audio capture")
        
        do {
            try await stream?.stopCapture()
            print("✅ System audio capture stopped")
        } catch {
            print("⚠️ Error stopping capture: \(error)")
        }
        
        await MainActor.run {
            isCapturing = false
            speakerLevel = 0.0
        }
    }
}

// MARK: - SCStreamOutput

@available(macOS 13.0, *)
extension SystemAudioService: SCStreamOutput {
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        // Handle audio output
        if type == .audio {
            // Convert CMSampleBuffer to AVAudioPCMBuffer
            guard let audioBuffer = convertToAudioBuffer(sampleBuffer) else {
                print("⚠️ Failed to convert sample buffer to audio buffer")
                return
            }
            
            // Calculate RMS amplitude for speaker level visualization
            let level = calculateRMSLevel(audioBuffer)
            
            // Update on main thread
            Task { @MainActor in
                self.speakerLevel = level
                
                // Forward audio buffer
                self.onAudioBuffer?(audioBuffer)
            }
        } else if type == .screen {
            // Discard video frames - we only want audio
            // This prevents "stream output NOT found" errors
            return
        }
    }
    
    nonisolated private func convertToAudioBuffer(_ sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return nil
        }
        
        guard let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) else {
            return nil
        }
        
        let format = AVAudioFormat(streamDescription: audioStreamBasicDescription)
        
        guard let format = format else {
            return nil
        }
        
        let frameLength = CMSampleBufferGetNumSamples(sampleBuffer)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameLength)) else {
            return nil
        }
        
        buffer.frameLength = AVAudioFrameCount(frameLength)
        
        // Copy audio data
        let audioBufferList = buffer.mutableAudioBufferList
        
        CMSampleBufferCopyPCMDataIntoAudioBufferList(
            sampleBuffer,
            at: 0,
            frameCount: Int32(frameLength),
            into: audioBufferList
        )
        
        return buffer
    }
    
    nonisolated private func calculateRMSLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else {
            return 0.0
        }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
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
        let normalizedLevel = min(rms * 2.0, 1.0)
        
        return normalizedLevel
    }
}

// MARK: - Error Types

enum SystemAudioError: LocalizedError {
    case contentAccessFailed
    case noDisplaysAvailable
    case streamSetupFailed
    case captureStartFailed
    case notAvailable
    
    var errorDescription: String? {
        switch self {
        case .contentAccessFailed:
            return "Failed to access screen content. Please grant screen recording permission in System Settings."
        case .noDisplaysAvailable:
            return "No displays available for audio capture."
        case .streamSetupFailed:
            return "Failed to set up audio capture stream."
        case .captureStartFailed:
            return "Failed to start system audio capture."
        case .notAvailable:
            return "System audio capture requires macOS 13.0 or later."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .contentAccessFailed:
            return "Open System Settings > Privacy & Security > Screen Recording and enable access for MeetRec."
        default:
            return nil
        }
    }
}
