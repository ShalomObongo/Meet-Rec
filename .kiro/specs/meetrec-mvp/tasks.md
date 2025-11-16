# Implementation Plan

## Vertical Slice Approach

Each task below delivers a working, testable feature. Complete tasks in order to build incrementally on previous work.

## Testing Guidelines

After completing each task, verify the deliverable works as expected:

**Audio & Recording (Tasks 2, 6, 13, 17):**
- Start recording and speak - confirm mic/speaker level indicators move in real-time
- Deny microphone permission - verify error alert appears with "Open System Settings" button
- Switch audio sources during recording - confirm transition happens within 2 seconds without crashes
- Record for 30+ seconds - verify no memory leaks or performance degradation

**Transcription (Tasks 3, 12, 19):**
- Speak clearly for 10 seconds - verify words appear within 2 seconds of speech completion
- Check word timestamps - click words in transcript to verify they match audio position
- Test with background noise - confirm transcription quality is acceptable
- Deny speech recognition permission - verify error handling and fallback behavior

**AI & Summaries (Tasks 5, 14):**
- Generate summary with empty memos - verify appropriate error message
- Generate summary with invalid API key - verify retry logic and error UI
- Test streaming - confirm text appears progressively, not all at once
- Switch autonomy levels - verify "grounded" uses only memos, "creative" uses transcript too

**Data & Persistence (Tasks 1, 4, 7, 8, 18):**
- Create 50+ sessions - verify list performance remains smooth
- Force quit app during recording - relaunch and verify crash recovery prompt appears
- Auto-save test: type in memos, wait 2 seconds, force quit, relaunch - verify content saved
- Search with special characters - verify no crashes

**Calendar & Export (Tasks 9, 10, 20):**
- Link session to calendar event - verify metadata displays correctly
- Export to PDF - open file and verify formatting is readable
- Export to Obsidian - open in Obsidian and verify links work
- Deny calendar permission - verify graceful error handling

**UI & Navigation (Tasks 7, 8, 16, 21):**
- Open 10 tabs - verify tab bar doesn't overflow, tabs are closeable
- Test keyboard shortcuts - verify Cmd+W, Cmd+T, Cmd+1-9 work correctly
- Resize window to minimum size - verify UI doesn't break
- Test in Dark Mode - verify colors and contrast are appropriate

## Liquid Glass Guidelines

For any task that involves SwiftUI UI work (views, controls, navigation, panels), the AI should also consider Apple’s Liquid Glass design:

- Before implementing the UI, **use the Apple Developer Documentation MCP** to:
  - Call `search_apple_docs` for Liquid Glass topics such as:
    - "Adopting Liquid Glass"
    - "Liquid Glass"
    - "Applying Liquid Glass to custom views"
    - `glassEffect(_:in:)`
    - `Glass`
    - `GlassEffectContainer`
  - Then call `get_apple_doc_content` on the most relevant results to understand how to configure and apply Liquid Glass in SwiftUI.
- When designing or refining SwiftUI views (shell, sidebars, headers, cards, buttons, settings panels, onboarding, timelines, etc.), use that documentation to decide **where Liquid Glass would enhance the experience**:
  - For example, applying `glassEffect(_:in:)` to cards, headers, or action buttons, or using `Glass`/`GlassEffectContainer` for grouped elements.
- Prefer subtle, purposeful use of Liquid Glass that matches Apple’s guidance, rather than applying it everywhere.

