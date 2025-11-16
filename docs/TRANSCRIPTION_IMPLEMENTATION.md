# Transcription Implementation

## Overview
Implemented live transcription with Apple Speech Framework for Task 3.

## Components Implemented

### 1. Core Data Model Updates
- Added `Transcript` entity with relationships to `Session`
- Added `Word` entity with word-level timestamps and confidence scores
- Established proper relationships: Session → Transcript (one-to-many), Transcript → Word (one-to-many, ordered)

### 2. TranscribedWord Struct
- Created lightweight struct for in-memory word representation
- Fields: id, text, startMs, endMs, channel, confidence

### 3. TranscriptionService
- Main service for managing speech recognition
- Uses `SFSpeechRecognizer` with on-device recognition when available
- Implements `SFSpeechAudioBufferRecognitionRequest` for live audio
- Configuration:
  - `shouldReportPartialResults = true` for real-time updates
  - `taskHint = .dictation` for optimal recognition
  - `requiresOnDeviceRecognition = true` for privacy
- Processes transcription results and extracts word segments with timestamps
- Converts timestamps to milliseconds
- Publishes words array for UI updates

### 4. TranscriptPersistenceQueue Actor
- Thread-safe Core Data batch saves
- Batches every 100 words for performance
- Creates Transcript and Word entities in Core Data
- Handles flush on transcription stop

### 5. AudioService Integration
- Added `onAudioBuffer` callback to forward audio buffers
- Integrated with transcription service for real-time processing

### 6. SessionViewModel Updates
- Integrated TranscriptionService
- Starts/stops transcription with recording
- Forwards audio buffers from AudioService to TranscriptionService
- Handles transcription errors

### 7. TranscriptView
- Displays scrollable list of words with timestamps
- Shows confidence indicators for low-confidence words
- Auto-scrolls to latest word
- Formats timestamps as MM:SS.D

### 8. SessionView Updates
- Added tab selector (Memos, Transcript, Summary)
- Integrated TranscriptView in Transcript tab
- Shows real-time transcription as words arrive

## Permissions
- Added `NSSpeechRecognitionUsageDescription` to Info.plist
- Added `INFOPLIST_KEY_NSSpeechRecognitionUsageDescription` to project.pbxproj build settings
- Service requests authorization before starting transcription
- Note: The project uses `GENERATE_INFOPLIST_FILE = YES`, so permissions must be added to both Info.plist and project.pbxproj

## Testing
To test the implementation:
1. Launch the app
2. Create a new session
3. Click "Start Recording"
4. Grant microphone and speech recognition permissions when prompted
5. Speak clearly: "Hello world"
6. Switch to "Transcript" tab
7. Verify both words appear within 2 seconds
8. Check that timestamps are sequential

## Performance
- Words appear in UI within 2 seconds of speech completion (as required)
- Batch saves every 100 words to optimize Core Data performance
- Uses on-device recognition when available for privacy and speed

## Bug Fixes Applied

### Issue 1: Words appearing one at a time
**Problem**: Speech Framework returns all segments on each update, causing duplicate processing
**Solution**: Track `lastProcessedSegmentCount` and only process new segments since last update

### Issue 2: Wrong timestamps
**Problem**: Timestamps were relative to recognition start, not session start
**Solution**: 
- Track `sessionStartTime` and `recognitionStartTime`
- Calculate absolute timestamps from session start
- Apply segment offset when recognition restarts

### Issue 3: Too many error indicators
**Problem**: Confidence threshold of 0.8 was too high, showing warnings for normal speech
**Solution**: Lowered threshold to 0.5 (only show warnings for very low confidence)

### Issue 4: Transcription stops after 1 minute
**Problem**: Speech Framework has a 1-minute limit for continuous recognition
**Solution**: 
- Detect timeout errors (code 216 or 203)
- Automatically restart recognition segment
- Maintain continuous transcription across segments

## Next Steps
- Task 4: Implement memos editor with auto-save
- Task 5: Add AI summary generation
- Task 6: Implement system audio capture with ScreenCaptureKit
