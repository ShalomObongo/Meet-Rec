# Design Document

## Overview

MeetRec is a native macOS application built with SwiftUI and AppKit that provides privacy-first meeting recording, transcription, and AI-powered summarization. The design follows a local-first architecture where all data processing occurs on-device by default, with optional cloud provider integration for enhanced capabilities.

### Design Principles

1. **Privacy First**: All data stays local unless user explicitly configures cloud providers
2. **Offline Capable**: Core functionality works without internet connection
3. **Native Experience**: Leverage macOS frameworks for optimal performance and integration
4. **Modular Architecture**: Clean separation between UI, business logic, and data layers
5. **Reactive Data Flow**: Use Combine and SwiftUI's state management for responsive UI

### Technology Stack

- **UI Framework**: SwiftUI (primary) with AppKit for complex controls
- **State Management**: @Observable macro (macOS 14+) or ObservableObject (macOS 11-13)
  - **Concurrency**: All view models are marked @MainActor to ensure UI updates occur on the main thread
  - Use Swift 6 strict concurrency checking to avoid data races
- **Persistence**: Core Data with SQLite backend
- **Audio**: AVFoundation, Core Audio, ScreenCaptureKit (macOS 12.3+)
- **Speech**: Speech Framework with on-device recognition
- **Concurrency**: Swift async/await and Actor pattern for services
- **Networking**: URLSession with Combine publishers

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    SwiftUI Views                        │
│  ┌──────────────┬──────────────┬──────────────────┐    │
│  │  Sidebar     │  Tab System  │  Session Editor  │    │
│  │  Timeline    │  Navigation  │  Audio Controls  │    │
│  └──────────────┴──────────────┴──────────────────┘    │
└────────────────────┬────────────────────────────────────┘
                     │ Bindings / Combine
┌────────────────────▼────────────────────────────────────┐
│                  View Models                            │
│  ┌──────────────┬──────────────┬──────────────────┐    │
│  │  AppState    │  SessionVM   │  TranscriptVM    │    │
│  │  SidebarVM   │  AudioVM     │  SettingsVM      │    │
│  └──────────────┴──────────────┴──────────────────┘    │
└────────────────────┬────────────────────────────────────┘
                     │ Service Calls
┌────────────────────▼────────────────────────────────────┐
│                   Services Layer                        │
│  ┌──────────────┬──────────────┬──────────────────┐    │
│  │  AudioSvc    │  TranscriptSvc│  AISvc          │    │
│  │  CalendarSvc │  ExportSvc   │  TemplateSvc    │    │
│  └──────────────┴──────────────┴──────────────────┘    │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│            Persistence & External APIs                  │
│  ┌──────────────┬──────────────┬──────────────────┐    │
│  │  Core Data   │  Keychain    │  EventKit        │    │
│  │  Cloud APIs  │  File System │  UserDefaults    │    │
│  └──────────────┴──────────────┴──────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### Audio Processing Pipeline

```
┌────────────────────────────────────────────────────────┐
│                   AVAudioEngine                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Input Node (Microphone)                         │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 │                                      │
│  ┌──────────────▼───────────────────────────────────┐  │
│  │  Mixer Node                                      │◄─┼─ System Audio
│  │  (Combines mic + system audio)                   │  │  (ScreenCaptureKit)
│  └──────────────┬───────────────────────────────────┘  │
│                 │                                      │
│  ┌──────────────▼───────────────────────────────────┐  │
│  │  Effect Chain                                    │  │
│  │  - Echo Cancellation (vDSP)                      │  │
│  │  - Automatic Gain Control                        │  │
│  │  - Noise Gate                                    │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 │                                      │
│  ┌──────────────▼───────────────────────────────────┐  │
│  │  VAD Node (Voice Activity Detection)            │  │
│  │  (Silero-RS based)                               │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 │                                      │
│  ┌──────────────▼───────────────────────────────────┐  │
│  │  Tap Node (Capture for transcription)           │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 │                                      │
│  ┌──────────────▼───────────────────────────────────┐  │
│  │  Output Node (Optional playback monitoring)      │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
                 │
                 ▼
     ┌───────────────────────┐
     │ Transcription Service │
     │ - Speech Framework    │
     │ - Deepgram WebSocket  │
     │ - Groq API            │
     └───────────────────────┘
```