- [x] 1. Basic app shell with session list
  - Create Xcode project with SwiftUI app template targeting macOS 12.0+
  - Configure app bundle identifier, version, and build settings
  - Add Core Data model file (.xcdatamodeld) with Session entity (id, title, createdAt, rawMarkdown)
  - Implement PersistenceController with NSPersistentContainer and viewContext
  - Create @MainActor AppState view model with @Observable (macOS 14+)
  - Create ContentView with HSplitView (sidebar + main content area)
  - Create SidebarView with List showing sessions grouped by date
  - Create simple SessionView that displays session title and empty memos editor
  - Implement "New Session" button that creates a session in Core Data
  - Add basic navigation: clicking a session in sidebar opens it in main content area
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` to find SwiftUI app structure docs (`App`, scenes, list/navigation containers like `NavigationSplitView`), Core Data docs (`NSPersistentContainer`, \"Setting up a Core Data stack\"), and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on the chosen results to see concrete usage, how to wire the managed object context into SwiftUI views, and where a Liquid Glass background or container might enhance the shell UI.
  - **Deliverable**: App launches, shows session list, can create and view sessions
  - **Test**: Launch app, click "New Session", verify session appears in sidebar; click session, verify it opens in main area
  - _Requirements: 4.1, 4.2, 8.1, 8.2, 10.1_

- [x] 2. Microphone recording with visual feedback
  - Add Info.plist key: NSMicrophoneUsageDescription with clear usage description
  - Configure sandbox entitlement: com.apple.security.device.microphone
  - Define AudioSource enum with cases: micAndSystem, micOnly, systemOnly
  - Create AudioService class with @Published properties: isRecording, micLevel, audioSource
  - Implement startRecording method that requests microphone permission and sets up AVAudioEngine
  - Set up AVAudioEngine with input node and mixer node, configure audio format (48kHz, 2 channels)
  - Install tap on mixer node with buffer size 4096, process on background queue (QoS .userInitiated)
  - Calculate RMS amplitude for mic level visualization (normalize to 0.0-1.0 range)
  - Implement stopRecording method that stops engine and removes tap
  - Create @MainActor SessionViewModel with AudioService dependency
  - Add "Start Recording" / "Stop Recording" button to SessionView
  - Display real-time mic level indicator (progress bar or waveform)
  - Update session startedAt/endedAt timestamps in Core Data when recording starts/stops
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for `AVAudioEngine`, `AVAudioInputNode`, and media capture authorization (for example `requestAccess(for:completionHandler:)` on `AVCaptureDevice`), and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those symbols and on SwiftUI controls like `Button` and `ProgressView` to guide both the audio setup, the recording/level UI, and where a subtle Liquid Glass treatment on the recording button or level indicator would make sense.
  - **Deliverable**: Click button to start/stop recording, see live mic level visualization
  - **Test**: Start recording, speak loudly/softly, verify level indicator responds; deny mic permission, verify error alert with Settings link
  - _Requirements: 1.1, 1.3, 1.5, 12.1_

- [x] 3. Live transcription with Apple Speech Framework
  - Add Info.plist key: NSSpeechRecognitionUsageDescription with clear usage description
  - Add Transcript and Word entities to Core Data model (id, text, startMs, endMs, channel, confidence)
  - Define relationships: Session → Transcript (one-to-many), Transcript → Word (one-to-many, ordered)
  - Create TranscribedWord struct with id, text, startMs, endMs, channel, confidence
  - Create TranscriptionService class with @Published property: words array
  - Implement startTranscription method that requests speech recognition authorization
  - Create SFSpeechAudioBufferRecognitionRequest with requiresOnDeviceRecognition = true
  - Configure request: shouldReportPartialResults = true, taskHint = .dictation
  - Connect AudioService audio buffers to recognition request
  - Process SFTranscription results and extract word segments with timestamps
  - Convert timestamps to milliseconds and create TranscribedWord objects
  - Publish words to @Published array for UI updates (within 2 seconds of speech)
  - Create actor TranscriptPersistenceQueue for thread-safe Core Data batch saves (every 100 words)
  - Add TranscriptView to SessionView showing scrollable list of words with timestamps
  - Display words in real-time as they arrive from transcription service
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for Speech framework symbols like `SFSpeechRecognizer`, `SFSpeechAudioBufferRecognitionRequest`, `SFTranscription`, and the \"Asking Permission to Use Speech Recognition\" article, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on the most relevant results and on SwiftUI list/scrolling views (for example `List` or `ScrollView`) to inform both the transcription pipeline, the TranscriptView UI, and where Liquid Glass headers or highlight cards would improve readability.
  - **Deliverable**: Record audio and see live transcription appear word-by-word
  - **Test**: Speak "Hello world" clearly, verify both words appear within 2 seconds; check timestamps are sequential
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 8.2, 12.3_

- [x] 4. Memos editor with auto-save
  - Add rawMarkdown field to Session entity if not already present
  - Create MemosEditorView with TextEditor bound to session.rawMarkdown
  - Add markdown formatting toolbar with buttons: bold, italic, heading, list
  - Implement toolbar actions that insert markdown syntax at cursor position
  - Add @Published property in SessionViewModel for memos content
  - Implement auto-save logic: debounce text changes by 2 seconds, then save to Core Data
  - Display word count indicator below editor
  - Add editor tab switcher: Summary, Memos, Transcript (default to Memos)
  - Update SessionView to show selected editor tab content
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for `TextEditor` and Core Data+SwiftUI integration articles, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those results and any relevant SwiftUI toolbar/button docs to learn recommended patterns for text editing, markdown toolbars, binding Core Data–backed state into SwiftUI views, and applying Liquid Glass to memo/editor chrome where appropriate.
  - **Deliverable**: Type notes during recording, see auto-save and word count
  - **Test**: Type text, wait 2 seconds, force quit app, relaunch - verify text was saved; check word count updates live
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 5. AI summary generation with OpenAI
  - Add enhancedMarkdown field to Session entity for storing summaries
  - Configure sandbox entitlement: com.apple.security.network.client
  - Create KeychainService for secure API key storage (kSecAttrAccessibleWhenUnlocked)
  - Define AutonomyLevel enum with cases: grounded, creative
  - Create AIService class with method: generateSummary(memos, transcript, autonomy) -> AsyncThrowingStream<String, Error>
  - Implement OpenAI streaming chat completions via URLSession
  - Build prompt: "Summarize these memos:" (grounded) or "Summarize this meeting: Memos: ... Transcript: ..." (creative)
  - Parse Server-Sent Events (SSE), extract content deltas, yield to stream
  - Handle "data: [DONE]" termination and errors with retry logic (3 attempts, exponential backoff)
  - Add generateSummary method to SessionViewModel that calls AIService
  - Create SummaryView with "Generate Summary" button and streaming text display
  - Show skeleton loader during generation, display error with retry button on failure
  - Store final summary in Session.enhancedMarkdown when stream completes
  - Add autonomy level picker (Grounded / Creative) to session header
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for `URLSession` async/await examples and Keychain Services topics, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those results and SwiftUI view docs for progress indicators and text streaming (for example `ProgressView`, `Text`) to confirm streaming patterns, secure credential storage, the SummaryView UI, and where a Liquid Glass card or button style would enhance the summary area. Additionally, for the OpenAI HTTP API itself, use the Context7 MCP: call `resolve-library-id` with a query like `openai api` to find the right docs, then `get-library-docs` with that id and a topic such as `chat completions streaming` so your request/response handling matches the provider specification.
  - **Deliverable**: Click "Generate Summary" to create AI summary from memos/transcript
  - **Test**: Generate with valid API key, verify streaming text appears; test with invalid key, verify retry button appears
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.6, 6.7, 8.6, 11.5_

- [x] 6. System audio capture with ScreenCaptureKit
  - Add Info.plist key: NSScreenCaptureUsageDescription with clear usage description
  - Create SystemAudioService class for macOS 12.3+ with availability check
  - Implement startCapture method that requests screen recording permission
  - Use SCShareableContent.current to get available displays
  - Configure SCStreamConfiguration: capturesAudio = true, sampleRate = 48000, channelCount = 2, excludesCurrentProcessAudio = true
  - Create SCStream with display filter and add audio output handler
  - Implement SCStreamDelegate and SCStreamOutput protocols
  - Convert CMSampleBuffer to AVAudioPCMBuffer in stream output handler
  - Calculate RMS amplitude for speaker level visualization
  - Integrate SystemAudioService into AudioService for "System Only" and "Mic + System" modes
  - Add speakerLevel @Published property to AudioService
  - Create AudioSourcePicker Menu component with three options and icons
  - Add audio source picker to session header
  - Display both mic and speaker level indicators when "Mic + System" is selected
  - Implement setAudioSource method that restarts recording with new source (within 2 seconds)
  - Persist selected audio source in UserDefaults
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for ScreenCaptureKit and key types like `SCShareableContent`, `SCContentFilter`, `SCStreamConfiguration`, `SCStreamOutput`, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on the ScreenCaptureKit overview and those symbols, plus SwiftUI docs for `Menu` and custom controls, to inform both system audio capture and the audio source picker UI, including whether a Liquid Glass treatment on the picker or header makes the control clearer.
  - **Deliverable**: Select audio source, record system audio, see both level indicators
  - **Test**: Play music, select "System Only", verify speaker level moves; switch to "Mic + System" during recording, verify smooth transition
  - _Requirements: 1.1, 1.2, 1.4, 1.6, 12.2_

- [ ] 7. Folders and organization
  - Add Folder entity to Core Data with fields: id, name, color, parentFolderId
  - Define relationships: Folder → Session (one-to-many), Folder → Folder (parent-child)
  - Add folderId field to Session entity
  - Create FolderService with methods: createFolder, updateFolder, deleteFolder, moveSession
  - Update SidebarView to show folder hierarchy with disclosure groups
  - Add "New Folder" button to sidebar
  - Implement drag-and-drop to move sessions between folders
  - Add breadcrumb navigation to session header showing folder path
  - Make breadcrumb items clickable to navigate to folder view
  - Update session list grouping to respect folder filtering
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for Core Data relationship modeling and hierarchical entities, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those results and SwiftUI navigation/list docs (for example, `NavigationSplitView`, `List`) to derive patterns for folder trees, sidebar hierarchies, breadcrumb UI, and tasteful Liquid Glass usage in the sidebar or breadcrumb bar.
  - **Deliverable**: Create folders, organize sessions, navigate folder hierarchy
  - **Test**: Create nested folders (Work > Meetings > Q1), drag session into Q1, verify breadcrumb shows full path
  - _Requirements: 4.3_

- [ ] 8. Search and filtering
  - Add search bar to top of SidebarView
  - Create @Published searchQuery property in SidebarViewModel
  - Implement NSPredicate-based filtering on session title and memos content
  - Update NSFetchedResultsController to apply search predicate
  - Add Tag entity to Core Data with many-to-many relationship to Session
  - Create tag picker UI in session metadata panel
  - Implement addTag and removeTag methods
  - Add tag filter chips to sidebar (show/hide sessions by tag)
  - Display search results count
  - Highlight search terms in results
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for `NSPredicate`, `NSFetchedResultsController`, any Core Data search/filtering guides, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those and on SwiftUI search field patterns (for example `searchable`) to design the search bar, tag filters, and any Liquid Glass search chips or search bars.
  - **Deliverable**: Search sessions by text, filter by tags
  - **Test**: Create sessions with "standup" in title, search "standup", verify only matching sessions appear; add "urgent" tag, filter by tag
  - _Requirements: 4.4, 4.5_

- [ ] 9. Export to Markdown and PDF
  - Create ExportService with methods: exportToMarkdown, exportToPDF, copyToClipboard
  - Implement exportToMarkdown that formats session title, memos, transcript, and summary
  - Implement exportToPDF using PDFKit to render formatted document
  - Add overflow menu (three dots) to session header
  - Add menu items: "Export as Markdown", "Export as PDF", "Copy to Clipboard"
  - Show NSSavePanel for file exports with default filename (session title + date)
  - Implement copyToClipboard that copies markdown content to NSPasteboard
  - Show success notification after export completes
  - Show error alert if export fails
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for `PDFKit`, `NSSavePanel`, `NSPasteboard`, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on the relevant classes and SwiftUI/AppKit integration docs (e.g. presenting panels from SwiftUI) to confirm correct export flows, clipboard handling on macOS, and if a Liquid Glass style makes sense on export buttons or menus.
  - **Deliverable**: Export session to Markdown/PDF file or copy to clipboard
  - **Test**: Export to PDF, open in Preview, verify formatting; copy to clipboard, paste in Notes, verify content matches
  - _Requirements: 9.1, 9.2, 9.4, 9.5_

- [ ] 10. Apple Calendar integration with EventKit
  - Add Info.plist key: NSCalendarsUsageDescription with clear usage description
  - Add CalendarEvent entity to Core Data (id, externalId, title, startedAt, endedAt, location, meetingLink)
  - Define relationship: Session → CalendarEvent (optional one-to-one)
  - Create CalendarService class with method: syncEvents(from, to)
  - Request calendar access authorization (requestFullAccessToEvents for macOS 14+, requestAccess for earlier)
  - Fetch calendars using EKEventStore.calendars(for: .event)
  - Fetch events using predicateForEvents with date range (last 30 days to next 30 days)
  - Create CalendarEvent entities in Core Data for each EKEvent
  - Display calendar events in sidebar timeline mixed with sessions
  - Add "Link to Event" button in session metadata panel
  - Show event picker sheet with list of upcoming events
  - Create relationship between Session and CalendarEvent when linked
  - Display event metadata (title, time, participants) in session header when linked
  - Sync events every 15 minutes using Timer.publish
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for EventKit and `EKEventStore` plus \"Accessing the event store\"/`requestFullAccessToEvents`, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those topics and SwiftUI list/picker docs to design the mixed timeline UI, event picker sheets, and potential Liquid Glass treatments for highlighted current events.
  - **Deliverable**: See calendar events in timeline, link sessions to events
  - **Test**: Create calendar event for today, verify it appears in sidebar; link session to event, verify event metadata displays in header
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 12.4_

- [ ] 11. Settings panel with provider configuration
  - Create SettingsView as a separate window with tab navigation
  - Implement tabs: General, AI, Calendar
  - Create General tab with toggles: Launch at login, Auto-detect meetings, Save recordings locally
  - Add default audio source picker to General tab
  - Display permission status for microphone, screen recording, speech recognition, calendar
  - Add "Request Permission" buttons that open System Settings if denied
  - Create AI tab with transcription provider picker (Apple Speech, Deepgram, Groq)
  - Add API key input fields for cloud providers with secure text entry
  - Store API keys in Keychain using KeychainService
  - Add LLM provider picker (OpenAI, Anthropic, OpenRouter, Ollama)
  - Add "Test Connection" buttons that validate API keys and show status
  - Create Calendar tab showing connected calendar providers
  - Add "Connect Google Calendar" and "Connect Outlook" buttons (OAuth flows)
  - Show list of synced calendars with enable/disable toggles
  - Open settings window from menu bar: MeetRec → Settings (Cmd+,)
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for SwiftUI/macOS settings patterns (e.g. SwiftUI settings windows, forms, toggles), Keychain Services, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those results to guide the Settings window UI, secure credential storage, high-level integration patterns (OAuth specifics come from providers), and where Liquid Glass might make settings cards or headers clearer. For non-Apple providers referenced in this task (Deepgram, Groq, OpenAI, Anthropic, OpenRouter, Ollama, Google Calendar, Outlook/Microsoft Graph), also use the Context7 MCP: call `resolve-library-id` with the provider name to locate its API docs, then `get-library-docs` with topics like `authentication`, `OAuth`, or `API keys` to shape configuration fields and connection tests around the real services.
  - **Deliverable**: Configure transcription/AI providers, manage calendar connections
  - **Test**: Toggle settings, quit app, relaunch - verify settings persisted correctly
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7_
  - **Note**: Launch at login and auto-detect meetings toggles are UI-only; implementation in tasks 22-23

- [ ] 12. Cloud transcription with Deepgram
  - Create DeepgramTranscriber class with WebSocket connection
  - Establish connection to wss://api.deepgram.com/v1/listen with Authorization header
  - Configure query parameters: model=nova-2, language=en, smart_format=true, diarize=true
  - Send audio data chunks from AudioService via WebSocket
  - Receive and parse JSON responses with word-level timestamps
  - Extract words, timestamps, confidence scores, and speaker labels
  - Publish TranscribedWord objects to wordPublisher (within 2 seconds)
  - Handle WebSocket errors and implement reconnection logic (3 attempts, exponential backoff)
  - Add provider switching logic to TranscriptionService
  - Update Settings AI tab to allow selecting between Apple Speech and Deepgram
  - Store selected provider in UserDefaults
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for `URLSessionWebSocketTask` and related networking topics, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on the best matches and SwiftUI patterns for showing asynchronous state (e.g. status indicators) to follow Apple’s WebSocket usage, integrate status into the Settings UI, and decide if a Liquid Glass status pill or card is appropriate. For Deepgram-specific WebSocket and transcription parameters, also use the Context7 MCP: call `resolve-library-id` with a query like `deepgram api` and then `get-library-docs` with topics such as `streaming` or `listen websocket` to confirm query parameters, authentication, and response formats.
  - **Deliverable**: Switch to Deepgram for faster, more accurate transcription with speaker labels
  - **Test**: Record conversation with 2 people, verify speaker labels appear (Speaker 0, Speaker 1); test reconnection by disconnecting WiFi mid-recording
  - _Requirements: 3.1, 3.3, 3.4, 3.5_

- [ ] 13. Audio file recording and playback
  - Add AudioFile entity to Core Data (id, sessionId, filePath, durationMs, fileSize)
  - Define relationship: Session → AudioFile (optional one-to-one)
  - Add "Save recordings locally" toggle to Settings General tab
  - When enabled, create AVAudioFile during recording and write audio buffers to file
  - Store file path in AudioFile entity, calculate duration and size when recording stops
  - Create AudioPlayerService with AVAudioPlayer for playback
  - Implement play, pause, seek methods
  - Add AudioTimelineView below transcript with play/pause button and scrubber
  - Display current time and total duration
  - Sync playback position with transcript: clicking a word seeks to its timestamp
  - Support keyboard shortcuts: Space (play/pause), ← → (seek ±5 seconds)
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for `AVAudioFile` and `AVAudioPlayer`, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those and on SwiftUI/AVFoundation integration docs (e.g. observing playback in SwiftUI) to implement file-based recording/playback, the timeline UI, and potential Liquid Glass styling for the transport controls.
  - **Deliverable**: Record audio to file, play back with timeline scrubber
  - **Test**: Record 30 seconds, click word at 15s mark, verify playback seeks to that position; press Space to pause/play
  - _Requirements: 1.7, 14.1, 14.2, 14.3, 14.4, 14.5_

- [ ] 14. Templates for structured summaries
  - Add Template entity to Core Data (id, title, description, category, sections as JSON, targets as JSON)
  - Create built-in templates: "1:1 Meeting", "Team Standup", "Sales Call", "Retrospective"
  - Each template has sections (e.g., "Key Points", "Action Items", "Decisions") and targets (memos, transcript, or both)
  - Add template picker to summary generation UI
  - When template is selected, modify AI prompt to include section structure
  - Format AI response to match template sections
  - Create Templates tab in Settings to view and manage templates
  - Add "Create Template" button to create custom templates
  - Implement template editor with section name/prompt inputs
  - Store custom templates in Core Data
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for Core Data modeling topics, SwiftUI forms/lists, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those to see examples of editing structured, persistent configuration data (templates) in SwiftUI and how Liquid Glass might enhance template rows or cards.
  - **Deliverable**: Generate summaries with structured sections using templates
  - **Test**: Select "1:1 Meeting" template, generate summary, verify sections appear (Key Points, Action Items, etc.)
  - _Requirements: 6.5, 13.1, 13.2, 13.3, 13.4, 13.5_

- [ ] 15. Onboarding flow for first launch
  - Check UserDefaults for "hasCompletedOnboarding" flag on app launch
  - If false, show OnboardingView as modal sheet
  - Create welcome screen with app description and "Get Started" button
  - Create permissions screen showing microphone, screen recording, speech recognition status
  - Add "Request Permission" buttons that trigger authorization requests
  - Show permission status: granted (green checkmark), denied (red X), not determined (gray)
  - Provide "Open System Settings" button for denied permissions
  - Create optional calendar connection screen with "Connect" and "Skip" buttons
  - Create completion screen with "Start Session" button
  - Set "hasCompletedOnboarding" flag when user completes flow
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for macOS app onboarding patterns (SwiftUI sheets/windows, `Alert`), TCC/permission articles (for example \"Requesting Authorization for Media Capture on macOS\"), and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` to confirm recommended permission UI flows, how to present them in SwiftUI, and where Liquid Glass backgrounds on welcome or permission cards are appropriate.
  - **Deliverable**: First-time users see guided setup for permissions and calendar
  - **Test**: Delete UserDefaults, relaunch app, verify onboarding appears; complete flow, relaunch, verify onboarding doesn't appear again
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

