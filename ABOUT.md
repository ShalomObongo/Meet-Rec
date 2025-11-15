# About MeetRec - Native macOS Implementation Guide

## Table of Contents
- [Overview](#overview)
- [Core Features](#core-features)
- [Design & User Interface](#design--user-interface)
- [Technical Architecture](#technical-architecture)
- [Data Models & Schema](#data-models--schema)
- [Integration Points](#integration-points)
- [macOS Native Implementation Guide](#macos-native-implementation-guide)
- [Implementation Roadmap](#implementation-roadmap)
- [Technical Considerations](#technical-considerations)

---

## Overview

### What is MeetRec?

MeetRec is a **local-first AI notepad for meetings** that combines real-time transcription, AI-powered summarization, and seamless integrations—all while keeping user data private and secure. The core principle is **privacy**: no data leaves the user's device unless they explicitly configure cloud providers.

### Key Value Propositions

- **Privacy-First**: All data stays local by default; cloud sync is optional
- **Offline-Capable**: Full functionality without internet connection
- **Real-Time Intelligence**: Live transcription and AI summaries during meetings
- **Flexible Architecture**: Support for both local and cloud AI models
- **Professional Integration**: Calendar sync, note-taking app exports, meeting detection

### Target Users

- Remote workers attending frequent video meetings
- Professionals who need meeting documentation (sales, consulting, product)
- Teams requiring meeting notes with privacy guarantees
- Anyone who wants to focus on conversations rather than note-taking

---

## Core Features

### 1. Audio Capture & Recording

#### Capabilities
- **Flexible Audio Source Selection**:
  - **Microphone + System Audio**: Capture both your voice and meeting participants (default)
  - **Microphone Only**: Record only your voice (for personal notes, voice memos)
  - **System Audio Only**: Capture only other participants (when you're not speaking)
  - User can switch sources during recording
- **Dual Audio Sources**:
  - Microphone input (speaker's voice)
  - System audio (other participants in video calls)
  - Independent level monitoring for each source
- **Real-Time Voice Activity Detection (VAD)**:
  - Detects when speech is happening
  - Silero-RS based detection
  - Reduces unnecessary processing
- **Audio Enhancement**:
  - **Acoustic Echo Cancellation (AEC)**: Removes echo from speakers
  - **Automatic Gain Control (AGC)**: Normalizes volume levels
  - **Noise Suppression**: Filters background noise
- **Recording Options**:
  - Optional local storage of audio files
  - User-controlled recording start/stop
  - Visual amplitude indicators for mic and speaker
  - Audio source selection persists across sessions
- **Smart Features**:
  - Microphone mute detection and sync
  - Live audio visualization
  - Multiple audio device selection

#### User Experience
- One-click start/stop recording
- **Audio source selector** dropdown or segmented control:
  - "Mic + System" (default)
  - "Mic Only"
  - "System Only"
- Visual feedback showing active recording state
- Real-time amplitude visualization for each active source
- Automatic device switching when devices change
- Settings remember last used audio source configuration

---

### 2. Transcription System

#### Local Transcription Models (Offline)

**MeetRec Models** (Recommended):
- **Parakeet V2**: English-only, optimized for speed
- **Parakeet V3**: 25+ languages including:
  - English, German, Spanish, French, Italian, Portuguese
  - Dutch, Japanese, Korean, Chinese, Russian, Arabic, Hindi
  - And more
- **Whisper Tiny**: English, quantized for performance
- **Whisper Small**: English, better accuracy

#### Cloud Transcription Providers

**Deepgram**:
- Models: nova-3-general, nova-3-medical, nova-2
- Best for: Real-time accuracy, medical terminology
- Features: Diarization, custom vocabulary

**Groq**:
- Model: Whisper large-v3
- Best for: Fast processing
- Features: High-speed inference

**Fireworks**:
- Model: Whisper large-v3
- Best for: Cost-effective cloud transcription

**Custom Providers**:
- Support for any OpenAI-compatible transcription API
- Configurable endpoints

#### Transcription Features
- **Real-Time Streaming**: See words appear as they're spoken
- **Word-Level Timestamps**: Every word has start_ms and end_ms
- **Speaker Diarization**: Identify who said what with hints
- **Multi-Channel Support**: Separate mic vs speaker audio
- **Batch Processing**: Upload audio files for transcription
- **Custom Vocabulary**: Improve accuracy with domain-specific terms
- **Multi-Language**: 25+ languages supported
- **Edit Transcripts**: Correct mistakes in-app
- **Search Within Transcripts**: Find specific words or phrases

---

### 3. AI-Powered Intelligence

#### Supported LLM Providers

**Cloud Providers**:
- **MeetRec** (Recommended): Built-in cloud service
- **OpenRouter**: Access to 100+ models (GPT, Claude, Gemini, Llama, etc.)
- **OpenAI**: GPT-3.5, GPT-4, GPT-4o, GPT-4o-mini
- **Anthropic**: Claude 3 (Haiku, Sonnet, Opus)
- **Custom**: Any OpenAI-compatible API

**Local Providers**:
- **Ollama**: Run models locally (Llama, Mistral, etc.)
- **LM Studio**: Desktop-based local models

#### AI Features

**Auto-Summarization**:
- Transform raw memos + transcript into polished summaries
- Template-based or free-form generation
- Regenerate summaries with different prompts
- Choose creativity level (grounded vs creative)

**Template System**:
- Pre-built templates for common meeting types:
  - 1:1 meetings
  - Team standups
  - Sales calls
  - Product feedback sessions
  - Retrospectives
- Create custom templates with sections
- Define expected output structure
- Share templates across team

**Autonomy Selector** (Capture Mode):
- **Grounded**: AI sticks closely to user's memos
- **Creative**: AI uses full transcript context for richer summaries

**AI Chat**:
- Interactive Q&A about meetings
- Ask questions about past sessions
- Tool use capabilities (read transcripts, search sessions)
- Context-aware responses
- Floating or docked chat panel

**Smart Features**:
- Auto-generated meeting titles
- Grammar-based structured outputs (GBNF)
- Streaming responses
- Multi-turn conversations

---

### 4. Calendar Integration

#### Supported Providers
- **Apple Calendar** (iCloud)
- **Google Calendar**
- **Microsoft Outlook Calendar**

#### Calendar Features
- **Sync Events**: Automatic bidirectional sync
- **Link Sessions to Events**: Associate recordings with calendar meetings
- **Event Metadata**: Capture title, time, location, meeting link, description
- **Multi-Calendar Support**: Connect multiple calendars per provider
- **Selective Sync**: Enable/disable specific calendars
- **Auto-Detect Meetings**: Suggest starting recordings based on calendar
- **Contact Sync**: Import meeting participants from calendar events

#### User Experience
- One-click calendar connection via OAuth
- Visual calendar view showing events and sessions
- Click event to start recording
- See upcoming meetings in timeline

---

### 5. Meeting Detection & Auto-Start

#### Detection Methods

**Meeting App Detection**:
- Use active app and calendar context to infer likely meetings within public API limits
- Offer to auto-start recording when supported meeting apps are frontmost
- Configurable ignored apps list

**Calendar-Based Detection**:
- Suggest starting recording when calendar event begins
- Show notification before meeting starts

**Application Monitoring**:
- Detect which apps are using audio
- Exclude specific apps (music players, browsers, etc.)

#### Smart Features
- **Do Not Disturb Mode**: Respect system DND settings
- **Quit Intercept**: Prevent accidental app closure during recordings
- **Permission-Based**: User controls all auto-start behavior

---

### 6. Note-Taking & Editor System

#### Triple-Pane Editor

Every session has three synchronized views:

**1. Memos (Raw)**:
- Markdown editor for quick notes during meeting
- Free-form note-taking
- Real-time editing
- Native text editor (`TextEditor` / `NSTextView`)
- Use for: Quick thoughts, action items, important points

**2. Transcript**:
- Complete word-by-word transcription
- Word-level timestamps
- Click words to jump to audio position
- Edit mode for corrections
- Speaker assignment
- Search within transcript
- Use for: Reference, fact-checking, detailed review

**3. Summary (Enhanced)**:
- AI-generated polished notes
- Template-based formatting
- Regenerate with different prompts
- Export-ready format
- Use for: Sharing, documentation, action items

#### Editor Features
- **Rich Text Editing**: Native `NSTextView`-backed WYSIWYG
- **Markdown Support**: Native markdown syntax via `TextEditor` / `NSTextView`
- **Real-Time Sync**: Changes sync across views
- **Search**: Find text within any view
- **Timeline Navigation**: Jump to specific moments
- **Audio Player Integration**: Sync with audio timeline

---

### 7. Organization & Management

#### Folder System
- **Hierarchical Folders**: Nested folder structure
- **Drag & Drop**: Move sessions between folders
- **Breadcrumb Navigation**: See current location
- **Folder-Scoped Views**: Filter timeline by folder

#### Tagging System
- **Flexible Tags**: Add multiple tags per session
- **Tag-Based Filtering**: Find sessions by tag
- **Auto-Tagging**: AI-suggested tags (optional)

#### Search
- **Global Search**: Search across all sessions
- **Full-Text Search**: Search transcripts, memos, summaries
- **Filter by**: Date, folder, tag, participant
- **Quick Find**: Keyboard shortcut (Cmd+K)

#### Timeline View
- **Chronological Display**: All sessions and events sorted by date
- **Grouped by Time**: Today, Yesterday, Last 7 days, Last 30 days, Older
- **Real-Time Indicator**: Shows current time in timeline
- **Mixed Content**: Sessions and calendar events interspersed
- **Auto-Scroll**: Timeline auto-scrolls to "now"

---

### 8. Export & Sharing

#### Export Formats
- **Markdown**: Plain text export
- **PDF**: Formatted document export
- **Copy to Clipboard**: Quick copy for pasting
- **JSON**: Raw data export

#### Integration Exports
- **Obsidian**: Export to Obsidian vault
- **Notion**: Create Notion pages (planned)
- **Slack**: Post summaries to channels (planned)

#### Sharing (Pro Feature)
- **Shareable Links**: Generate public or private links
- **Access Controls**: Set expiration, password protection
- **Embed Player**: Share with audio playback

---

### 9. Templates

#### Template Structure
- **Sections**: Define structured sections (e.g., "Key Points", "Action Items")
- **Targets**: Specify which content to use (memos, transcript, both)
- **Categories**: Organize by meeting type
- **Prompts**: Custom AI prompts per template

#### Built-In Templates
- 1:1 Meeting
- Team Standup
- Sales Call
- Customer Interview
- Product Feedback
- Retrospective
- Interview (Hiring)

#### Custom Templates
- **Create Your Own**: Define custom sections and prompts
- **Local & Remote**: Store locally or fetch from cloud
- **Share Templates**: Export/import template definitions

---

### 10. Privacy & Security Features

#### Privacy Principles
- **Local-First Architecture**: All data stays on device by default
- **No Cloud Requirement**: Full functionality offline
- **Explicit Consent**: User controls all data sharing
- **Transparent Processing**: Clear explanation of what happens to data

#### Security Measures
- **Local Encryption**: SQLite database encrypted
- **Secure API Keys**: Encrypted storage of provider credentials
- **No Telemetry by Default**: Analytics opt-in only
- **Audit Logs**: Track data access (pro feature)

#### User Controls
- **Per-Session Recording**: Choose whether to save audio
- **Delete Anytime**: Permanent deletion of sessions
- **Export Your Data**: Full data export in open formats
- **Optional Cloud Sync**: Core Data with CloudKit (NSPersistentCloudKitContainer) for controlled iCloud sync

---

## Design & User Interface

### Application Layout

```
┌──────────────────────────────────────────────────────────┐
│  Title Bar (Window Controls, Drag Region)                │
├──────────┬───────────────────────────────────────────────┤
│          │  Tab Bar                                      │
│          │  [Session 1] [Event 2] [Folder] [+]          │
│          ├───────────────────────────────────────────────┤
│          │  Session Header                               │
│  Left    │  [Breadcrumb] [Metadata] [Listen Btn]        │
│  Side    ├───────────────────────────────────────────────┤
│  bar     │  Editor Tabs                                  │
│          │  [Summary] [Memos] [Transcript]              │
│  280px   ├───────────────────────────────────────────────┤
│          │                                               │
│  Search  │          Main Editor Content                  │
│  Timeline│                                               │
│  Profile │                                               │
│          │                                               │
│          ├───────────────────────────────────────────────┤
│          │  Audio Timeline (when audio available)        │
└──────────┴───────────────────────────────────────────────┘
```

---

### Left Sidebar

#### Components

**1. Header**:
- App logo
- Collapse button (collapse to icon-only mode)

**2. Search Bar**:
- Global search input
- Keyboard shortcut: Cmd+K
- Search as you type
- Shows results in modal

**3. Timeline View** (Main Content):
- **Grouped by Date**:
  - "Now" (real-time indicator)
  - "Today"
  - "Yesterday"
  - "Last 7 days"
  - "Last 30 days"
  - "January 2024" (month groupings for older)
- **Item Types**:
  - Session items (with title, folder, duration)
  - Event items (calendar events)
- **Visual Indicators**:
  - Recording status (red dot for active)
  - Folder color coding
  - Event vs session icons
- **Sticky Headers**: Date headers stick when scrolling
- **Auto-Scroll**: Automatically scrolls to "Now" on load

**4. Profile Section** (Bottom):
- User avatar
- Account name
- Settings button
- Sign out option

**5. Banner Area**:
- Notification banners
- Update alerts
- Onboarding tips

#### Interaction Patterns
- Click session/event to open in new tab or switch to existing
- Hover shows quick actions (delete, move, tag)
- Right-click for context menu
- Keyboard navigation (arrow keys, enter to open)

---

### Tab System

#### Browser-Style Tabs
```
[← →]  [Session: Team Standup] [Event: 1:1 with John] [Folder: Q1] [+]
        ─────────────────────
        Active tab (underlined)
```

**Features**:
- Multiple tabs open simultaneously
- Tab types: Session, Event, Folder, Contact, Calendar, Empty State
- Drag to reorder tabs
- Close tab: Click X or Cmd+W
- Switch tabs: Cmd+1 through Cmd+9
- Navigate: Back/forward buttons
- New tab: Click + or Cmd+T

**Tab States**:
- Active: Highlighted with underline
- Inactive: Dimmed
- Recording: Red indicator dot
- Unsaved changes: Dot next to title

---

### Session View Layout

#### Outer Header

```
┌────────────────────────────────────────────────────────────────┐
│ 📁 Work > Meetings > Team    [Mic+System ▼] [i] [🎙️ Stop]   │
│                                              [Grounded ▼]      │
└────────────────────────────────────────────────────────────────┘
```

**Components**:

**1. Folder Breadcrumb**:
- Shows folder hierarchy
- Click to navigate to folder
- Drag session to move folders

**2. Audio Source Selector** (Dropdown):
- **Options**:
  - "Mic + System" (default) - Both microphone and system audio
  - "Mic Only" - Only microphone input
  - "System Only" - Only system audio
- Icon changes based on selection:
  - 🎙️ for Mic Only
  - 🔊 for System Only
  - 🎙️🔊 for Both
- Can be changed during recording
- Selection persists in user preferences

**3. Metadata Button** (i icon):
- Shows event details modal
- Participants list
- Meeting link
- Calendar info
- Add tags

**4. Listen Button** (Primary CTA):
- **Not Recording**: "Start listening" (green)
- **Recording**: Red circle with amplitude animation
- **Hover while recording**: Shows "Stop"
- **Finalizing**: "Finalizing..." with spinner

**5. Capture Mode Toggle**:
- Dropdown: [Grounded] or [Creative]
- Controls AI autonomy level
- Tooltip explains difference

**6. Overflow Menu** (...):
- Export options
- Share link
- Delete session
- Move to folder
- Add participants

---

#### Session Title

```
┌────────────────────────────────────────────────────────┐
│  Team Standup - Sprint 42                              │
│  ────────────────────────────                          │
│  (Click to edit)                                        │
└────────────────────────────────────────────────────────┘
```

- Editable inline
- Auto-save on blur
- AI can generate title
- Font: Large, bold

---

#### Editor Tabs

```
┌────────────────────────────────────────────────────────┐
│  [Summary]  [Memos]  [Transcript]                      │
│   ───────                                              │
└────────────────────────────────────────────────────────┘
```

**Tab 1: Summary (Enhanced)**:
- AI-generated formatted notes
- Template-based structure
- **Regenerate Button**: Click to regenerate with options:
  - Choose different template
  - Adjust autonomy level
  - Add custom instructions
- **Empty State**: "Generate summary" button
- **Error State**: Retry button with error message
- **Loading State**: Skeleton with progress indicator

**Tab 2: Memos (Raw)**:
- Native Markdown editor (SwiftUI `TextEditor` / AppKit `NSTextView`)
- Free-form text
- Toolbar: Bold, italic, lists, headings
- **Empty State**: "Start listening" floating button
- Auto-save every 2 seconds
- Word count indicator

**Tab 3: Transcript**:
- Word-by-word transcription display
- Each word clickable (jumps to audio)
- Speaker labels (if diarized)
- **Edit Mode**: Click to edit transcript
  - Correct mistakes
  - Assign speakers
  - Merge/split segments
- **Search**: Cmd+F to search within transcript
- **Progress Indicator**: Shows transcription progress
- **Empty State**: "Transcript will appear here"
- Infinite scroll for long transcripts

---

#### Audio Timeline

```
┌────────────────────────────────────────────────────────┐
│  [▶️] ─────●─────────────── 12:34 / 45:67             │
│        ^                                               │
│        Current position                                │
└────────────────────────────────────────────────────────┘
```

**Features**:
- Play/pause button
- Scrubber for seeking
- Current time / total duration
- Waveform visualization (optional)
- Click transcript words to seek
- Keyboard shortcuts: Space (play/pause), ← → (seek)

---

### Settings Panel

#### Window Layout
```
┌─────────────────────────────────────────┐
│  Settings                          [X]  │
├───────────┬─────────────────────────────┤
│ General   │  App Settings               │
│ AI        │                             │
│ Calendar  │  [Content Area]             │
│ Integr... │                             │
│ Templates │                             │
│ Memory    │                             │
│ Notific...│                             │
│ Account   │                             │
└───────────┴─────────────────────────────┘
```

#### Tab Structure

**1. General**:
- **App Settings**:
  - ✓ Launch at login
  - ✓ Auto-detect meetings
  - ✓ Save recordings locally
  - ✓ Minimize to tray
  - Language selection
  - Theme (Light/Dark/System)
  - **Default Audio Source**: Dropdown
    - Mic + System (default)
    - Mic Only
    - System Only
- **Permissions**:
  - Microphone status
  - Screen recording status
  - Accessibility status
  - Request buttons for each

**2. AI**:
- **Transcription**:
  - Provider dropdown (Local, Deepgram, Groq, etc.)
  - Model selector (auto-populated from provider)
  - Language selection
  - API key input (if cloud)
  - Test connection button
- **Intelligence**:
  - LLM provider dropdown
  - Model selector
  - API key input
  - Test connection button
  - Default autonomy mode

**3. Calendar**:
- **Connected Accounts**:
  - List of connected calendar providers
  - Add account button (OAuth flow)
  - Per-calendar enable/disable toggles
  - Sync status indicators
  - Disconnect button

**4. Integrations**:
- List of available integrations:
  - Obsidian (configure vault path)
  - Notion (connect account)
  - Slack (connect workspace)
  - HubSpot, Salesforce, etc.
- Connection status for each
- Configure/disconnect buttons

**5. Templates**:
- **Local Templates**:
  - List of user-created templates
  - Edit/delete options
  - Create new template button
- **Remote Templates**:
  - Browse template library
  - Install templates
  - Update available indicators

**6. Memory**:
- **Custom Vocabulary**:
  - Add words/phrases to improve transcription
  - Domain-specific terminology
  - Proper nouns (names, companies)
  - Import/export vocabulary lists

**7. Notifications**:
- **Event Notifications**:
  - ✓ Notify before meetings start (X minutes before)
  - ✓ Notify when meeting starts
- **Microphone Detection**:
  - ✓ Show notification when mic is active
  - Excluded apps list
  - Add app to ignore button

**8. Account**:
- **User Profile**:
  - Email
  - Name
  - Avatar
- **Subscription**:
  - Current plan (Free / Pro)
  - Billing details
  - Upgrade/downgrade options
- **Usage**:
  - Sessions this month
  - Transcription minutes used
  - Storage used

---

### Onboarding Flow

#### Step 1: Welcome
```
┌────────────────────────────────────┐
│                                    │
│         🎙️ MeetRec                │
│                                    │
│  Where Conversations Stay Yours    │
│                                    │
│        [Get Started]               │
│                                    │
└────────────────────────────────────┘
```

#### Step 2: Permissions
```
┌────────────────────────────────────┐
│  Grant Permissions                 │
│                                    │
│  ✓ Microphone Access              │
│    Required for recording          │
│                                    │
│  ○ Screen Recording               │
│    Required for system audio       │
│    [Grant Access]                  │
│                                    │
│  ○ Accessibility                  │
│    Optional, for better UX         │
│    [Grant Access]                  │
│                                    │
│              [Continue]            │
└────────────────────────────────────┘
```

#### Step 3: Calendar (Optional)
```
┌────────────────────────────────────┐
│  Connect Your Calendar             │
│                                    │
│  [G] Connect Google Calendar       │
│                                    │
│  [O] Connect Outlook Calendar      │
│                                    │
│  [ ] Connect Apple Calendar        │
│                                    │
│              [Skip]  [Continue]    │
└────────────────────────────────────┘
```

#### Step 4: Ready
```
┌────────────────────────────────────┐
│  You're All Set! 🎉                │
│                                    │
│  Start your first session or       │
│  explore the app.                  │
│                                    │
│        [Start Session]             │
│        [Take a Tour]               │
│                                    │
└────────────────────────────────────┘
```

---

### Chat Interface

#### Floating Chat (40% width, 70% height)
```
┌──────────────────────────────┐
│  Chat  [Session: Team...]  ×│
├──────────────────────────────┤
│                              │
│  User: What action items?   │
│                              │
│  AI: Based on transcript:   │
│  1. Update roadmap          │
│  2. Schedule follow-up      │
│                              │
├──────────────────────────────┤
│  Type a message...      [→] │
└──────────────────────────────┘
```

**Features**:
- Draggable window
- Resizable
- Context-aware of active session
- Tool use (can read transcripts, search)
- Streaming responses
- Message history
- Minimize/maximize

#### Docked Chat (Right Panel)
- Fixed to right side of window
- Same features as floating
- 30% of window width
- Toggle with keyboard shortcut

---

### Design System

#### Colors

**Neutrals** (Primary):
- Gray 50: #fafafa (backgrounds)
- Gray 100: #f5f5f5
- Gray 200: #e5e5e5 (borders)
- Gray 300: #d4d4d4
- Gray 400: #a3a3a3
- Gray 500: #737373 (text secondary)
- Gray 600: #525252
- Gray 700: #404040
- Gray 800: #262626
- Gray 900: #171717 (text primary)

**Accent Colors**:
- Red 500: #ef4444 (recording, danger)
- Emerald 500: #10b981 (success)
- Yellow 500: #eab308 (warning)
- Blue 500: #3b82f6 (info, links)

**Semantic Colors**:
- Recording: Red 500
- Active: Blue 500
- Success: Emerald 500
- Warning: Yellow 500
- Error: Red 500

#### Typography

**Font Family**: System font stack
- macOS: SF Pro
- Windows: Segoe UI
- Linux: Roboto

**Font Sizes**:
- xs: 12px (0.75rem)
- sm: 14px (0.875rem)
- base: 16px (1rem)
- lg: 18px (1.125rem)
- xl: 20px (1.25rem)
- 2xl: 24px (1.5rem)
- 3xl: 30px (1.875rem)

**Font Weights**:
- Regular: 400
- Medium: 500
- Semibold: 600
- Bold: 700

**Line Heights**:
- Tight: 1.25
- Normal: 1.5
- Relaxed: 1.75

#### Spacing Scale (Tailwind)
- 0: 0px
- 1: 4px
- 2: 8px
- 3: 12px
- 4: 16px
- 6: 24px
- 8: 32px
- 12: 48px
- 16: 64px

#### Border Radius
- sm: 4px
- base: 8px (standard)
- lg: 12px
- xl: 16px
- full: 9999px (pills)

#### Shadows
- sm: subtle shadow for cards
- base: standard elevation
- lg: modals, popovers
- xl: dropdowns

---

### Native macOS Components

**AppKit Components** (Traditional):
- NSTextField, NSTextView
- NSPopUpButton, NSComboBox
- NSButton (Checkbox, Radio)
- NSSwitch (toggles)
- NSSlider, NSProgressIndicator

**SwiftUI Components** (Modern):
- TextField, TextEditor
- Picker, Menu
- Toggle, Checkbox
- Slider, ProgressView
- List, ScrollView

**Navigation**:
- NSTabView / TabView
- NSMenu / Menu
- NSPopover / Popover
- Breadcrumb (Custom)

**Feedback**:
- NSAlert / Alert
- NSPanel / Sheet
- NSWindow / Window
- ToolTip / .help()
- ProgressView / NSProgressIndicator

**Layout**:
- DisclosureGroup (SwiftUI)
- Divider / NSSplitView
- ScrollView / NSScrollView

---

## Technical Architecture

### Native macOS App Stack

#### UI Framework Options

**Option 1: SwiftUI (Recommended)**
- **SwiftUI**: Declarative UI framework (macOS 10.15+)
- **Combine**: Reactive framework for data flow
- **async/await**: Modern concurrency
- **@Observable macro**: Modern state management (Swift 5.9+, macOS 14+)
- **ObservableObject protocol**: Legacy state management (macOS 11-13)
- **@Bindable**: Two-way bindings for observable properties
- **TCA (The Composable Architecture)**: Optional state management
- Modern, less code, best for new projects

**Option 2: AppKit (Legacy Support)**
- **NSViewController**: View controller pattern
- **Interface Builder**: Visual UI design
- **Cocoa Bindings**: Data binding
- **NotificationCenter**: Event system
- **KVO**: Key-Value Observing
- More control, better for macOS 10.14 and below

**Hybrid Approach** (Best of Both):
- SwiftUI for new views
- AppKit for complex controls
- NSHostingController to bridge between them

#### Core Technologies

**Audio Processing**:
- **AVFoundation**: Audio capture and playback
- **Core Audio**: Low-level audio processing
- **AudioToolbox**: Audio file I/O
- **Accelerate**: DSP and signal processing (vDSP)
- **Speech Framework**: Native speech recognition (supports on-device mode with `requiresOnDeviceRecognition`)

**Transcription**:
- **Speech Framework**: Apple's speech recognition (with optional on-device mode)
- **whisper.cpp**: Local Whisper models (via C++ bridge)
- **CloudKit**: Optional cloud-based processing
- **URLSession**: WebSocket for cloud transcription services

**AI/LLM**:
- **MLX Swift**: Apple Silicon optimized ML framework
- **Core ML**: On-device model inference
- **CreateML**: Model training (optional)
- **URLSession**: API calls to cloud LLM providers
- **Natural Language Framework**: Text processing

**Database**:
- **Core Data**: Apple's ORM framework
- **SQLite**: Direct SQL access (via GRDB or SQLite.swift)
- **CloudKit**: Optional cloud sync
- **UserDefaults**: Simple key-value storage

**Calendar Integration**:
- **EventKit**: Native calendar and reminders access
- **Google Calendar API**: OAuth + REST API
- **Microsoft Graph API**: OAuth + REST API

**System Integration**:
- **LaunchAgent**: Auto-start on login
- **NSMenu**: Menu bar integration
- **NSStatusItem**: System tray icon
- **UNUserNotificationCenter**: User notifications (macOS 10.14+)
- **Accessibility API**: Observe UI state and app focus for meeting heuristics
- **ScreenCaptureKit**: System audio capture (macOS 12.3+)

**Networking**:
- **URLSession**: HTTP/WebSocket client
- **Combine**: Reactive networking
- **async/await**: Modern async networking

#### Project Structure
```
MeetRec.xcodeproj
├── MeetRec/                    # Main app target
│   ├── App/
│   │   ├── MeetRecApp.swift   # App entry point
│   │   └── AppDelegate.swift  # AppKit app delegate (if needed)
│   ├── Views/                  # SwiftUI views
│   │   ├── MainWindow/
│   │   │   ├── ContentView.swift
│   │   │   ├── SidebarView.swift
│   │   │   └── TabView.swift
│   │   ├── Session/
│   │   │   ├── SessionView.swift
│   │   │   ├── EditorView.swift
│   │   │   └── TranscriptView.swift
│   │   ├── Settings/
│   │   │   └── SettingsView.swift
│   │   └── Onboarding/
│   │       └── OnboardingView.swift
│   ├── ViewModels/             # Observable view models
│   │   ├── SessionViewModel.swift
│   │   ├── TranscriptViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Models/                 # Data models
│   │   ├── Session.swift
│   │   ├── Transcript.swift
│   │   └── Word.swift
│   ├── Services/               # Business logic
│   │   ├── AudioService.swift
│   │   ├── TranscriptionService.swift
│   │   ├── AIService.swift
│   │   └── CalendarService.swift
│   ├── Persistence/            # Data persistence
│   │   ├── MeetRec.xcdatamodeld  # Core Data model
│   │   ├── PersistenceController.swift
│   │   └── DataMigration.swift
│   ├── Extensions/             # Swift extensions
│   │   └── Date+Extensions.swift
│   ├── Utilities/              # Helper classes
│   │   └── Logger.swift
│   └── Resources/              # Assets, strings, etc.
│       ├── Assets.xcassets
│       └── Localizable.strings
├── MeetRecTests/               # Unit tests
└── MeetRecUITests/             # UI tests
```

#### Audio Pipeline Architecture
```
┌────────────────────────────────────────┐
│  AVAudioEngine                         │
│  ┌──────────────────────────────────┐  │
│  │  Input Node (Microphone)         │  │
│  └──────────────┬───────────────────┘  │
│                 │                      │
│  ┌──────────────▼───────────────────┐  │
│  │  Mixer Node                      │◄─┼─── System Audio (ScreenCaptureKit)
│  └──────────────┬───────────────────┘  │
│                 │                      │
│  ┌──────────────▼───────────────────┐  │
│  │  Effect Nodes                    │  │
│  │  - vDSP AEC (Echo Cancellation)  │  │
│  │  - vDSP AGC (Gain Control)       │  │
│  │  - Noise Gate                    │  │
│  └──────────────┬───────────────────┘  │
│                 │                      │
│  ┌──────────────▼───────────────────┐  │
│  │  VAD (Voice Activity Detection)  │  │
│  └──────────────┬───────────────────┘  │
│                 │                      │
│  ┌──────────────▼───────────────────┐  │
│  │  Tap Node (Record/Stream)        │  │
│  └──────────────┬───────────────────┘  │
│                 │                      │
│  ┌──────────────▼───────────────────┐  │
│  │  Output Node (Playback)          │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
                 │
                 ▼
     ┌───────────────────────┐
     │ Transcription Service │
     └───────────────────────┘
```

---

## Data Models & Schema

### Database Tables (SQLite / Postgres)

#### 1. users
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  avatar_url TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER
);
```

#### 2. sessions
```sql
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  folder_id TEXT REFERENCES folders(id),
  event_id TEXT REFERENCES events(id),
  title TEXT,
  raw_md TEXT,           -- Memos content
  enhanced_md TEXT,      -- Summary content
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  started_at INTEGER,    -- Recording start timestamp
  ended_at INTEGER,      -- Recording end timestamp
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 3. transcripts
```sql
CREATE TABLE transcripts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  session_id TEXT NOT NULL REFERENCES sessions(id),
  created_at INTEGER NOT NULL,
  started_at INTEGER,    -- First word timestamp
  ended_at INTEGER,      -- Last word timestamp
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 4. words
```sql
CREATE TABLE words (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  transcript_id TEXT NOT NULL REFERENCES transcripts(id),
  text TEXT NOT NULL,
  start_ms INTEGER NOT NULL,  -- Word start time in milliseconds
  end_ms INTEGER NOT NULL,    -- Word end time in milliseconds
  channel TEXT,               -- 'mic' or 'speaker'
  speaker TEXT,               -- Speaker ID (if diarized)
  confidence REAL,            -- Transcription confidence (0-1)
  created_at INTEGER NOT NULL,
  metadata TEXT,              -- JSON for additional data
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 5. speaker_hints
```sql
CREATE TABLE speaker_hints (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  transcript_id TEXT NOT NULL REFERENCES transcripts(id),
  word_id TEXT NOT NULL REFERENCES words(id),
  type TEXT NOT NULL,         -- 'identity', 'merge', 'split'
  value TEXT NOT NULL,        -- JSON value
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 6. humans (Contacts/Participants)
```sql
CREATE TABLE humans (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  org_id TEXT REFERENCES organizations(id),
  name TEXT NOT NULL,
  email TEXT,
  job_title TEXT,
  linkedin_username TEXT,
  is_user INTEGER DEFAULT 0,  -- Boolean
  memo TEXT,                  -- User notes about person
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 7. organizations
```sql
CREATE TABLE organizations (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  domain TEXT,
  logo_url TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 8. events (Calendar Events)
```sql
CREATE TABLE events (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  calendar_id TEXT NOT NULL REFERENCES calendars(id),
  external_id TEXT NOT NULL,  -- ID from calendar provider
  title TEXT NOT NULL,
  started_at INTEGER NOT NULL,
  ended_at INTEGER NOT NULL,
  location TEXT,
  meeting_link TEXT,
  description TEXT,
  note TEXT,                  -- User's notes about event
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 9. calendars
```sql
CREATE TABLE calendars (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  provider TEXT NOT NULL,     -- 'google', 'apple', 'outlook'
  external_id TEXT NOT NULL,  -- ID from provider
  name TEXT NOT NULL,
  color TEXT,
  is_enabled INTEGER DEFAULT 1,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 10. folders
```sql
CREATE TABLE folders (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  parent_folder_id TEXT REFERENCES folders(id),
  name TEXT NOT NULL,
  color TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 11. templates
```sql
CREATE TABLE templates (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT,
  sections TEXT NOT NULL,     -- JSON array of sections
  targets TEXT NOT NULL,      -- JSON array: ['memos', 'transcript']
  is_remote INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 12. tags
```sql
CREATE TABLE tags (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  color TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 13. mapping_session_participant
```sql
CREATE TABLE mapping_session_participant (
  session_id TEXT NOT NULL REFERENCES sessions(id),
  human_id TEXT NOT NULL REFERENCES humans(id),
  PRIMARY KEY (session_id, human_id)
);
```

#### 14. mapping_tag_session
```sql
CREATE TABLE mapping_tag_session (
  tag_id TEXT NOT NULL REFERENCES tags(id),
  session_id TEXT NOT NULL REFERENCES sessions(id),
  PRIMARY KEY (tag_id, session_id)
);
```

#### 15. chat_groups
```sql
CREATE TABLE chat_groups (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 16. chat_messages
```sql
CREATE TABLE chat_messages (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  chat_group_id TEXT NOT NULL REFERENCES chat_groups(id),
  role TEXT NOT NULL,         -- 'user', 'assistant', 'system'
  content TEXT NOT NULL,
  metadata TEXT,              -- JSON for tool calls, etc.
  parts TEXT,                 -- JSON for multimodal content
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 17. memories (Custom Vocabulary)
```sql
CREATE TABLE memories (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL,         -- 'vocabulary', 'context'
  text TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 18. audio_files (Optional)
```sql
CREATE TABLE audio_files (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL REFERENCES sessions(id),
  file_path TEXT NOT NULL,
  duration_ms INTEGER,
  file_size INTEGER,
  created_at INTEGER NOT NULL
);
```

---

### State Management Architecture

#### Core Data (Persistent Data)
Used for database-backed models:
- Sessions
- Transcripts
- Words
- Events
- Calendars
- Folders
- Tags

**Core Data Benefits**:
- NSFetchedResultsController for reactive UI updates
- Relationships and cascading deletes
- Indexes and predicates
- iCloud sync (optional)
- Background context for heavy operations

#### @Observable / ObservableObject (UI State)
Used for view-level state:
- View models for each major view
- Open tabs management
- Sidebar collapsed state
- Selected items
- Theme preference

**Modern Approach (macOS 14+, Swift 5.9+):**
```swift
@Observable
class AppState {
    var openTabs: [Tab] = []
    var selectedTab: Tab.ID?
    var sidebarCollapsed: Bool = false
}

struct ContentView: View {
    @State private var appState = AppState()

    var body: some View {
        @Bindable var appState = appState
        Toggle("Collapse Sidebar", isOn: $appState.sidebarCollapsed)
    }
}
```

**Legacy Approach (macOS 11-13):**
```swift
class AppState: ObservableObject {
    @Published var openTabs: [Tab] = []
    @Published var selectedTab: Tab.ID?
    @Published var sidebarCollapsed: Bool = false
}

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        Toggle("Collapse Sidebar", isOn: $appState.sidebarCollapsed)
    }
}
```

#### Combine Publishers (Reactive Data Flow)
Used for async data streams:
- Audio level monitoring
- Transcription updates
- Network requests
- File I/O operations

```swift
class AudioService {
    let levelPublisher = PassthroughSubject<Float, Never>()
    let transcriptionPublisher = PassthroughSubject<Word, Never>()
}
```

#### UserDefaults / AppStorage (Settings)
Used for user preferences:
- App settings
- API keys (stored in Keychain)
- Window positions
- Last used folders

```swift
@AppStorage("autoStartRecording") var autoStart: Bool = false
```

#### Actor Pattern (Concurrency)
Used for thread-safe services:
- Audio processing
- Transcription queue
- File operations

**Best Practice**:
- Mark ObservableObject-based view models that update UI state with `@MainActor` to align with Swift’s strict concurrency checking and avoid manual main-thread dispatch.

```swift
actor TranscriptionQueue {
    func enqueue(_ audio: Data) async throws -> Transcript { }
}
```

---

## Integration Points

### 1. Calendar APIs

#### Google Calendar
**OAuth Flow**:
1. User clicks "Connect Google Calendar"
2. OAuth consent screen opens
3. User grants permissions
4. App receives access token
5. Store token encrypted

**API Endpoints**:
- `GET /calendar/v3/users/me/calendarList`: List calendars
- `GET /calendar/v3/calendars/{calendarId}/events`: Fetch events
- `POST /calendar/v3/calendars/{calendarId}/events`: Create event
- `PATCH /calendar/v3/calendars/{calendarId}/events/{eventId}`: Update event

**Sync Strategy**:
- Poll every 15 minutes
- Use sync tokens for incremental updates
- Store `nextSyncToken` for efficiency

#### Microsoft Outlook Calendar
**OAuth Flow**: Similar to Google, using Microsoft Identity Platform

**API Endpoints**:
- `GET /me/calendars`: List calendars
- `GET /me/calendars/{id}/events`: Fetch events
- Microsoft Graph API

#### Apple Calendar (macOS Only)
**Native Integration**:
- Use EventKit framework
- No OAuth required
- Direct access to iCloud calendars
- Requires user permission

---

### 2. Transcription Service APIs

#### Deepgram
**WebSocket Streaming**:
```javascript
const ws = new WebSocket('wss://api.deepgram.com/v1/listen?model=nova-3');
ws.send(audioChunk); // Send audio chunks
ws.onmessage = (event) => {
  const { transcript } = JSON.parse(event.data);
  // Handle transcript
};
```

**Features**:
- Real-time streaming
- Word-level timestamps
- Speaker diarization
- Custom vocabulary
- Multi-language

#### AssemblyAI
**HTTP + WebSocket**:
1. Upload audio to `/v2/upload`
2. Create transcript via `/v2/transcript`
3. Poll for completion or use WebSocket
4. Fetch final transcript

**Features**:
- High accuracy
- Speaker diarization
- Topic detection
- Content moderation

#### OpenAI Whisper API
**HTTP POST**:
```javascript
const formData = new FormData();
formData.append('file', audioFile);
formData.append('model', 'whisper-1');

const response = await fetch('https://api.openai.com/v1/audio/transcriptions', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${apiKey}` },
  body: formData
});
```

---

### 3. LLM Provider APIs

#### OpenAI
**Streaming Chat Completion**:
```javascript
const response = await fetch('https://api.openai.com/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${apiKey}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model: 'gpt-4',
    messages: [...],
    stream: true
  })
});

// Use Vercel AI SDK for easier streaming
import { OpenAI } from '@ai-sdk/openai';
const model = openai('gpt-4');
const result = await streamText({ model, prompt });
```

#### Anthropic Claude
**Streaming**:
```javascript
import { Anthropic } from '@anthropic-ai/sdk';
const anthropic = new Anthropic({ apiKey });

const stream = await anthropic.messages.create({
  model: 'claude-3-5-sonnet-20250514',
  max_tokens: 1024,
  messages: [...],
  stream: true
});

for await (const event of stream) {
  // Handle streaming events
}
```

#### OpenRouter
**Unified API**:
- Access 100+ models through one API
- OpenAI-compatible interface
- Model pricing transparency

```javascript
const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${apiKey}`,
    'HTTP-Referer': yourSiteUrl,
    'X-Title': yourSiteName
  },
  body: JSON.stringify({
    model: 'anthropic/claude-3.5-sonnet',
    messages: [...]
  })
});
```

---

### 4. Third-Party App Integrations

#### Obsidian
**File System Integration**:
- User selects vault path via NSOpenPanel
- Write markdown files to vault
- Frontmatter for metadata
- Bi-directional links support

#### Notion (Planned)
**Notion API**:
- OAuth for authentication
- Create pages in databases
- Rich content blocks
- Bi-directional sync

#### Slack (Planned)
**Slack API**:
- OAuth for workspace access
- Post messages to channels
- Slash commands for quick sharing
- Unfurl meeting links

---

## macOS Native Implementation Guide

### Recommended Tech Stack

#### Swift & Xcode
- **Xcode 15+**: IDE and toolchain
- **Swift 5.9+**: Programming language
- **SwiftUI**: Declarative UI framework (macOS 10.15+)
- **AppKit**: Traditional UI framework (for complex controls)
- **Swift Concurrency**: async/await, actors, tasks
- **Combine**: Reactive programming framework

#### Data & Persistence
- **Core Data**: Apple's ORM (macOS 10.4+)
- **GRDB**: Advanced SQLite wrapper (optional)
- **CloudKit**: Cloud sync (optional)
- **UserDefaults**: Settings storage
- **Keychain**: Secure credential storage

#### Audio & Speech
- **AVFoundation**: Audio capture and playback
- **Core Audio**: Low-level audio processing
- **Speech Framework**: Speech recognition with optional on-device mode (`requiresOnDeviceRecognition`)
- **ScreenCaptureKit**: System audio capture (macOS 12.3+)
- **Accelerate**: DSP operations (vDSP)

**Info.plist (Speech)**:
- Add `NSSpeechRecognitionUsageDescription` with a clear string such as:
  - `"MeetRec uses speech recognition to transcribe your meetings locally on your Mac."`

#### AI & ML
- **MLX Swift**: Apple Silicon ML framework
- **Core ML**: On-device inference
- **Natural Language**: Text processing
- **URLSession**: Cloud API integration

#### System Integration
- **EventKit**: Calendar and reminders
- **UserNotifications**: System notifications
- **ServiceManagement**: Launch agents
- **Accessibility**: Monitor app permissions

**Info.plist (Calendars)**:
- For macOS, add `NSCalendarsUsageDescription` with text like:
  - `"MeetRec uses your calendars to detect upcoming meetings and link recordings to events."`

---

### Architecture Overview

```
┌─────────────────────────────────────────────┐
│         SwiftUI Views / AppKit              │
│  ┌───────────────────────────────────────┐  │
│  │  ContentView, SidebarView, etc.       │  │
│  └──────────────┬────────────────────────┘  │
│                 │ Bindings / Combine        │
├─────────────────┼─────────────────────────────┤
│         View Models (@ObservableObject)    │
│  ┌──────────────▼────────────────────────┐  │
│  │  SessionViewModel, AudioViewModel     │  │
│  └──────────────┬────────────────────────┘  │
│                 │ Calls                     │
├─────────────────┼─────────────────────────────┤
│              Services Layer                │
│  ┌──────────────▼────────────────────────┐  │
│  │  AudioService, TranscriptionService   │  │
│  │  AIService, CalendarService           │  │
│  └──────────────┬────────────────────────┘  │
│                 │                           │
├─────────────────┼─────────────────────────────┤
│         Persistence & External APIs        │
│  ┌──────────────▼────────────────────────┐  │
│  │  Core Data                            │  │
│  │  Deepgram, OpenAI, Google Calendar    │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

---

### Core Data Schema

#### Entity Definitions

```swift
// Session entity
@objc(Session)
class Session: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String?
    @NSManaged var rawMarkdown: String?      // Memos
    @NSManaged var enhancedMarkdown: String? // Summary
    @NSManaged var startedAt: Date?
    @NSManaged var endedAt: Date?
    @NSManaged var createdAt: Date
    @NSManaged var folder: Folder?
    @NSManaged var event: CalendarEvent?
    @NSManaged var transcripts: Set<Transcript>
    @NSManaged var tags: Set<Tag>
    @NSManaged var participants: Set<Human>
}

// Transcript entity
@objc(Transcript)
class Transcript: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var startedAt: Date?
    @NSManaged var endedAt: Date?
    @NSManaged var createdAt: Date
    @NSManaged var session: Session
    @NSManaged var words: NSOrderedSet // Ordered for timeline
}

// Word entity
@objc(Word)
class Word: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var text: String
    @NSManaged var startMs: Int64
    @NSManaged var endMs: Int64
    @NSManaged var channel: String? // "mic" or "speaker"
    @NSManaged var speaker: String?
    @NSManaged var confidence: Double
    @NSManaged var transcript: Transcript
}

// Folder entity
@objc(Folder)
class Folder: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var color: String?
    @NSManaged var parent: Folder?
    @NSManaged var children: Set<Folder>
    @NSManaged var sessions: Set<Session>
}
```

---

### Key Implementation Details

#### 1. Audio Recording with AVFoundation

```swift
// Services/AudioService.swift

import AVFoundation
import Combine

enum AudioSource: String, Codable, CaseIterable {
    case micAndSystem = "Mic + System"
    case micOnly = "Mic Only"
    case systemOnly = "System Only"

    var includesMic: Bool {
        self == .micAndSystem || self == .micOnly
    }

    var includesSystem: Bool {
        self == .micAndSystem || self == .systemOnly
    }
}

class AudioService: ObservableObject {
    @Published var isRecording = false
    @Published var micLevel: Float = 0.0
    @Published var speakerLevel: Float = 0.0
    @Published var audioSource: AudioSource = .micAndSystem

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var mixerNode: AVAudioMixerNode?
    private var systemAudioService: SystemAudioService?

    private let levelPublisher = PassthroughSubject<(mic: Float, speaker: Float), Never>()
    private let audioDataPublisher = PassthroughSubject<Data, Never>()

    func startRecording(source: AudioSource = .micAndSystem) async throws {
        guard !isRecording else { return }

        self.audioSource = source

        // Request microphone permission if needed
        if source.includesMic {
            let authorized = await AVCaptureDevice.requestAccess(for: .audio)
            guard authorized else { throw AudioError.permissionDenied }
        }

        // Setup audio engine for microphone if needed
        if source.includesMic {
            audioEngine = AVAudioEngine()
            inputNode = audioEngine!.inputNode
            mixerNode = AVAudioMixerNode()

            audioEngine!.attach(mixerNode!)

            // Connect nodes
            let format = inputNode!.outputFormat(forBus: 0)
            audioEngine!.connect(inputNode!, to: mixerNode!, format: format)
            audioEngine!.connect(mixerNode!, to: audioEngine!.mainMixerNode, format: format)

            // Install tap for recording
            mixerNode!.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, time in
                self?.processAudioBuffer(buffer, channel: "mic")
            }

            try audioEngine!.start()
        }

        // Setup system audio capture if needed
        if source.includesSystem {
            if #available(macOS 12.3, *) {
                systemAudioService = SystemAudioService()
                try await systemAudioService?.startCapture { [weak self] buffer in
                    self?.processAudioBuffer(buffer, channel: "system")
                }
            } else {
                throw AudioError.systemAudioNotAvailable
            }
        }

        isRecording = true
    }

    func setAudioSource(_ newSource: AudioSource) async throws {
        let wasRecording = isRecording

        if wasRecording {
            stopRecording()
        }

        audioSource = newSource

        // Persist preference
        UserDefaults.standard.set(newSource.rawValue, forKey: "audioSource")

        if wasRecording {
            try await startRecording(source: newSource)
        }
    }

    func stopRecording() {
        audioEngine?.stop()
        mixerNode?.removeTap(onBus: 0)

        if #available(macOS 12.3, *) {
            Task {
                try? await systemAudioService?.stopCapture()
                systemAudioService = nil
            }
        }

        isRecording = false
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, channel: String) {
        // Calculate audio level
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let channelDataArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
            .map { channelDataValue[$0] }

        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        let normalizedLevel = max(0, min(1, (avgPower + 50) / 50))

        DispatchQueue.main.async {
            if channel == "mic" {
                self.micLevel = normalizedLevel
            } else if channel == "system" {
                self.speakerLevel = normalizedLevel
            }
        }

        // Convert to Data for transcription with channel tag
        if let audioData = buffer.toData() {
            audioDataPublisher.send(audioData)
        }
    }
}

enum AudioError: Error {
    case permissionDenied
    case systemAudioNotAvailable
}

extension AVAudioPCMBuffer {
    func toData() -> Data? {
        let audioBuffer = audioBufferList.pointee.mBuffers
        return Data(bytes: audioBuffer.mData!, count: Int(audioBuffer.mDataByteSize))
    }
}
```

#### 2. System Audio Capture (ScreenCaptureKit)

```swift
// Services/SystemAudioService.swift

import ScreenCaptureKit

@available(macOS 12.3, *)
class SystemAudioService: NSObject, ObservableObject {
    private var stream: SCStream?
    private var audioBufferCallback: ((AVAudioPCMBuffer) -> Void)?

    func startCapture(bufferCallback: @escaping (AVAudioPCMBuffer) -> Void) async throws {
        self.audioBufferCallback = bufferCallback

        // Get available content (requires Screen Recording permission)
        let content = try await SCShareableContent.current

        // Configure stream for audio only
        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.sampleRate = 48000
        config.channelCount = 2
        config.excludesCurrentProcessAudio = true

        // Create filter for display audio
        guard let display = content.displays.first else {
            throw NSError(domain: "SystemAudio", code: 1, userInfo: [NSLocalizedDescriptionKey: "No display found"])
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])

        // Create stream
        stream = SCStream(filter: filter, configuration: config, delegate: self)

        // Add audio output
        try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: DispatchQueue(label: "com.meetrec.audio.queue"))
        try await stream?.startCapture()
    }

    func stopCapture() async throws {
        try await stream?.stopCapture()
        stream = nil
        audioBufferCallback = nil
    }
}

@available(macOS 12.3, *)
extension SystemAudioService: SCStreamDelegate, SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }

        // Convert CMSampleBuffer to AVAudioPCMBuffer
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
              let audioFormat = AVAudioFormat(cmAudioFormatDescription: formatDescription) else {
            return
        }

        let frameCapacity = CMSampleBufferGetNumSamples(sampleBuffer)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCapacity)) else {
            return
        }

        pcmBuffer.frameLength = pcmBuffer.frameCapacity

        // Copy audio data
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

        var length: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)

        if let dataPointer = dataPointer, let channelData = pcmBuffer.floatChannelData {
            dataPointer.withMemoryRebound(to: Float.self, capacity: length / MemoryLayout<Float>.size) { floatPointer in
                channelData.pointee.initialize(from: floatPointer, count: Int(pcmBuffer.frameLength))
            }
        }

        // Call the callback with the processed buffer
        audioBufferCallback?(pcmBuffer)
    }
}
```

#### 3. Speech Recognition (Apple's Speech Framework)

```swift
// Services/TranscriptionService.swift

import Speech

class TranscriptionService: ObservableObject {
    @Published var words: [Word] = []

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func startTranscription() async throws {
        // Request authorization
        let authorized = await SFSpeechRecognizer.requestAuthorization()
        guard authorized == .authorized else { throw TranscriptionError.unauthorized }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true // Keep audio on device when supported
        recognitionRequest.taskHint = .dictation

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let result = result else { return }

            let transcription = result.bestTranscription
            self?.processTranscription(transcription)

            if result.isFinal {
                self?.audioEngine.stop()
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
            }
        }

        // Setup audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopTranscription() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }

    private func processTranscription(_ transcription: SFTranscription) {
        let newWords = transcription.segments.map { segment in
            Word(
                text: segment.substring,
                startMs: Int64(segment.timestamp * 1000),
                endMs: Int64((segment.timestamp + segment.duration) * 1000)
            )
        }

        DispatchQueue.main.async {
            self.words = newWords
        }
    }
}
```

**Permissions & Privacy (Speech)**:
- Ensure `NSSpeechRecognitionUsageDescription` is present in your app's Info.plist so macOS can show a clear rationale when asking for speech-recognition access.

#### 4. Cloud Transcription (Deepgram WebSocket)

```swift
// Services/DeepgramService.swift

import Foundation

class DeepgramService: NSObject, ObservableObject {
    @Published var words: [Word] = []

    private var webSocketTask: URLSessionWebSocketTask?
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func startTranscription() {
        let url = URL(string: "wss://api.deepgram.com/v1/listen?model=nova-2&language=en&smart_format=true")!
        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()

        receiveMessage()
    }

    func sendAudio(_ audioData: Data) {
        let message = URLSessionWebSocketTask.Message.data(audioData)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self?.processTranscriptionData(data)
                case .string(let string):
                    if let data = string.data(using: .utf8) {
                        self?.processTranscriptionData(data)
                    }
                @unknown default:
                    break
                }
                self?.receiveMessage() // Continue receiving

            case .failure(let error):
                print("WebSocket receive error: \(error)")
            }
        }
    }

    private func processTranscriptionData(_ data: Data) {
        struct DeepgramResponse: Codable {
            struct Channel: Codable {
                struct Alternative: Codable {
                    struct Word: Codable {
                        let word: String
                        let start: Double
                        let end: Double
                        let confidence: Double
                    }
                    let words: [Word]
                }
                let alternatives: [Alternative]
            }
            let channel: Channel
        }

        guard let response = try? JSONDecoder().decode(DeepgramResponse.self, from: data) else { return }
        guard let alternative = response.channel.alternatives.first else { return }

        let newWords = alternative.words.map { word in
            Word(
                text: word.word,
                startMs: Int64(word.start * 1000),
                endMs: Int64(word.end * 1000)
            )
        }

        DispatchQueue.main.async {
            self.words.append(contentsOf: newWords)
        }
    }

    func stopTranscription() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}
```

#### 5. AI Summarization

```swift
// Services/AIService.swift

import Foundation

class AIService: ObservableObject {
    @Published var summary: String = ""
    @Published var isGenerating: Bool = false

    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func generateSummary(memos: String, transcript: String, autonomy: AutonomyLevel) async throws {
        isGenerating = true
        defer { isGenerating = false }

        let prompt = autonomy == .grounded
            ? "Summarize these memos:\n\n\(memos)"
            : "Summarize this meeting:\n\nMemos:\n\(memos)\n\nTranscript:\n\(transcript)"

        let request = OpenAIRequest(
            model: "gpt-4-turbo",
            messages: [
                Message(role: "system", content: "You are a professional meeting note summarizer."),
                Message(role: "user", content: prompt)
            ],
            stream: true,
            temperature: autonomy == .grounded ? 0.3 : 0.7
        )

        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (bytes, _) = try await URLSession.shared.bytes(for: urlRequest)

        for try await line in bytes.lines {
            guard line.hasPrefix("data: "), line != "data: [DONE]" else { continue }
            let jsonString = String(line.dropFirst(6))

            if let data = jsonString.data(using: .utf8),
               let response = try? JSONDecoder().decode(OpenAIStreamResponse.self, from: data),
               let content = response.choices.first?.delta.content {
                await MainActor.run {
                    summary += content
                }
            }
        }
    }
}

struct OpenAIRequest: Encodable {
    let model: String
    let messages: [Message]
    let stream: Bool
    let temperature: Double
}

struct Message: Encodable {
    let role: String
    let content: String
}

struct OpenAIStreamResponse: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }
        let delta: Delta
    }
    let choices: [Choice]
}

enum AutonomyLevel {
    case grounded
    case creative
}
```

#### 6. Calendar Integration (EventKit)

```swift
// Services/CalendarService.swift

import EventKit

class CalendarService: ObservableObject {
    @Published var events: [EKEvent] = []

    private let eventStore = EKEventStore()

    func requestAccess() async throws {
        if #available(macOS 14.0, *) {
            let granted = try await withCheckedThrowingContinuation { continuation in
                eventStore.requestFullAccessToEvents { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
            guard granted else { throw CalendarError.unauthorized }
        } else {
            let granted = try await withCheckedThrowingContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
            guard granted else { throw CalendarError.unauthorized }
        }
    }

    func fetchEvents(from startDate: Date, to endDate: Date) {
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)

        events = eventStore.events(matching: predicate)
    }

    func createEvent(title: String, startDate: Date, endDate: Date) throws {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = eventStore.defaultCalendarForNewEvents

        try eventStore.save(event, span: .thisEvent)
    }
}

/// Notes:
/// - Add `NSCalendarsUsageDescription` to Info.plist with a user-facing explanation of how MeetRec uses calendar data.
/// - For sandboxed macOS apps, enable the Calendars entitlement so EventKit can access people’s calendars.
```

#### 7. SwiftUI Audio Source Picker

```swift
// Views/Session/AudioSourcePicker.swift

import SwiftUI

struct AudioSourcePicker: View {
    @Binding var selectedSource: AudioSource
    @StateObject private var audioService: AudioService

    var body: some View {
        Menu {
            ForEach(AudioSource.allCases, id: \.self) { source in
                Button {
                    Task {
                        try? await audioService.setAudioSource(source)
                        selectedSource = source
                    }
                } label: {
                    HStack {
                        Text(source.rawValue)
                        if selectedSource == source {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: iconForSource(selectedSource))
                    .foregroundColor(.primary)
                Text(selectedSource.rawValue)
                    .font(.system(size: 13))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func iconForSource(_ source: AudioSource) -> String {
        switch source {
        case .micOnly:
            return "mic.fill"
        case .systemOnly:
            return "speaker.wave.2.fill"
        case .micAndSystem:
            return "mic.and.speaker.fill"
        }
    }
}

// Usage in Session Header
struct SessionHeaderView: View {
    @State private var audioSource: AudioSource = .micAndSystem
    @StateObject private var audioService = AudioService()

    var body: some View {
        HStack {
            Text("Session Title")
                .font(.headline)

            Spacer()

            AudioSourcePicker(selectedSource: $audioSource, audioService: audioService)

            Button("Start Listening") {
                Task {
                    try? await audioService.startRecording(source: audioSource)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

---

## Implementation Roadmap

### Phase 1: MVP (Weeks 1-6)

**Week 1-2: Core Setup**
- [ ] Create Xcode project with SwiftUI
- [ ] Set up Core Data schema
- [ ] Design basic UI layout (NSWindow, Sidebar, Tabs)
- [ ] Implement navigation structure
- [ ] Create app icon and assets

**Week 3-4: Audio & Transcription**
- [ ] Implement AVFoundation audio capture
- [ ] Add ScreenCaptureKit for system audio (macOS 12.3+)
- [ ] Implement audio source selection (Mic Only, System Only, Both)
- [ ] Build audio source picker UI component
- [ ] Add audio level monitoring for both sources independently
- [ ] Persist audio source preference in UserDefaults
- [ ] Integrate Speech Framework for local transcription
- [ ] Set up Deepgram WebSocket for cloud transcription
- [ ] Create session CRUD with Core Data
- [ ] Implement @Observable view models (macOS 14+) or ObservableObject (macOS 11-13)
- [ ] Build basic transcript display UI

**Week 5-6: Note-Taking & Export**
- [ ] Implement markdown editor (NSTextView or TextEditor)
- [ ] Build rich text editor for summaries
- [ ] Add PDF export functionality (PDFKit)
- [ ] Implement folder system
- [ ] Create search functionality (NSPredicate)

**Deliverable**: Functional meeting recorder with transcription and basic note-taking.

---

### Phase 2: AI & Intelligence (Weeks 7-10)

**Week 7-8: LLM Integration**
- [ ] Integrate OpenAI API with streaming
- [ ] Integrate Anthropic Claude API
- [ ] Build AI summarization service
- [ ] Create template system
- [ ] Implement autonomy selector UI
- [ ] Add auto-title generation

**Week 9-10: Advanced Features**
- [ ] Build AI chat interface (floating window)
- [ ] Create template library UI
- [ ] Implement custom vocabulary storage
- [ ] Add speaker diarization hints
- [ ] Build transcript editing mode
- [ ] Add word-level audio sync

**Deliverable**: Full AI-powered summarization and chat.

---

### Phase 3: Integrations (Weeks 11-14)

**Week 11-12: Calendar Integration**
- [ ] Integrate EventKit for Apple Calendar
- [ ] Add Google Calendar OAuth + API
- [ ] Add Microsoft Graph API for Outlook
- [ ] Build calendar view UI
- [ ] Implement event-session linking
- [ ] Add calendar sync service

**Week 13-14: Third-Party Apps**
- [ ] Implement Obsidian export (file system)
- [ ] Add Notion API integration
- [ ] Add Slack API integration
- [ ] Create export formats (Markdown, PDF)
- [ ] Build sharing functionality

**Deliverable**: Fully integrated with external services.

---

### Phase 4: Polish & Distribution (Weeks 15-18)

**Week 15-16: System Integration**
- [ ] Implement menu bar (NSStatusItem)
- [ ] Add launch at login (ServiceManagement)
- [ ] Create system notifications
- [ ] Add keyboard shortcuts
- [ ] Implement app permissions flow
- [ ] Add Spotlight integration

**Week 17-18: Distribution**
- [ ] Code signing with Apple Developer certificate
- [ ] Notarize app for Gatekeeper
- [ ] Create app installer (DMG)
- [ ] Set up auto-updates (Sparkle framework)
- [ ] Write documentation
- [ ] Submit to Mac App Store (optional)

**Deliverable**: Production-ready macOS app.

---

## Technical Considerations

### 1. macOS Version Support

| Feature | Minimum macOS | Recommended | Notes |
|---------|---------------|-------------|-------|
| **SwiftUI** | 10.15 (Catalina) | 14.0 (Sonoma) | Better APIs in newer versions |
| **@Observable macro** | 14.0 (Sonoma) | 14.0+ | Modern state management |
| **ScreenCaptureKit** | 12.3 (Monterey) | 13.0+ | System audio capture |
| **Speech Framework** | 10.15 (Catalina) | Latest | Offline transcription |
| **EventKit** | 10.8 | Latest | Calendar integration |

**Recommendation**: Target macOS 12.0+ for broader compatibility, use availability checks for newer APIs.

---

### 2. Performance Optimization

#### Audio Processing
- Use `AVAudioEngine` with buffer size 4096 for low latency
- Process audio on background queue (`DispatchQueue.global(qos: .userInitiated)`)
- Use `vDSP` from Accelerate for DSP operations (3-5x faster than naive Swift)
- Implement proper audio session management to avoid conflicts

#### Large Transcripts
- Use `NSFetchedResultsController` for automatic UI updates
- Implement batching with `fetchBatchSize` (50-100 items)
- Create indexes on `startMs` for timeline queries
- Use `NSPredicate` for efficient filtering
- Consider lazy loading for transcripts >10,000 words

#### Core Data Optimization
- Enable lightweight migration for schema changes
- Use background contexts for heavy operations
- Batch save operations (every 100 words)
- Create compound indexes for common queries:
  ```swift
  // session_id + start_ms for word lookups
  index = ["sessionId", "startMs"]
  ```

#### Memory Management
- Use `@autoreleasepool` for batch audio processing
- Implement proper `deinit` to stop audio engines
- Unregister observers in `deinit`
- Use weak references to avoid retain cycles

---

### 3. Security Best Practices

#### Sandboxing
- Enable App Sandbox in Xcode capabilities
- Request minimal entitlements:
  - `com.apple.security.device.audio-input`
  - `com.apple.security.device.camera` (for screen recording)
  - `com.apple.security.files.user-selected.read-write` (for exports)
- Use security-scoped bookmarks for persistent file access

#### API Keys & Credentials
- Store API keys in **Keychain**, never UserDefaults:
  ```swift
  let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: "openai_api_key",
      kSecValueData as String: apiKey.data(using: .utf8)!
  ]
  SecItemAdd(query as CFDictionary, nil)
  ```
- Use App Groups for sharing between main app and extensions
- Encrypt sensitive data with `CryptoKit`

#### Data Privacy
- Respect user's Transparency Consent & Control (TCC):
  - Microphone
  - Screen Recording
  - Accessibility
  - Calendar
- Implement data export (GDPR compliance)
- Provide clear privacy policy
- Don't collect telemetry without explicit consent

#### Code Signing & Notarization
- Enable Hardened Runtime
- Sign all executables and frameworks
- Notarize app for Gatekeeper
- Use secure timestamp server

---

### 4. macOS-Specific Features

#### Menu Bar Integration
```swift
class MenuBarController {
    private var statusItem: NSStatusItem?

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "MeetRec")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Start Recording", action: #selector(startRecording), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }
}
```

#### Launch at Login
```swift
import ServiceManagement

func setLaunchAtLogin(_ enabled: Bool) {
    if #available(macOS 13.0, *) {
        let appService = SMAppService.mainApp
        do {
            if enabled {
                try appService.register()
            } else {
                try appService.unregister()
            }
        } catch {
            // Handle registration error (for example, by surfacing it in the UI)
        }
    } else {
        // Use legacy login item APIs for macOS versions earlier than 13 if you need to support them.
    }
}
```

#### System Notifications
```swift
import UserNotifications

func requestNotificationPermission() async {
    let center = UNUserNotificationCenter.current()
    try? await center.requestAuthorization(options: [.alert, .sound, .badge])
}

func sendNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)
}
```

---

### 5. Distribution Strategy

#### Developer Account Requirements
- **Apple Developer Program**: $99/year
- Required for:
  - Code signing
  - Notarization
  - Mac App Store distribution
  - TestFlight beta testing

#### Distribution Options

**Option 1: Direct Download (DMG)**
- Host on your website
- Requires notarization
- Faster update cycles
- Keep 100% of revenue
- Use Sparkle for auto-updates

**Option 2: Mac App Store**
- Discoverability through App Store
- Apple handles payments (30% commission first year, 15% after)
- Sandboxing required (more restrictive)
- Slower review process
- No custom updater allowed

**Option 3: Setapp**
- Subscription app store
- Monthly revenue share
- Good discoverability
- No upfront cost for users

#### Recommended Approach
1. Start with direct download (DMG) for flexibility
2. Implement Sparkle for auto-updates
3. Consider Mac App Store once stable

---

### 6. Accessibility Best Practices

#### VoiceOver Support
```swift
// Label UI elements
Button("Start Recording") { }
    .accessibilityLabel("Start recording")
    .accessibilityHint("Begins audio capture and transcription")

// Group related elements
HStack {
    Text("Session")
    Text(session.title)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Session title: \(session.title)")
```

#### Keyboard Shortcuts
```swift
.keyboardShortcut("n", modifiers: [.command]) // Cmd+N for new session
.keyboardShortcut("r", modifiers: [.command, .shift]) // Cmd+Shift+R for record
```

#### Dynamic Type Support
```swift
Text("Session Title")
    .font(.title)
    .dynamicTypeSize(.medium ... .xxxLarge) // Support larger text
```

#### Color Contrast
- Use system colors (adapts to Dark Mode)
- Ensure 4.5:1 contrast ratio for text
- Don't rely solely on color for information

---

### 7. Testing Strategy

#### Unit Tests
```swift
import XCTest
@testable import MeetRec

class TranscriptionServiceTests: XCTestCase {
    func testWordTimestamps() {
        let word = Word(text: "Hello", startMs: 0, endMs: 500)
        XCTAssertEqual(word.duration, 500)
    }
}
```

#### UI Tests
```swift
class MeetRecUITests: XCTestCase {
    func testRecordingFlow() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Start Recording"].tap()
        XCTAssertTrue(app.staticTexts["Recording"].exists)

        app.buttons["Stop Recording"].tap()
        XCTAssertFalse(app.staticTexts["Recording"].exists)
    }
}
```

#### Performance Tests
```swift
func testTranscriptLoading() {
    measure {
        // Test loading 10,000 words
        let words = fetchWords(limit: 10000)
    }
}
```

---

## Conclusion

This document provides a comprehensive guide for building a native macOS version of MeetRec, covering:

- ✅ **All core features** with native macOS APIs
- ✅ **Complete UI/UX design** for macOS
- ✅ **Technical architecture** using Swift and SwiftUI
- ✅ **Core Data schemas** for persistence
- ✅ **Integration points** for macOS services
- ✅ **Implementation roadmap** with realistic timeline
- ✅ **Technical considerations** for performance, security, and distribution

**Key Takeaways**:

1. **Privacy-First**: Leverage macOS privacy features and local-first architecture
2. **Native Experience**: Use SwiftUI for modern UI, AppKit for advanced controls
3. **Performance**: AVFoundation + vDSP for efficient audio processing
4. **Distribution**: Start with DMG, consider Mac App Store later
5. **Accessibility**: VoiceOver, keyboard shortcuts, and Dynamic Type support

**Next Steps**:

1. Set up Xcode project with SwiftUI + Core Data
2. Implement Phase 1 MVP features (6 weeks)
3. Beta test with TestFlight
4. Gather feedback and iterate
5. Launch v1.0 via direct download (DMG)

This native macOS architecture leverages Apple's frameworks for optimal performance, seamless system integration, and exceptional user experience while maintaining privacy and offline capabilities.