## Components and Interfaces

### 1. Audio Service

**Responsibilities:**
- Manage audio capture from microphone and system audio
- Apply audio enhancements (AEC, AGC, noise suppression)
- Perform voice activity detection
- Provide real-time audio level monitoring
- Support dynamic audio source switching

**Interface:**
```swift
protocol AudioServiceProtocol {
    var isRecording: Bool { get }
    var micLevel: Float { get }
    var speakerLevel: Float { get }
    var audioSource: AudioSource { get set }
    
    func startRecording(source: AudioSource) async throws
    func stopRecording()
    func setAudioSource(_ source: AudioSource) async throws
    
    var audioDataPublisher: AnyPublisher<AudioData, Never> { get }
    var levelPublisher: AnyPublisher<(mic: Float, speaker: Float), Never> { get }
}

enum AudioSource: String, Codable {
    case micAndSystem = "Mic + System"
    case micOnly = "Mic Only"
    case systemOnly = "System Only"
}

struct AudioData {
    let buffer: AVAudioPCMBuffer
    let channel: AudioChannel
    let timestamp: TimeInterval
}

enum AudioChannel {
    case microphone
    case system
}
```

**Implementation Notes:**
- Use AVAudioEngine for microphone capture
- Use ScreenCaptureKit for system audio (macOS 12.3+)
- Process audio on background queue with QoS .userInitiated
- Use vDSP from Accelerate framework for DSP operations
- Buffer size: 4096 frames for low latency
- **Performance Target**: Forward audio to transcription within 500ms of voice detection

### 2. Transcription Service

**Responsibilities:**
- Coordinate transcription across multiple providers
- Handle both streaming and batch transcription
- Manage word-level timestamps and speaker diarization
- Support local and cloud transcription models

**Interface:**
```swift
protocol TranscriptionServiceProtocol {
    var provider: TranscriptionProvider { get set }
    var isTranscribing: Bool { get }
    
    func startTranscription(config: TranscriptionConfig) async throws
    func stopTranscription()
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer, channel: AudioChannel) async
    
    var wordPublisher: AnyPublisher<TranscribedWord, Never> { get }
}

enum TranscriptionProvider {
    case appleSpeech
    case deepgram(apiKey: String, model: String)
    case groq(apiKey: String)
    case whisperLocal(model: WhisperModel)
}

struct TranscriptionConfig {
    let language: String
    let enableDiarization: Bool
    let customVocabulary: [String]
}

struct TranscribedWord {
    let id: UUID
    let text: String
    let startMs: Int64
    let endMs: Int64
    let channel: AudioChannel
    let speaker: String?
    let confidence: Double
}
```

**Implementation Notes:**
- Use Speech Framework for local transcription with `requiresOnDeviceRecognition = true`
- Use URLSession WebSocket for Deepgram streaming
- Implement actor pattern for thread-safe word queue
- Batch save words to Core Data every 100 words
- Handle reconnection logic for cloud providers
- **Performance Target**: Display transcribed words in UI within 2 seconds of speech completion

### 3. AI Service

**Responsibilities:**
- Generate summaries from memos and transcripts
- Support multiple LLM providers
- Handle streaming responses
- Apply templates to structure output

**Interface:**
```swift
protocol AIServiceProtocol {
    var provider: LLMProvider { get set }
    var isGenerating: Bool { get }
    
    func generateSummary(
        memos: String,
        transcript: String?,
        template: Template?,
        autonomy: AutonomyLevel
    ) async throws -> AsyncThrowingStream<String, Error>
    
    func generateTitle(content: String) async throws -> String
    func chat(messages: [ChatMessage]) async throws -> AsyncThrowingStream<String, Error>
}

enum LLMProvider {
    case openAI(apiKey: String, model: String)
    case anthropic(apiKey: String, model: String)
    case openRouter(apiKey: String, model: String)
    case ollama(baseURL: String, model: String)
}

enum AutonomyLevel {
    case grounded  // Use only memos
    case creative  // Use memos + full transcript
}

struct Template {
    let id: UUID
    let title: String
    let sections: [TemplateSection]
    let targets: [ContentTarget]
}

struct TemplateSection {
    let name: String
    let prompt: String
}

enum ContentTarget {
    case memos
    case transcript
}
```