- [ ] 16. Tab system for multiple sessions
  - Create @MainActor AppState view model with openTabs array and selectedTabId
  - Define Tab enum with cases: session(Session), event(CalendarEvent), folder(Folder), empty
  - Create TabBarView above main content area showing tab titles with close buttons
  - Implement openSession method that checks if tab exists, otherwise creates new tab
  - Implement closeTab method that removes tab from array
  - Implement selectTab method that updates selectedTabId
  - Add keyboard shortcuts: Cmd+W (close tab), Cmd+T (new empty tab), Cmd+1-9 (switch to tab)
  - Show recording indicator (red dot) on tabs with active recording
  - Support drag-to-reorder tabs
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for SwiftUI navigation/tab patterns (e.g., `NavigationSplitView`, `TabView`) and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those to inform your tab system and any Liquid Glass styling for the tab bar or active tab highlight, using AppKit tabbed windows docs only if you need deeper integration.
  - **Deliverable**: Open multiple sessions in tabs, switch between them
  - **Test**: Open 5 sessions, press Cmd+2 to switch to second tab, press Cmd+W to close it, verify correct tab closes
  - _Requirements: 10.2, 10.3, 10.4_

- [ ] 17. Voice activity detection (VAD) for efficient processing
  - Integrate Silero-RS VAD library (use vDSP for energy calculation as implementation detail)
  - Analyze audio buffers in real-time to detect voice activity
  - Calculate energy threshold using vDSP (RMS > -40dB indicates speech)
  - Emit voice activity events via Combine publisher
  - Forward audio to transcription service only when voice is detected (within 500ms)
  - Pause transcription processing after 3 seconds of silence
  - Add visual indicator in UI showing voice activity status (green dot when active)
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for `AVAudioPCMBuffer`, Accelerate/vDSP signal-processing articles, Combine (`PassthroughSubject`, `Publisher`), and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those and on SwiftUI view docs for simple indicators (e.g. a colored circle) to guide both the VAD implementation and its UI, including whether a Liquid Glass capsule around the activity dot makes sense. For the Silero-RS VAD library itself, also use the Context7 MCP: call `resolve-library-id` with a query like `silero-rs` (or the concrete crate/package name you adopt) and then `get-library-docs` with a topic such as `voice activity detection` to confirm initialization, threading, and recommended thresholds from the library’s own documentation.
  - **Deliverable**: Transcription only processes when speech is detected, saving CPU/battery
  - **Test**: Record with 5-second pauses between sentences, verify transcription pauses during silence
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 18. Crash recovery for in-progress sessions
  - Add "status" field to Session entity with values: draft, recording, completed
  - Set status to "recording" when startRecording is called
  - Set status to "completed" when stopRecording is called
  - On app launch, query Core Data for sessions with status = "recording"
  - Show alert: "You have unfinished sessions. Would you like to resume or finalize them?"
  - Provide "Resume" button that reopens session and continues recording
  - Provide "Finalize" button that sets status to "completed" without resuming
  - Persist session state incrementally during recording (auto-save every 10 seconds)
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for Core Data background saving and stack articles, SwiftUI alert patterns, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those to confirm recommended crash-safe save patterns, how to present recovery prompts, and whether a Liquid Glass-styled recovery banner or sheet is appropriate.
  - **Deliverable**: Recover in-progress sessions after unexpected app termination
  - **Test**: Start recording, force quit app (Activity Monitor), relaunch, verify recovery alert appears with Resume/Finalize options
  - _Requirements: 8.4_

