# Project Structure & Architecture

## Folder Organization

### `/MeetRec` - Main Application Target
Primary source code for the macOS app.

- **App/**: Application lifecycle and entry point
  - `MeetRecApp.swift`: SwiftUI app entry with Core Data setup
  - `AppState.swift`: Global app state (@Observable)

- **Views/**: SwiftUI view components
  - `ContentView.swift`: Root view with HSplitView layout
  - `SidebarView.swift`: Left sidebar with session list
  - `SessionView.swift`: Main session editor view
  - Organized by feature (Session/, Settings/, Onboarding/)

- **ViewModels/**: Observable view models
  - `SessionViewModel.swift`: Session-specific logic and audio control
  - All view models marked with `@MainActor` and `@Observable`

- **Audio/**: Audio recording and processing
  - `AudioService.swift`: AVAudioEngine-based recording service
  - `AudioSource.swift`: Audio source enum (mic, system, both)

- **Persistence/**: Core Data stack
  - `Persistence.swift`: PersistenceController with shared and preview instances
  - `MeetRec.xcdatamodeld/`: Core Data model definition

- **Extensions/**: Swift extensions for common types
  - `ViewExtensions.swift`: Custom view modifiers

- **Resources/**: Assets and configuration
  - `Assets.xcassets/`: App icons and images
  - `Info.plist`: App permissions and metadata
  - `MeetRec.entitlements`: App capabilities

### `/MeetRecTests` - Unit Tests
Unit tests for business logic and services.

### `/MeetRecUITests` - UI Tests
Automated UI tests for user flows.

### `/MeetRec.xcodeproj` - Xcode Project
Build configuration and project settings.

### `/docs` - Development Documentation
Task-specific development documentation and debugging guides.

- Document each task's development process, decisions, and debugging steps
- Use descriptive filenames: `[FEATURE]_[DESCRIPTION].md` (e.g., `DEBUG_RECORDING.md`)
- Include implementation notes, issues encountered, and solutions
- Keep technical context for future reference and troubleshooting

## Architecture Patterns

### MVVM (Model-View-ViewModel)
- **Models**: Core Data entities (Session, Transcript, etc.)
- **Views**: SwiftUI views (declarative UI)
- **ViewModels**: @Observable classes with business logic

### State Management
- **@Observable**: Modern Swift observation for view models
- **@State**: Local view state
- **@Environment**: Dependency injection (Core Data context, AppState)
- **@FetchRequest**: Reactive Core Data queries in views

### Service Layer
Services are @Observable or actor-based classes:
- `AudioService`: Audio recording and level monitoring
- `TranscriptionService`: (future) Transcription processing
- `AIService`: (future) LLM integration
- `CalendarService`: (future) Calendar sync

### Data Flow
```
User Action → View → ViewModel → Service → Core Data
                ↑                              ↓
                └──────── @FetchRequest ───────┘
```

## Naming Conventions

### Files
- Views: `[Feature]View.swift` (e.g., `SessionView.swift`)
- ViewModels: `[Feature]ViewModel.swift`
- Services: `[Feature]Service.swift`
- Extensions: `[Type]+Extensions.swift`

### Code Style
- **Classes/Structs**: PascalCase (`AudioService`, `SessionViewModel`)
- **Properties/Methods**: camelCase (`isRecording`, `startRecording()`)
- **Constants**: camelCase (`maxRecordingDuration`)
- **Enums**: PascalCase with lowercase cases (`AudioSource.micOnly`)

### SwiftUI Conventions
- Use `@MainActor` for view models that update UI
- Use `@Observable` for modern state management (Swift 5.9+)
- Use `@Bindable` for two-way bindings with @Observable objects
- Prefer `@FetchRequest` for Core Data queries in views
- Use `.environment()` for dependency injection

## Core Data Schema

Current entities:
- **Session**: Recording sessions with title, timestamps, and markdown content
  - `id`: UUID (primary key)
  - `title`: String (optional)
  - `createdAt`: Date
  - `startedAt`: Date (optional, when recording started)
  - `endedAt`: Date (optional, when recording ended)
  - `rawMarkdown`: String (optional, user's raw notes)

Future entities (see ABOUT.md for complete schema):
- Transcript, Word, Event, Calendar, Folder, Tag, Human, Organization

## Key Design Decisions

1. **Local-First**: All data stored in Core Data, cloud sync optional
2. **Privacy**: No telemetry by default, explicit user consent required
3. **Native**: Use native frameworks (AVFoundation, EventKit) over third-party
4. **Modern Swift**: Leverage Swift 5.9+ features (@Observable, async/await)
5. **Reactive UI**: Use @FetchRequest and Combine for automatic UI updates