**Implementation Notes:**
- Use URLSession for HTTP streaming
- Parse Server-Sent Events (SSE) for OpenAI/Anthropic
- Implement retry logic with exponential backoff
- Cache API responses for regeneration
- Use @MainActor for UI updates during streaming

### 4. Calendar Service

**Responsibilities:**
- Integrate with Apple Calendar, Google Calendar, and Outlook
- Sync events incrementally
- Link sessions to calendar events
- Extract meeting metadata

**Interface:**
```swift
protocol CalendarServiceProtocol {
    var connectedProviders: [CalendarProvider] { get }
    
    func connectProvider(_ provider: CalendarProvider) async throws
    func disconnectProvider(_ provider: CalendarProvider) async throws
    func syncEvents(from: Date, to: Date) async throws
    func linkSession(_ sessionId: UUID, to eventId: String) async throws
    
    var eventsPublisher: AnyPublisher<[CalendarEvent], Never> { get }
}

enum CalendarProvider {
    case apple
    case google(credentials: OAuthCredentials)
    case outlook(credentials: OAuthCredentials)
}

struct CalendarEvent {
    let id: String
    let externalId: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let meetingLink: String?
    let participants: [String]
    let calendarId: String
}
```

**Implementation Notes:**
- Use EventKit for Apple Calendar (no OAuth needed)
- Implement OAuth 2.0 flow for Google and Microsoft
- Store sync tokens for incremental updates
- Poll every 15 minutes for changes
- Store credentials in Keychain

### 5. Persistence Controller

**Responsibilities:**
- Manage Core Data stack
- Provide contexts for UI and background operations
- Handle migrations
- Implement efficient fetching strategies

**Interface:**
```swift
protocol PersistenceControllerProtocol {
    var viewContext: NSManagedObjectContext { get }
    
    func newBackgroundContext() -> NSManagedObjectContext
    func save(context: NSManagedObjectContext) async throws
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T
}
```

**Implementation Notes:**
- Use NSPersistentContainer with SQLite store
- Enable automatic lightweight migration
- Use NSFetchedResultsController for reactive UI updates
- Implement batch operations for large datasets
- Create indexes on frequently queried fields
- **Crash Recovery**: Persist active session state incrementally (metadata + partial transcript) to enable recovery of in-progress sessions after unexpected termination. On launch, detect unfinished sessions and offer to resume or finalize them.

## Data Models

### Core Data Entities

#### Session Entity
```swift
@objc(Session)
class Session: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String?
    @NSManaged var rawMarkdown: String?      // Memos
    @NSManaged var enhancedMarkdown: String? // Summary
    @NSManaged var startedAt: Date?
    @NSManaged var endedAt: Date?
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date?
    
    // Relationships
    @NSManaged var folder: Folder?
    @NSManaged var event: CalendarEvent?
    @NSManaged var transcripts: Set<Transcript>
    @NSManaged var tags: Set<Tag>
    @NSManaged var participants: Set<Human>
    @NSManaged var audioFile: AudioFile?
}
```

#### Transcript Entity
```swift
@objc(Transcript)
class Transcript: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var startedAt: Date?
    @NSManaged var endedAt: Date?
    @NSManaged var createdAt: Date
    
    // Relationships
    @NSManaged var session: Session
    @NSManaged var words: NSOrderedSet  // Ordered for timeline
}
```

#### Word Entity
```swift
@objc(Word)
class Word: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var text: String
    @NSManaged var startMs: Int64
    @NSManaged var endMs: Int64
    @NSManaged var channel: String?  // "mic" or "system"
    @NSManaged var speaker: String?
    @NSManaged var confidence: Double
    @NSManaged var createdAt: Date
    
    // Relationships
    @NSManaged var transcript: Transcript
    
    // Computed
    var duration: Int64 {
        endMs - startMs
    }
}
```

#### Folder Entity
```swift
@objc(Folder)
class Folder: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var color: String?
    @NSManaged var createdAt: Date
    
    // Relationships
    @NSManaged var parent: Folder?
    @NSManaged var children: Set<Folder>
    @NSManaged var sessions: Set<Session>
}
```

