# Technical Stack

## Platform

- **Target**: macOS native application
- **Minimum Version**: macOS 11.0+ (Big Sur) **Not important, we'll raise this minimum to a higher level as we develop**
- **Language**: Swift 5.9+
- **Build System**: Xcode project (.xcodeproj)

## Frameworks & Technologies

### UI Layer
- **SwiftUI**: Primary UI framework (declarative, modern)
- **AppKit**: Legacy support and complex controls when needed
- **Combine**: Reactive data flow and async operations

### State Management
- **@Observable macro**: Modern state management (macOS 14+, Swift 5.9+)
- **@MainActor**: Thread-safe UI updates and view models
- **Core Data**: Persistent storage with NSFetchedResultsController for reactive UI

### Audio & Media
- **AVFoundation**: Audio capture, playback, and processing
- **Core Audio**: Low-level audio processing
- **ScreenCaptureKit**: System audio capture (macOS 12.3+)
- **Accelerate (vDSP)**: DSP and signal processing for audio effects

### Data Persistence
- **Core Data**: Primary ORM for sessions, transcripts, and metadata
- **SQLite**: Underlying database engine
- **CloudKit**: Optional iCloud sync (NSPersistentCloudKitContainer)

### System Integration
- **EventKit**: Native calendar access (Apple Calendar)
- **UNUserNotificationCenter**: User notifications
- **Accessibility API**: Meeting detection heuristics

## Project Structure

```
MeetRec/
├── App/                    # App entry point (MeetRecApp.swift)
├── Views/                  # SwiftUI views
│   ├── ContentView.swift
│   ├── SidebarView.swift
│   └── SessionView.swift
├── ViewModels/             # @Observable view models
│   └── SessionViewModel.swift
├── Models/                 # Data models (Core Data entities)
├── Audio/                  # Audio services
│   ├── AudioService.swift
│   └── AudioSource.swift
├── Extensions/             # Swift extensions
├── Persistence/            # Core Data stack
│   ├── Persistence.swift
│   └── MeetRec.xcdatamodeld
└── Resources/              # Assets, Info.plist
```

## Common Commands

### Build & Run
```bash
# Open in Xcode
open MeetRec.xcodeproj

# Build from command line
xcodebuild -project MeetRec.xcodeproj -scheme MeetRec -configuration Debug build

# Run tests
xcodebuild test -project MeetRec.xcodeproj -scheme MeetRec
```

### Code Generation
Core Data entities are auto-generated as classes. The model is defined in `MeetRec.xcdatamodeld/MeetRec.xcdatamodel/contents`.

## Key Dependencies

Currently using native frameworks only. Future integrations may include:
- whisper.cpp for local transcription
- MLX Swift for Apple Silicon ML
- OAuth libraries for calendar providers

## Permissions Required

Declared in `Info.plist`:
- **NSMicrophoneUsageDescription**: Required for audio recording
- **NSScreenCaptureUsageDescription**: Required for system audio (future)
- **NSCalendarsUsageDescription**: Required for calendar integration (future)
