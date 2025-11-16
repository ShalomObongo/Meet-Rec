# AI Summary Generation Implementation

## Overview

This document describes the implementation of Task 5: AI summary generation with OpenAI streaming API support.

## Implementation Date

November 17, 2025

## Components Implemented

### 1. Core Data Model Update

**File:** `MeetRec/MeetRec.xcdatamodeld/MeetRec.xcdatamodel/contents`

Added `enhancedMarkdown` attribute to the Session entity to store AI-generated summaries.

```xml
<attribute name="enhancedMarkdown" optional="YES" attributeType="String"/>
```

### 2. Sandbox Entitlements

**File:** `MeetRec/MeetRec.entitlements`

Added network client entitlement to allow HTTPS requests to OpenAI API:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

### 3. KeychainService

**File:** `MeetRec/Services/KeychainService.swift`

Secure storage service for API keys using macOS Keychain with `kSecAttrAccessibleWhenUnlocked` accessibility level.

**Features:**
- Save API keys securely
- Retrieve API keys
- Delete API keys
- Check if key exists
- Thread-safe singleton pattern

**Security:**
- Uses `kSecClassGenericPassword` for password storage
- Accessibility set to `kSecAttrAccessibleWhenUnlocked` (data only accessible when device is unlocked)
- Automatic cleanup of existing items before saving

### 4. AutonomyLevel Enum

**File:** `MeetRec/Services/AIService.swift`

Defines two levels of AI autonomy:

- **Grounded**: Uses only user's memos for summary generation
- **Creative**: Uses both memos and full transcript for comprehensive summaries

### 5. AIService

**File:** `MeetRec/Services/AIService.swift`

Main service for AI summary generation with OpenAI streaming API.

**Features:**
- Streaming chat completions via URLSession
- Server-Sent Events (SSE) parsing
- Retry logic with exponential backoff (3 attempts)
- Error handling for network, API, and content errors
- Support for both autonomy levels

**API Integration:**
- Endpoint: `https://api.openai.com/v1/chat/completions`
- Model: `gpt-4o-mini`
- Streaming: Enabled via `stream: true` parameter
- Authentication: Bearer token via Authorization header

**Prompt Building:**
- Grounded mode: "Summarize these memos..."
- Creative mode: "Summarize this meeting: Memos: ... Transcript: ..."

**Error Handling:**
- Missing API key detection
- Network error handling
- Invalid response handling
- Empty content validation
- Streaming error recovery

### 6. SessionViewModel Updates

**File:** `MeetRec/ViewModels/SessionViewModel.swift`

Added AI summary generation capabilities to the session view model.

**New Properties:**
- `aiService: AIService` - AI service instance
- `autonomyLevel: AutonomyLevel` - Current autonomy level
- `isGeneratingSummary: Bool` - Generation state
- `streamingSummary: String` - Accumulated streaming content
- `summaryError: String?` - Error message if generation fails

**New Methods:**
- `generateSummary()` - Async method to generate summary with streaming

**Implementation Details:**
- Fetches transcript words from Core Data when creative mode is selected
- Streams content chunks and accumulates them
- Saves final summary to `session.enhancedMarkdown`
- Handles cancellation and errors gracefully

### 7. SummaryView

**File:** `MeetRec/Views/SummaryView.swift`

SwiftUI view for displaying and generating AI summaries.

**Features:**
- Autonomy level picker (Grounded/Creative)
- Generate Summary button with loading state
- Streaming text display with skeleton loader
- Error state with retry button
- Empty state with helpful instructions
- Saved summary display

**UI States:**
1. **Generating**: Shows skeleton loader and streaming text
2. **Error**: Shows error message with retry button
3. **Saved**: Displays previously generated summary
4. **Empty**: Shows empty state with instructions

**Visual Effects:**
- Shimmer animation for skeleton loader
- Progress indicator during generation
- Icon-based state indicators

### 8. SessionView Updates