#### CalendarEvent Entity
```swift
@objc(CalendarEvent)
class CalendarEvent: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var externalId: String
    @NSManaged var title: String
    @NSManaged var startedAt: Date
    @NSManaged var endedAt: Date
    @NSManaged var location: String?
    @NSManaged var meetingLink: String?
    @NSManaged var eventDescription: String?
    @NSManaged var note: String?
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date?
    
    // Relationships
    @NSManaged var calendar: Calendar
    @NSManaged var session: Session?
}
```

### View Models

#### AppState (Global State)
```swift
@MainActor
@Observable  // macOS 14+
class AppState {
    var openTabs: [Tab] = []
    var selectedTabId: Tab.ID?
    var sidebarCollapsed: Bool = false
    var searchQuery: String = ""
    
    func openSession(_ session: Session) { }
    func closeTab(_ tabId: Tab.ID) { }
    func selectTab(_ tabId: Tab.ID) { }
}

// For macOS 11-13, use ObservableObject:
// @MainActor
// class AppState: ObservableObject {
//     @Published var openTabs: [Tab] = []
//     @Published var selectedTabId: Tab.ID?
//     // ... etc
// }

enum Tab: Identifiable {
    case session(Session)
    case event(CalendarEvent)
    case folder(Folder)
    case empty
    
    var id: String {
        switch self {
        case .session(let s): return "session-\(s.id)"
        case .event(let e): return "event-\(e.id)"
        case .folder(let f): return "folder-\(f.id)"
        case .empty: return "empty"
        }
    }
}
```

#### SessionViewModel
```swift
@MainActor
@Observable  // macOS 14+
class SessionViewModel {
    var session: Session
    var isRecording: Bool = false
    var audioSource: AudioSource = .micAndSystem
    var micLevel: Float = 0.0
    var speakerLevel: Float = 0.0
    var selectedEditor: EditorTab = .summary
    var autonomyLevel: AutonomyLevel = .grounded
    
    private let audioService: AudioServiceProtocol
    private let transcriptionService: TranscriptionServiceProtocol
    private let aiService: AIServiceProtocol
    
    func startRecording() async throws { }
    func stopRecording() { }
    func generateSummary() async throws { }
    func saveChanges() async throws { }
}

// For macOS 11-13, use ObservableObject instead:
// @MainActor
// class SessionViewModel: ObservableObject {
//     @Published var isRecording: Bool = false
//     @Published var audioSource: AudioSource = .micAndSystem
//     // ... etc
// }

enum EditorTab {
    case summary
    case memos
    case transcript
}
```

## Error Handling

### Error Types

```swift
enum MeetRecError: LocalizedError {
    case audioPermissionDenied
    case screenRecordingPermissionDenied
    case calendarPermissionDenied
    case speechRecognitionPermissionDenied
    case systemAudioNotAvailable
    case transcriptionFailed(underlying: Error)
    case aiGenerationFailed(underlying: Error)
    case networkError(underlying: Error)
    case persistenceError(underlying: Error)
    case invalidConfiguration(message: String)
    
    var errorDescription: String? {
        switch self {
        case .audioPermissionDenied:
            return "Microphone access is required to record audio. Please grant permission in System Settings."
        case .screenRecordingPermissionDenied:
            return "Screen Recording permission is required to capture system audio. Please grant permission in System Settings."
        case .calendarPermissionDenied:
            return "Calendar access is required to sync events. Please grant permission in System Settings."
        case .speechRecognitionPermissionDenied:
            return "Speech recognition permission is required for transcription. Please grant permission in System Settings."
        case .systemAudioNotAvailable:
            return "System audio capture requires macOS 12.3 or later."
        case .transcriptionFailed(let error):
            return "Transcription failed: \(error.localizedDescription)"
        case .aiGenerationFailed(let error):
            return "AI generation failed: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .persistenceError(let error):
            return "Database error: \(error.localizedDescription)"
        case .invalidConfiguration(let message):
            return "Configuration error: \(message)"
        }
    }
}
```

### Error Handling Strategy

1. **Permission Errors**: Show alert with system settings deep link
2. **Network Errors**: Retry with exponential backoff (3 attempts)
3. **Transcription Errors**: Fall back to local model if cloud fails
4. **AI Errors**: Show error banner with retry option
5. **Persistence Errors**: Log to console, show user-friendly message

