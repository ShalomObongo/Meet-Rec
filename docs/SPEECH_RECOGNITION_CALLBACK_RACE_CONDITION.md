# SFSpeechRecognizer Callback Queue Race Condition

## Critical Discovery

This document details a subtle but critical race condition discovered in the Speech framework's callback behavior.

## The Problem

The error "⚠️ Audio start time not set" was appearing for **EVERY** transcribed word, causing all transcription to fail.

## Root Cause Analysis

### Apple's Callback Queue Behavior

Through extensive research using Apple's documentation and header files:

**Key Finding:** The `resultHandler` callback in `recognitionTask(with:resultHandler:)` **runs on the main queue by default**.

From the SFSpeechRecognizer header:
> "The queue where recognition handlers should be executed on. Defaults to the main queue."

### The Race Condition Sequence

```swift
// Our code structure
recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
    guard let self = self else { return }

    Task { @MainActor in                    // Creates async task
        // Process result
        self.processTranscriptionResult(result)
    }
}
```

**What happens when user stops transcription:**

1. **Speech recognition is active** → Multiple result callbacks are queued on main queue
   ```
   Main Queue: [Callback A, Callback B, Callback C] ← waiting to execute
   ```

2. **User stops recording** → `stopTranscription()` executes synchronously on main thread
   ```swift
   func stopTranscription() {
       recognitionRequest?.endAudio()
       recognitionTask?.cancel()
       isTranscribing = false      // ← Set to false
       audioStartTime = nil         // ← Set to nil
   }
   ```

3. **Callbacks A, B, C still execute!** (they were already queued)
   - Each callback creates a `Task { @MainActor in }`
   - These Tasks run **asynchronously**

4. **By the time Tasks execute:**
   - `audioStartTime` is already `nil`
   - `isTranscribing` is already `false`
   - Guard check fails: `guard audioStartTime != nil else { ... }`

5. **Result:** Every queued callback produces the warning

### Why This Is Subtle

1. **Apple's docs don't explicitly state the queue behavior** - it's mentioned in header comments
2. **The `Task { @MainActor in }` creates asynchronous execution** - adds time delay
3. **Main queue != Main actor** - callbacks are on main queue but create async actor tasks
4. **Time gap allows state to change** between callback arriving and Task executing

## The Fix

### Two-Layer Defense

**Layer 1: Check at Task Creation** (line 93)
```swift
Task { @MainActor in
    // Early return if we've stopped transcribing
    guard self.isTranscribing else {
        return
    }
    // ... process result
}
```

**Layer 2: Check in Processing** (line 210)
```swift
private func processTranscriptionResult(_ result: SFSpeechRecognitionResult) {
    // Double-check we're still transcribing
    guard isTranscribing else {
        return
    }
    // ... process segments
}
```

### Why `isTranscribing` Instead of `audioStartTime`?

- **Semantically correct:** We should process results IFF we're actively transcribing
- **Single source of truth:** One flag to check instead of multiple state variables
- **Atomic state:** Set to `false` in `stopTranscription()`, checked in callbacks
- **Proper lifecycle:** Represents the actual transcription state

## Visualization

```
Time →

T0: Recognition active
    Main Queue: [Callback 1] [Callback 2] [Callback 3] ← queued, not yet run

T1: User clicks STOP
    stopTranscription() executes on main thread
    isTranscribing = false
    audioStartTime = nil
    recognitionTask?.cancel()

T2: Callback 1 executes (from queue)
    Creates Task { @MainActor in }
    Task queued on actor executor

T3: Callback 2 executes (from queue)
    Creates Task { @MainActor in }
    Task queued on actor executor

T4: Task from Callback 1 runs
    guard isTranscribing ← false! → early return ✅
    (Previously: guard audioStartTime != nil ← fails! → warning ❌)

T5: Task from Callback 2 runs
    guard isTranscribing ← false! → early return ✅
```

## Lessons Learned

### For Speech Recognition

1. **Always check transcription state** before processing results
2. **Use lifecycle flags** (`isTranscribing`) rather than implementation details (`audioStartTime`)
3. **Callbacks may execute after cancellation** - they're already queued!
4. **Async Tasks create time gaps** where state can change

### For Swift Concurrency

1. **Main queue ≠ Main actor:**
   - Callback on main queue
   - `Task { @MainActor in }` runs asynchronously on main actor
   - Time gap between the two!

2. **Queued callbacks persist:**
   - Canceling a task doesn't remove queued callbacks
   - Callbacks will still execute
   - Must handle gracefully

3. **Defense in depth:**
   - Check state at multiple points
   - Early returns prevent wasted work
   - Fail gracefully

## Testing This Fix

1. Start transcription
2. Speak a few words
3. While speech recognition is actively sending results, IMMEDIATELY stop recording
4. Check logs - should see NO "⚠️ Audio start time not set" warnings
5. Only see "ℹ️ Recognition request ended (user stopped)"

## References

- Apple's SFSpeechRecognizer header file
- Speech framework documentation
- Swift Concurrency documentation on actors and tasks
- [TRANSCRIPTION_FIX_SUMMARY.md](TRANSCRIPTION_FIX_SUMMARY.md) - Complete fix summary
