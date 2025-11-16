# System Audio Capture Implementation

## Overview
Implemented system audio capture using ScreenCaptureKit framework for macOS 12.3+, allowing MeetRec to capture audio from applications like Zoom, Teams, and other meeting software.

## Implementation Details

### Files Created/Modified

1. **MeetRec/Audio/SystemAudioService.swift** (NEW)
   - Created `SystemAudioService` class that inherits from `NSObject` and conforms to `SCStreamOutput`
   - Implements system audio capture using ScreenCaptureKit
   - Provides real-time speaker level visualization
   - Converts `CMSampleBuffer` to `AVAudioPCMBuffer` for compatibility with existing audio pipeline
   - Handles proper actor isolation for thread-safe operation

2. **MeetRec/Audio/AudioService.swift** (MODIFIED)
   - Added `speakerLevel` property for speaker audio visualization
   - Integrated `SystemAudioService` for system audio capture
   - Updated `startRecording()` to support all three audio sources:
     - `micOnly`: Only microphone audio
     - `systemOnly`: Only system audio
     - `micAndSystem`: Both microphone and system audio
   - Added `setAudioSource()` method to switch sources during recording (within 2 seconds)
   - Added UserDefaults persistence for audio source preference
   - Added `systemAudioNotAvailable` error case

3. **MeetRec/Views/AudioSourcePicker.swift** (NEW)
   - Created SwiftUI Menu component for selecting audio source
   - Shows appropriate icons for each source type
   - Displays checkmark for currently selected source
   - Disabled during recording to prevent mid-recording changes via UI (programmatic changes still work)

4. **MeetRec/SessionView.swift** (MODIFIED)
   - Added `AudioSourcePicker` to session header
   - Display both mic and speaker level indicators when appropriate:
     - Mic level shown for `micOnly` and `micAndSystem`
     - Speaker level shown for `systemOnly` and `micAndSystem`
   - Different colors for indicators (red for mic, blue for speaker)

5. **MeetRec/Info.plist** (MODIFIED)
   - Added `NSScreenCaptureUsageDescription` key with clear explanation

### Key Features

- **Three Audio Source Modes**:
  - Mic Only: Traditional microphone recording
  - System Only: Capture only system audio (e.g., from Zoom, Teams)
  - Mic + System: Capture both simultaneously

- **Real-time Level Visualization**:
  - Separate level indicators for microphone and speaker
  - RMS amplitude calculation normalized to 0.0-1.0 range
  - Visual feedback during recording

- **Dynamic Source Switching**:
  - Can switch audio sources during recording
  - Restarts recording with new source within 2 seconds
  - Preserves session state

- **Persistent Preferences**:
  - Selected audio source saved to UserDefaults
  - Restored on app launch

- **Proper Error Handling**:
  - Checks for macOS 12.3+ availability
  - Requests screen recording permission when needed
  - Clear error messages with recovery suggestions

### Technical Considerations

1. **Actor Isolation**:
   - `SystemAudioService` uses proper actor isolation
   - Main actor properties for UI-bound state
   - Nonisolated methods for audio processing

2. **Thread Safety**:
   - Audio processing on background queue (QoS .userInitiated)
   - UI updates on main thread via `Task { @MainActor in ... }`

3. **Memory Management**:
   - Proper cleanup in `deinit`
   - Stops capture asynchronously to avoid blocking

4. **Audio Format Handling**:
   - Converts ScreenCaptureKit's `CMSampleBuffer` to `AVAudioPCMBuffer`
   - Maintains compatibility with existing transcription pipeline

## Testing

### Manual Testing Steps

1. **System Only Mode**:
   - Select "System Only" from audio source picker
   - Play music or video
   - Verify speaker level indicator moves
   - Verify no mic level indicator shown

2. **Mic + System Mode**:
   - Select "Mic + System"
   - Play music and speak into microphone
   - Verify both level indicators move independently
   - Verify both audio sources are captured

3. **Dynamic Switching**:
   - Start recording with "Mic Only"
   - Switch to "Mic + System" during recording
   - Verify smooth transition (< 2 seconds)
   - Verify no crashes or data loss

4. **Permission Handling**:
   - First launch: verify screen recording permission prompt
   - Deny permission: verify error message with Settings link
   - Grant permission: verify system audio works

5. **Persistence**:
   - Select "System Only"
   - Quit and relaunch app
   - Verify "System Only" is still selected

## Known Limitations

1. **macOS Version Requirement**:
   - System audio capture requires macOS 13.0+ (Ventura or later)
   - The `capturesAudio` property in `SCStreamConfiguration` is only available in macOS 13.0+
   - Falls back gracefully on older versions with clear error message
   - macOS 12.3-12.x does not support audio-only capture via ScreenCaptureKit

2. **Screen Recording Permission**:
   - Requires screen recording permission (TCC)
   - User must grant in System Settings > Privacy & Security > Screen Recording

3. **Audio Quality**:
   - System audio quality depends on ScreenCaptureKit configuration
   - Currently set to 48kHz, 2 channels

## Future Enhancements

1. **Audio Mixing**:
   - Better mixing of mic and system audio
   - Volume controls for each source

2. **Echo Cancellation**:
   - Implement AEC when both sources active
   - Prevent feedback loops

3. **Source Monitoring**:
   - Visual waveform display
   - Peak level indicators

4. **Advanced Configuration**:
   - Sample rate selection
   - Channel configuration
   - Buffer size tuning