## Testing Strategy

### Unit Tests

**Audio Service Tests:**
- Test audio source switching
- Test level calculation accuracy
- Test VAD detection thresholds
- Mock AVAudioEngine for isolation

**Transcription Service Tests:**
- Test word timestamp accuracy
- Test provider switching
- Test batch processing
- Mock network responses

**AI Service Tests:**
- Test streaming response parsing
- Test template application
- Test autonomy level logic
- Mock API responses

**Persistence Tests:**
- Test CRUD operations
- Test relationship integrity
- Test migration scenarios
- Use in-memory store

### Integration Tests

- Test audio → transcription pipeline
- Test transcription → AI summary flow
- Test calendar sync end-to-end
- Test session lifecycle

### UI Tests

- Test recording start/stop flow
- Test audio source selection
- Test tab navigation
- Test search functionality
- Test export workflows

### Performance Tests

- Measure audio processing latency (<100ms)
- Measure transcription delay (<2s)
- Measure UI responsiveness with 10,000 words
- Measure memory usage during long recordings

## Security Considerations

### Data Protection

1. **API Keys**: Store in Keychain with kSecAttrAccessibleWhenUnlocked
2. **Audio Files**: Optional encryption using CryptoKit
3. **Database**: Enable Core Data encryption for sensitive fields
4. **Network**: Use TLS 1.3 for all API calls

### Sandboxing

Enable App Sandbox with entitlements:
- `com.apple.security.device.microphone` (for microphone access)
- `com.apple.security.files.user-selected.read-write` (for file exports)
- `com.apple.security.network.client` (for cloud API access)

**Note on Screen Recording**: ScreenCaptureKit-based system audio capture is governed by TCC (Transparency, Consent, and Control) via `NSScreenCaptureUsageDescription` in Info.plist, not by a sandbox entitlement. No camera entitlement is required for screen recording.

### Privacy

1. Request permissions with clear usage descriptions in Info.plist:
   - `NSMicrophoneUsageDescription`
   - `NSScreenCaptureUsageDescription`
   - `NSCalendarsUsageDescription`
   - `NSSpeechRecognitionUsageDescription`

2. Implement data export for GDPR compliance
3. Provide clear privacy policy
4. No telemetry without explicit opt-in

## Performance Optimization

### Audio Processing

- Use buffer size 4096 for optimal latency/CPU balance
- Process on background queue with QoS .userInitiated
- Use vDSP for vectorized operations (3-5x faster)
- Implement proper audio session management

### Core Data

- Use NSFetchedResultsController for automatic UI updates
- Set fetchBatchSize to 50-100 for large result sets
- Create indexes on: `sessionId`, `startMs`, `createdAt`
- Use background contexts for heavy operations
- Batch save every 100 words

### Memory Management

- Use @autoreleasepool for batch processing
- Implement proper deinit to stop services
- Use weak references in closures
- Monitor memory with Instruments

### UI Responsiveness

- Keep main thread free from heavy operations
- Use Task.detached for CPU-intensive work
- Implement progressive loading for large transcripts
- Use LazyVStack for long lists

## Deployment Considerations

### Minimum Requirements

- macOS 12.0 (Monterey) or later
- Apple Silicon or Intel processor
- 4GB RAM minimum, 8GB recommended
- 500MB disk space

### Distribution

1. **Code Signing**: Use Apple Developer certificate
2. **Notarization**: Submit to Apple for Gatekeeper approval
3. **Installer**: Create DMG with drag-to-Applications
4. **Updates**: 
   - For direct download (DMG): Implement Sparkle framework for auto-updates
   - For Mac App Store: Updates handled by App Store (do not include Sparkle)

### Build Configuration

- **Debug**: Enable logging, disable optimizations
- **Release**: Enable optimizations, strip symbols
- **Beta**: Enable crash reporting, limited logging

## Future Enhancements

1. **iCloud Sync**: Use CloudKit for cross-device sync
2. **Shortcuts Integration**: Support macOS Shortcuts
3. **Widgets**: Show recent sessions in Notification Center
4. **Share Extension**: Quick share from other apps
5. **Siri Integration**: Voice commands for recording
6. **Multi-language UI**: Localization support