- [ ] 19. Transcript editing and speaker assignment
  - Add edit mode toggle to TranscriptView
  - When enabled, make word text editable inline
  - Implement updateWord method in TranscriptionService that updates Core Data
  - Add speaker assignment UI: right-click word → "Assign Speaker" → text input
  - Store speaker identifier in Word.speaker field
  - Display speaker labels in transcript (e.g., "Speaker 1:", "John:")
  - Add merge/split functionality: select multiple words → "Merge" or "Split at cursor"
  - Publish edit events for UI updates
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for text editing in SwiftUI and AppKit (e.g., `TextEditor`, `NSTextView`), Core Data update docs, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` to inform how you implement inline editing, context menus, persistent updates for the transcript, and any Liquid Glass accents on the editing toolbar or selection chrome.
  - **Deliverable**: Correct transcription mistakes, assign speakers to words
  - **Test**: Enable edit mode, change "hello" to "Hello", verify change persists; right-click word, assign speaker "John", verify label appears
  - _Requirements: 3.6_

- [ ] 20. Obsidian vault export
  - Add "Export to Obsidian" option to export menu
  - Use NSOpenPanel to let user select Obsidian vault directory
  - Store vault path in UserDefaults for future exports
  - Format session as markdown with YAML frontmatter (title, date, tags, participants)
  - Write file to vault: `{vault_path}/{session_title}_{date}.md`
  - Support bi-directional links: `[[Session Title]]` format
  - Show success notification with "Open in Obsidian" button
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for `NSOpenPanel`, sandboxed file access (security-scoped bookmarks), and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those and SwiftUI/AppKit integration docs for presenting panels to implement safe Obsidian vault access from the SwiftUI export UI and consider Liquid Glass styling for export confirmation banners. For Obsidian-specific behavior such as vault structure, YAML frontmatter, and wiki-link formats, also use the Context7 MCP: call `resolve-library-id` with a query like `obsidian docs` and then `get-library-docs` with topics like `YAML front matter` or `vault structure` so exported files integrate cleanly with Obsidian.
  - **Deliverable**: Export sessions directly to Obsidian vault
  - **Test**: Select vault, export session, open Obsidian, verify file appears with correct frontmatter and content
  - _Requirements: 9.3_

- [ ] 21. Polish: keyboard shortcuts, icons, and build configuration
  - Add global keyboard shortcuts: Cmd+N (new session), Cmd+K (search), Cmd+, (settings)
  - Create app icon in Assets.xcassets (1024x1024 PNG)
  - Add SF Symbols for UI elements (mic, speaker, play, pause, etc.)
  - Configure accent color in Assets.xcassets
  - Set up development certificate and provisioning profile
  - Enable Hardened Runtime in build settings
  - Configure code signing for distribution
  - Set minimum macOS version to 12.0 in project settings
  - Test app on clean macOS installation
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for SwiftUI/AppKit keyboard shortcut APIs, asset catalogs (`.xcassets`), Hardened Runtime, notarization docs, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those to verify the correct UI wiring, configuration steps, and whether global accents like a Liquid Glass search field or primary buttons fit the overall design.
  - **Deliverable**: Polished app ready for distribution
  - **Test**: Press each keyboard shortcut to verify it works; test on macOS 12.0 VM if possible
  - _Requirements: 10.4, 10.5, 12.1, 12.2_

- [ ] 22. Launch at login implementation
  - Use SMAppService.mainApp for macOS 13.0+ to register/unregister login item
  - For macOS 12.0, use legacy SMLoginItemSetEnabled API
  - Implement setLaunchAtLogin(_ enabled: Bool) method in AppDelegate or main app
  - Call method when user toggles "Launch at login" in Settings General tab
  - Handle registration errors gracefully (show alert if registration fails)
  - Verify login item status on app launch and sync with Settings toggle
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for the ServiceManagement framework (`SMAppService`, `SMLoginItemSetEnabled`) and login items docs, then call `get_apple_doc_content` on those pages to follow the current login-item best practices and surface any relevant UI guidance for login item status.
  - **Deliverable**: App launches automatically on login when enabled
  - **Test**: Enable toggle, log out, log back in - verify app launches automatically
  - _Requirements: 11.1_

- [ ] 23. Auto-detect meetings implementation
  - Create MeetingDetectionService that monitors active applications and calendar
  - Use NSWorkspace.shared.frontmostApplication to get active app
  - Check if active app is in meeting apps list (Zoom, Teams, Meet, etc.)
  - Cross-reference with calendar events: if meeting app is active AND calendar event is happening now, suggest recording
  - Show notification: "Meeting detected. Start recording?" with "Start" and "Dismiss" buttons
  - Respect Do Not Disturb / Focus mode using the appropriate macOS API (consult Focus and notification docs to choose the right approach)
  - Add "Ignored Apps" list in Settings to exclude specific apps from detection
  - Store detection preferences in UserDefaults
  - **AI docs lookup**: Before using any MCPs, first open and skim the existing related Swift files in this project (views, view models, services, Core Data models) so you understand current types, flows, and naming. After you have that local context, use the Apple Developer Documentation MCP to call `search_apple_docs` for `NSWorkspace.frontmostApplication`, Focus-related docs (for example \"Focus\" in AppIntents), EventKit calendar APIs, and Liquid Glass docs (for example \"Adopting Liquid Glass\", `glassEffect(_:in:)`, `Glass`), then call `get_apple_doc_content` on those results and SwiftUI notification/banner patterns to design a meeting-detection heuristic that respects Focus/DND settings, presents suggestions in the UI, and optionally uses Liquid Glass styling for the suggestion banner.
  - **Deliverable**: App suggests starting recording when meeting is detected
  - **Test**: Open Zoom during calendar event time, verify notification appears; enable DND, verify no notification
  - _Requirements: 5.1, 5.2, 5.3, 5.4_
