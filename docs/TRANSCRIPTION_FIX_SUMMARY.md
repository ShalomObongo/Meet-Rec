# Speech Recognition Transcription Fixes

## Issues Fixed

### 1. Incorrect Timestamps
**Problem:** Timestamps were being double-offset, causing incorrect word timing.

**Root Cause:** According to Apple's documentation, `SFTranscriptionSegment.timestamp` is already "the number of seconds between the beginning of the audio content and when the user spoke the word." The code was adding an additional offset from session start, which was incorrect.

**Solution:**
- Removed the complex offset calculation
- `segment.timestamp` is now used directly (converted to milliseconds)
- Recording start time is tracked and passed from SessionViewModel to TranscriptionService
- Timestamps are now accurate relative to when audio recording began

### 2. Error Code 301 "Recognition request was canceled"
**Problem:** UI showed error signs and logged cancellation errors when stopping transcription.

**Root Cause:** Error code 301 is the EXPECTED error when calling `recognitionTask?.cancel()` during normal shutdown. The code was treating this as an unexpected error.

**Solution:**
- Added specific handling for error code 301 to ignore it (it's expected behavior)
- Changed error message from "❌" to "ℹ️" for user-initiated stops
- Prevented this error from being set as `errorMessage` which caused UI error indicators

### 3. Transcription Stopping Prematurely
**Problem:** After a while, transcription would stop working.

**Root Cause:** Multiple potential causes:
- Error 301 was being treated as a real error, potentially disrupting the flow
- The 1-minute recognition limit restart logic existed but errors were interfering

**Solution:**
- Improved error handling to distinguish between:
  - Code 301: User-initiated cancellation (normal)
  - Code 216/203: 1-minute timeout (needs restart)
  - Other codes: Actual errors
- Automatic restart on 1-minute timeout now works properly

### 4. Duplicate Word Processing
**Problem:** Speech recognition sends multiple partial results with ALL segments from the beginning, which could cause duplicate processing.

**Root Cause:** The previous approach used array indices (`lastProcessedSegmentCount`) to track processed words, but this could fail if Apple's Speech framework changed segment boundaries in later results.

**Solution:**
- Changed to Set-based deduplication using unique segment IDs
- Segment ID includes: text + timestamp + duration
- This ensures each unique segment is processed exactly once, even across partial results

### 5. "Audio start time not set" Warning (Callback Queue Race Condition)
**Problem:** Warning appeared for EVERY transcribed word: "⚠️ Audio start time not set"

**Root Cause (CRITICAL DISCOVERY):**
According to Apple's SFSpeechRecognizer header and documentation research:
- **The `resultHandler` callback runs on the main queue by default**
- When you stop transcription, there are **already-queued callbacks on the main queue** that haven't executed yet
- The problematic sequence:
  1. Recognition task sends results → callbacks queued on main queue
  2. User stops recording → `stopTranscription()` executes synchronously
  3. Sets `audioStartTime = nil` immediately
  4. Cancels recognition task
  5. **But queued callbacks still execute!**
  6. They create `Task { @MainActor in }` which executes asynchronously
  7. By the time the Task runs, `audioStartTime` is already nil
  8. Guard check fails

**Solution:**
- Added early `guard isTranscribing` check at the START of the callback Task block (line 93)
- This prevents processing stale callbacks from stopped recognition tasks
- Changed `processTranscriptionResult()` to check `isTranscribing` instead of `audioStartTime != nil`
- This is semantically correct: we should only process results if actively transcribing
- The check happens inside the async Task, so it sees the updated `isTranscribing` state

### 6. Speech Loss During 1-Minute Auto-Restart
**Problem:** Audio might be lost during the automatic segment restart (1-minute limit).

**Root Cause:** The restart sequence had a gap where audio buffers weren't being captured:
1. Old request ended
2. Old task canceled
3. Brief gap before new request created
4. Audio buffers dropped during this gap

**Solution:**
- Completely redesigned restart sequence to minimize gaps:
  1. Store reference to old task/request
  2. **Immediately** create new recognition segment (new request starts receiving audio)
  3. Then clean up old task
- Process any final results from the old segment before restarting
- **DO NOT** clear `processedSegments` on restart (only on full stop)
- This ensures continuity across segment boundaries with minimal audio loss
- Added proper error handling for restart failures

## Implementation Changes

### TranscriptionService.swift
**State Management:**
- Changed from `sessionStartTime` and `recognitionStartTime` to `recordingStartTime` and `audioStartTime`
- Changed from `lastProcessedSegmentCount` (Int) to `processedSegments` (Set<String>)
- Set `audioStartTime` and `isTranscribing` BEFORE starting recognition segment (fixes race condition)

**Timestamp Handling:**
- Updated `startTranscription()` to accept `recordingStartTime` parameter
- Simplified timestamp calculation to use `segment.timestamp` directly
- Removed incorrect offset calculations

**Error Handling:**
- Added proper error code filtering (301, 216, 203)
- Process final results before restarting on 1-minute timeout
- Improved error messages and logging

**Restart Logic:**
- Completely redesigned `restartRecognitionSegment()`:
  - Store reference to old task/request
  - Create new segment immediately (before cleanup)
  - Clean up old task after new one is ready
- Maintains `processedSegments` across restarts (only cleared on full stop)
- Added error handling for restart failures

**Audio Buffer Handling:**
- Added guards to `appendAudioBuffer()` for safety
- Only append buffers when actively transcribing
- Ensures smooth transition during restarts

**Deduplication:**
- Uses Set-based deduplication with unique segment IDs
- Segment ID format: `"{text}_{timestampMs}_{durationMs}"`

### SessionViewModel.swift
- Captures `recordingStartTime` before starting audio/transcription
- Passes `recordingStartTime` to `TranscriptionService.startTranscription()`
- Uses same timestamp for `session.startedAt` to keep everything synchronized

## Apple Documentation References

### SFTranscriptionSegment.timestamp
> "The timestamp is the number of seconds between the beginning of the audio content and when the user spoke the word represented by the segment."

**Key Insight:** This is already an absolute time from when audio buffering started, NOT relative to some arbitrary recognition task creation time.

### SFTranscriptionSegment.duration
> "The duration contains the number of seconds it took for the user to speak the one or more words (utterance) represented by the segment."

### Error Codes
- **301**: Recognition request was canceled (expected on normal stop)
- **216/203**: Recognition timeout (1-minute limit, needs restart)

## Testing Recommendations

1. **Timestamp Accuracy**: Verify that word timestamps match when they were actually spoken
2. **Long Recordings**: Test recordings longer than 1 minute to ensure automatic restart works
   - Watch for "🔄 Restarting recognition segment..." message in logs
   - Verify no speech is lost during the transition
   - Check that transcription continues seamlessly
3. **Stop/Start**: Verify no error indicators appear when normally stopping transcription
   - Should see "ℹ️ Recognition request ended (user stopped)" not an error
4. **No Duplicates**: Check that words aren't duplicated in the transcript
5. **Continuous Operation**: Verify transcription continues working for extended periods
   - Test 5+ minute recordings
   - Check for multiple automatic restarts
6. **No Warnings**: Verify "⚠️ Audio start time not set" warning no longer appears
7. **Rapid Start**: Test quick stop/start cycles to ensure race conditions are handled

## Key Design Decisions

### Why Create New Request Before Cleaning Up Old One?
During restart, we create the new recognition segment BEFORE cleaning up the old one. This design:
- Minimizes the gap where `recognitionRequest` is nil
- Ensures `appendAudioBuffer()` always has a valid request to append to
- Prevents audio loss during the transition
- The old request's cancellation (error 301) is safely ignored

### Why Use Set-Based Deduplication?
Speech recognition sends ALL segments with each partial result, not just new ones:
```
Result 1: ["Hello"]
Result 2: ["Hello", "world"]  // Contains both, not just "world"
Result 3: ["Hello", "world", "how"]  // Contains all three
```
Using a Set prevents processing "Hello" and "world" multiple times.

### Why Maintain processedSegments Across Restarts?
When the 1-minute limit triggers:
- The old task ends with final results
- New task starts fresh with empty state
- BUT some segments might appear in both final result and new task's initial results
- Keeping `processedSegments` prevents duplicates across this boundary

### Why Check isTranscribing in appendAudioBuffer?
Extra safety for edge cases:
- Prevents appending after user stops transcription
- Handles brief window during restart when request might be transitioning
- Fails gracefully instead of appending to stale request

### Why Check isTranscribing at Task Start AND in processTranscriptionResult?
This is **defense in depth** against the callback queue race condition:

**The Problem:**
```swift
// SFSpeechRecognizer callbacks run on main queue by default
recognitionTask = recognizer.recognitionTask(with: request) { result, error in
    // This callback is on main queue, but then we create async Task
    Task { @MainActor in
        // By the time this executes, state may have changed!
        processTranscriptionResult(result)
    }
}
```

**Why Two Checks:**
1. **Check at Task start (line 93):** Catches callbacks queued BEFORE stopTranscription() was called
2. **Check in processTranscriptionResult (line 210):** Extra safety for any edge cases

**The Race Condition:**
- Main queue has: `[Callback A, Callback B, Callback C]` (not yet executed)
- User calls `stopTranscription()` (executes on main thread)
- Sets `isTranscribing = false`
- Cancels task
- Callbacks A, B, C still execute (they were already queued!)
- Each creates a `Task { @MainActor in }` which runs asynchronously
- By the time Tasks run, `isTranscribing` is false → early return

**Why This Wasn't Obvious:**
- Apple's docs don't clearly state callbacks run on main queue
- The `Task { @MainActor in }` creates async execution
- Time delay between callback arrival and Task execution allows state to change
- This explains why the warning appeared for EVERY transcribed word after stopping

## Notes

- The "one word at a time" behavior in logs is EXPECTED and CORRECT for live speech recognition
- Apple's Speech framework sends frequent partial results as speech is recognized
- Each partial result contains ALL segments from the beginning, not just new ones
- This is why deduplication is critical
- The 1-minute limit is a Speech framework constraint, not a bug
- Audio continues flowing during restarts; only the recognition task restarts