**File:** `MeetRec/SessionView.swift`

Added autonomy level picker to session header and integrated SummaryView.

**Header Additions:**
- Autonomy level menu with icon and description
- Visual indicator for current autonomy level
- Tooltip with autonomy description

**Tab Integration:**
- Summary tab now shows SummaryView instead of placeholder

## Testing

### Unit Tests

**File:** `MeetRecTests/KeychainServiceTests.swift`

Comprehensive tests for KeychainService:
- ✅ Save and retrieve API key
- ✅ Check key existence
- ✅ Handle non-existent key retrieval
- ✅ Delete keys

All tests passed successfully.

### Manual Testing Checklist

- [x] Build succeeds without errors
- [x] App launches successfully
- [ ] Generate summary with valid API key (requires user testing)
- [ ] Verify streaming text appears progressively
- [ ] Test with invalid API key - verify error message
- [ ] Test retry button functionality
- [ ] Test autonomy level switching
- [ ] Verify summary saves to Core Data
- [ ] Test with empty memos - verify error message

## API Key Configuration

Users need to configure their OpenAI API key. This will be done through the Settings panel (Task 11).

For now, developers can set the API key programmatically:

```swift
let aiService = AIService()
try aiService.saveAPIKey("sk-your-api-key-here")
```

## Requirements Satisfied

- ✅ 6.1: Support multiple LLM providers (OpenAI implemented)
- ✅ 6.2: Use selected autonomy level to determine input sources
- ✅ 6.3: Grounded mode uses only memos
- ✅ 6.4: Creative mode uses memos and transcript
- ✅ 6.6: Stream results to UI as produced
- ✅ 6.7: Allow regeneration with different settings
- ✅ 8.6: Encrypt sensitive data (API keys in Keychain)
- ✅ 11.5: Store API keys securely

## Known Limitations

1. Only OpenAI is currently supported (other providers in Task 11)
2. No template support yet (Task 14)
3. Settings UI for API key configuration not yet implemented (Task 11)
4. No retry count indicator in UI
5. Model selection is hardcoded to `gpt-4o-mini`

## Future Enhancements

1. Add support for Anthropic, OpenRouter, and Ollama (Task 11)
2. Implement template-based summaries (Task 14)
3. Add model selection in Settings
4. Show retry attempt count in UI
5. Add summary regeneration history
6. Support for custom system prompts
7. Token usage tracking and display

## Dependencies

- Foundation (URLSession, JSONSerialization)
- Security (Keychain Services)
- SwiftUI (UI components)
- CoreData (Session entity, Word entity)
- Combine (async/await integration)

## Performance Considerations

- Streaming reduces perceived latency
- Exponential backoff prevents API rate limit issues
- Background context used for Core Data fetches
- Cancellable tasks prevent memory leaks
- Efficient SSE parsing with line-by-line processing

## Security Considerations

- API keys stored in Keychain with `kSecAttrAccessibleWhenUnlocked`
- HTTPS-only communication with OpenAI
- No API keys logged or exposed in UI
- Sandbox entitlement limits network access to explicit client connections
- Bearer token authentication

## Debugging Tips

1. Check Keychain for stored API key:
   ```swift
   let hasKey = KeychainService.shared.exists(key: "openai_api_key")
   ```

2. Monitor streaming in console:
   ```swift
   for try await chunk in stream {
       print("Received chunk: \(chunk)")
   }
   ```

3. Test with curl:
   ```bash
   curl https://api.openai.com/v1/chat/completions \
     -H "Authorization: Bearer YOUR_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Test"}],"stream":true}'
   ```

## References

- [OpenAI Chat Completions API](https://platform.openai.com/docs/api-reference/chat/create)
- [Apple Keychain Services](https://developer.apple.com/documentation/security/keychain-services/)
- [Server-Sent Events Specification](https://html.spec.whatwg.org/multipage/server-sent-events.html)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
