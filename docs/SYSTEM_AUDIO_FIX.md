# System Audio Capture Fix

## Issue
The system audio capture was failing with the error:
```
[ERROR] -[SCStream startCaptureWithCompletionHandler:]_block_invoke_2:840 error=Error Domain=CoreGraphicsErrorDomain Code=1003 "Start stream failed" UserInfo={NSLocalizedDescription=Start stream failed, NSLocalizedFailureReason=The stream is nil.}
```

## Root Cause
The `capturesAudio` property in `SCStreamConfiguration` is only available in **macOS 13.0+** (Ventura), not macOS 12.3+ as initially assumed. The ScreenCaptureKit framework was introduced in macOS 12.3, but audio-only capture support was added later in macOS 13.0.

## Solution

### 1. Updated macOS Version Requirements
Changed all availability checks from `@available(macOS 12.3, *)` to `@available(macOS 13.0, *)`:

- `SystemAudioService` class
- `SystemAudioService` extension for `SCStreamOutput`
- All references in `AudioService`

### 2. Added Version Check in startCapture()
Added explicit version check before setting audio configuration:

```swift
if #available(macOS 13.0, *) {
    config.capturesAudio = true
    config.sampleRate = 48000
    config.channelCount = 2
    config.excludesCurrentProcessAudio = true
    print("✅ Audio capture configured (macOS 13.0+)")
} else {
    print("⚠️ macOS 12.x detected - audio-only capture not supported")
    throw SystemAudioError.notAvailable
}
```

### 3. Improved Stream Configuration
- Increased minimal video dimensions from 1x1 to 100x100 (more stable)
- Added explicit pixel format: `kCVPixelFormatType_32BGRA`
- Added null check after stream creation
- Added more detailed logging for debugging

### 4. Updated Error Messages
Changed all error messages to reflect the correct requirement:
- "System audio capture requires macOS 13.0 or later"
- Updated recovery suggestions accordingly

### 5. Updated Documentation
- Info.plist description now mentions macOS 13.0 requirement
- Implementation documentation updated with correct version info
- Added note about macOS 12.3-12.x limitations

## Testing on macOS 13.0+

To test the system audio capture:

1. **Check macOS Version**:
   ```bash
   sw_vers
   ```
   Ensure you're running macOS 13.0 (Ventura) or later.

2. **Grant Screen Recording Permission**:
   - System Settings > Privacy & Security > Screen Recording
   - Enable MeetRec

3. **Test System Audio**:
   - Select "System Only" from audio source picker
   - Play music or video
   - Verify speaker level indicator moves
   - Check console for success messages

4. **Test Mic + System**:
   - Select "Mic + System"
   - Play audio and speak into microphone
   - Verify both level indicators work independently

## Expected Behavior

### On macOS 13.0+
- System audio capture works correctly
- Both "System Only" and "Mic + System" modes function
- Speaker level visualization displays properly
- Audio is captured and forwarded to transcription

### On macOS 12.x
- System audio options are available in UI but will fail gracefully
- Clear error message: "System audio capture requires macOS 13.0 or later"
- User can still use "Mic Only" mode
- No crashes or undefined behavior

## Technical Details

### Why macOS 13.0 is Required

The `SCStreamConfiguration.capturesAudio` property was introduced in macOS 13.0:

```swift
@available(macOS 13.0, *)
var capturesAudio: Bool { get set }
```

In macOS 12.3-12.x, ScreenCaptureKit could only capture video, and audio capture was not supported even when capturing a display. The framework was enhanced in macOS 13.0 to support:
- Audio-only capture
- Microphone audio capture
- System audio exclusion (`excludesCurrentProcessAudio`)

### Alternative Approaches Considered

1. **Use AVCaptureScreenInput (Deprecated)**:
   - Deprecated in macOS 10.15
   - Not recommended for new development

2. **Capture Video + Audio in macOS 12.x**:
   - Would require processing video frames unnecessarily
   - Significant performance overhead
   - Not worth the complexity for older OS support

3. **Use Core Audio for System Audio**:
   - Requires private APIs or kernel extensions
   - Not suitable for App Store distribution
   - Security and sandboxing issues

## Conclusion

The fix correctly identifies that system audio capture via ScreenCaptureKit requires macOS 13.0+. The implementation now:
- Checks version availability properly
- Provides clear error messages
- Falls back gracefully on unsupported systems
- Works correctly on macOS 13.0+ (Ventura and later)

Users on macOS 12.x can still use MeetRec with microphone-only recording.


## Additional Fix: Video Frame Dropping Error

### Issue
After the initial fix, the console showed continuous errors:
```
[ERROR] _SCStream_RemoteVideoQueueOperationHandlerWithError:1459 stream output NOT found. Dropping frame
```

### Root Cause
ScreenCaptureKit was capturing video frames (because we configured width/height) but we only registered an audio output handler. The framework was trying to deliver video frames but couldn't find a handler, resulting in dropped frames and error messages.

### Solution
Added a screen output handler that discards video frames:

```swift
// Add screen output handler (to prevent "stream output NOT found" errors)
// We discard video frames since we only want audio
try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: audioQueue)

// Add audio output handler
try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: audioQueue)
```

Updated the `SCStreamOutput` delegate method to handle both types:

```swift
nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
    if type == .audio {
        // Process audio...
    } else if type == .screen {
        // Discard video frames - we only want audio
        return
    }
}
```

### Why We Need Video Configuration
Even though we only want audio, ScreenCaptureKit requires:
1. A valid display filter (which inherently captures video)
2. Video configuration (width, height, pixel format)
3. Both screen and audio output handlers registered

We minimize the overhead by:
- Setting dimensions to 1x1 (smallest possible)
- Setting frame rate to 1 fps (lowest possible)
- Immediately discarding video frames in the handler

### Result
- No more error messages in console
- Audio capture works correctly
- Minimal CPU/memory overhead from video processing
- Clean, stable operation
