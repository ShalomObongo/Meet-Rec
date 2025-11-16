# Speech Recognition Confidence Score Issue & Fix

## Problem

Every transcribed word was showing a ⚠️ warning symbol in the UI, indicating low confidence.

## Root Cause Discovery

Through research using Apple's documentation (Context7 MCP and Apple Docs MCP):

### Key Finding from Apple Developer Forums & Stack Overflow

> **"Confidence values are typically 0.0 for partial results and only become non-zero for final results."**

### Why This Happened

1. **Partial Results Have Zero Confidence**
   - We use `shouldReportPartialResults = true` for live transcription
   - This provides a great UX - users see words as they're spoken
   - BUT: partial results always have `segment.confidence = 0.0`
   - Only when `result.isFinal == true` do we get accurate confidence values

2. **Our Deduplication Prevented Updates**
   - Original logic: Use `Set<String>` to track processed segment IDs
   - When partial result arrives: Add segment to set
   - When final result arrives: **Same segment ID → SKIPPED!**
   - Result: Confidence values were never updated from 0.0 to actual values

### The Problematic Sequence

```
1. Partial result: "hello" at 1.0s
   - confidence = 0.0
   - segmentId = "hello_1000_500"
   - Added to processedSegments
   - Word created with confidence = 0.0 ❌

2. Final result: "hello" at 1.0s
   - confidence = 0.94 ✓
   - segmentId = "hello_1000_500"
   - Already in processedSegments
   - SKIPPED! Confidence never updated ❌

3. UI checks: confidence (0.0) < 0.5?
   - YES → Show warning ⚠️
```

## The Fix

### Changes Made

#### 1. Updated `TranscribedWord` Struct

```swift
struct TranscribedWord: Identifiable {
    var confidence: Double  // Changed from 'let' to 'var' - can update
    var isFinal: Bool       // Track whether from final result
}
```

#### 2. Changed Deduplication Strategy

**Before:** `Set<String>` tracking segment IDs
```swift
private var processedSegments: Set<String> = []
```

**After:** Dictionary mapping segment IDs to word IDs
```swift
private var segmentIdToWordId: [String: UUID] = [:]
```

This allows us to:
- Find existing words when final results arrive
- Update their confidence values
- Mark them as final

#### 3. Updated Processing Logic

```swift
for segment in segments {
    let segmentId = "..."

    // Check if we've seen this segment before
    if let existingWordId = segmentIdToWordId[segmentId] {
        // Update confidence if this is a final result
        if result.isFinal {
            if let index = words.firstIndex(where: { $0.id == existingWordId }) {
                words[index].confidence = segment.confidence
                words[index].isFinal = true
            }
        }
        continue  // Don't add duplicate
    }

    // New segment - create word
    let word = TranscribedWord(...)
    segmentIdToWordId[segmentId] = word.id
}
```

#### 4. Fixed UI Display Logic

**Before:** Show warning for ANY word with confidence < 0.5
```swift
if word.confidence < 0.5 {
    // ⚠️ shown for all partial results (confidence = 0)
}
```

**After:** Only show warning for FINAL results with low confidence
```swift
if word.isFinal && word.confidence < 0.5 {
    // ⚠️ only shown for genuinely low-confidence final results
}
```

#### 5. Added Confidence Logging

Now logs each word's confidence score:
```
📝 'Hello' - confidence: 0.00 [isFinal: false]
✓ Updated word 'Hello' with final confidence: 0.94
📝 'world' - confidence: 0.00 [isFinal: false]
✓ Updated word 'world' with final confidence: 0.87
```

#### 6. Display Confidence Percentage in UI

Added confidence percentage display for final results:
- Shows percentage next to each final result
- Color-coded: orange if < 50%, gray otherwise
- Helps debug and verify the fix

## Technical Details

### Apple's Confidence Value Specification

From `SFTranscriptionSegment.confidence` documentation:
- **Type:** `Float`
- **Range:** 0.0 to 1.0
- **0:** No recognition
- **~1.0:** High certainty
- **Example:** 0.94 = very high confidence, 0.72 = good confidence

### Regional Considerations

Research also uncovered regional issues:
- Some regions (Malaysia, Saudi Arabia) may have confidence always at 0
- Setting device region to US or Russia produces correct values
- This is a known limitation of on-device models for certain locales

### On-Device vs Server Recognition

- **On-device:** May have lower quality but works offline
- **Server-based:** Higher quality but requires internet
- Both support confidence scores, but on-device may be less accurate

## Files Modified

1. **TranscribedWord.swift**
   - Made `confidence` mutable (`var` instead of `let`)
   - Added `isFinal` property

2. **TranscriptionService.swift**
   - Changed from `Set<String>` to `[String: UUID]` for segment tracking
   - Added logic to update confidence values when final results arrive
   - Enhanced logging to show confidence scores

3. **TranscriptView.swift**
   - Updated warning condition to check `isFinal` flag
   - Added confidence percentage display
   - Updated preview with sample data

## Expected Behavior After Fix

### During Live Transcription

1. **Partial result arrives:**
   - Word appears immediately (good UX)
   - Confidence = 0.0 (expected)
   - `isFinal = false`
   - **No warning shown** (partial results are normal)

2. **Final result arrives:**
   - Same word's confidence updated (e.g., 0.94)
   - `isFinal = true`
   - Confidence percentage displayed
   - **Warning only if < 0.5** (rare)

### In Console Logs

```
📝 'Hello' - confidence: 0.00 [isFinal: false]
📝 'there' - confidence: 0.00 [isFinal: false]
✓ Updated word 'Hello' with final confidence: 0.94
✓ Updated word 'there' with final confidence: 0.87
📝 Added 2 new words (total: 2)
✓ Final result received with 2 total segments
```

### In UI

- Partial results: Just the word text (no confidence info)
- Final results: Word text + confidence percentage
- Low confidence finals: Word text + percentage + ⚠️ warning

## Testing Recommendations

1. **Start recording and speak**
2. **Watch console logs** - should see:
   - Partial results with confidence: 0.00
   - Final results updating confidence to 0.7-0.99 range
3. **Check UI** - should see:
   - No ⚠️ warnings on most words
   - Confidence percentages appearing as speech finalizes
   - Warnings only on genuinely unclear speech (rare)

## References

- Apple Developer Forums: "SFTranscriptionSegment confidence always 0"
- Stack Overflow: "Speech Recognition: Alternate substrings always empty, confidence 0"
- Apple Documentation: `SFTranscriptionSegment.confidence` property
- Apple Documentation: `SFSpeechRecognitionResult.isFinal` property

## Lessons Learned

1. **Read the fine print:** Partial results vs final results have very different metadata
2. **Don't trust confidence = 0:** It's expected behavior for live transcription
3. **Update strategies matter:** Simple deduplication can prevent important updates
4. **UI should reflect reality:** Don't show warnings for expected behavior
5. **Log everything during development:** Confidence scores help verify the fix
