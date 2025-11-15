# Requirements Document

## Introduction

MeetRec is a native macOS application that provides local-first meeting recording, transcription, and AI-powered summarization. The system prioritizes user privacy by keeping all data on the user's device by default, with optional cloud provider integration. The application captures audio from multiple sources, transcribes speech in real-time, and generates intelligent summaries while maintaining full offline capability.

## Glossary

- **MeetRec System**: The complete macOS application including UI, audio capture, transcription, and AI services
- **Session**: A single meeting recording instance with associated audio, transcript, memos, and summary
- **Audio Source**: The input method for audio capture (microphone, system audio, or both)
- **Transcript**: Word-by-word text representation of recorded audio with timestamps
- **Memos**: User-written markdown notes taken during a session
- **Summary**: AI-generated enhanced notes based on memos and/or transcript
- **Template**: A predefined structure for organizing AI-generated summaries
- **Autonomy Level**: The degree of AI creativity (Grounded or Creative) when generating summaries
- **Calendar Event**: An external calendar entry that can be linked to a session
- **Folder**: A hierarchical organizational container for sessions
- **VAD**: Voice Activity Detection system that identifies when speech is occurring

## Requirements

### Requirement 1: Audio Capture and Recording

**User Story:** As a meeting participant, I want to record audio from my microphone and system audio, so that I can capture both my voice and other participants in video calls.

#### Acceptance Criteria

1. THE MeetRec System SHALL provide three audio source options: "Mic + System", "Mic Only", and "System Only"
2. WHEN the user selects an audio source, THE MeetRec System SHALL persist the selection across application sessions
3. WHEN recording is active, THE MeetRec System SHALL display real-time amplitude visualization for each active audio source independently
4. WHEN the user changes the audio source during recording, THE MeetRec System SHALL switch to the new source within 2 seconds without data loss
5. THE MeetRec System SHALL request microphone permission before accessing microphone input
6. WHERE system audio capture is selected, THE MeetRec System SHALL request screen recording permission on macOS 12.3 or later

### Requirement 2: Voice Activity Detection

**User Story:** As a user, I want the system to detect when speech is happening, so that unnecessary processing is reduced and battery life is preserved.

#### Acceptance Criteria

1. WHILE audio is being captured, THE MeetRec System SHALL analyze audio buffers for voice activity
2. WHEN voice activity is detected, THE MeetRec System SHALL forward audio data to the transcription service within 500 milliseconds
3. WHEN no voice activity is detected for 3 consecutive seconds, THE MeetRec System SHALL pause transcription processing
4. THE MeetRec System SHALL use the Silero-RS algorithm for voice activity detection

### Requirement 3: Real-Time Transcription

**User Story:** As a meeting participant, I want to see transcription appear in real-time as people speak, so that I can follow along and reference what was said.

#### Acceptance Criteria

1. THE MeetRec System SHALL support both local transcription models and cloud transcription providers
2. WHEN using local transcription, THE MeetRec System SHALL process audio on-device without internet connectivity
3. WHEN transcription is active, THE MeetRec System SHALL display new words within 2 seconds of speech completion
4. THE MeetRec System SHALL assign start and end timestamps in milliseconds to each transcribed word
5. WHERE speaker diarization is available, THE MeetRec System SHALL assign speaker identifiers to transcribed words
6. THE MeetRec System SHALL allow users to edit transcribed text after generation

### Requirement 4: Session Management

**User Story:** As a user, I want to create, organize, and manage my meeting sessions, so that I can keep my recordings organized and easily accessible.

#### Acceptance Criteria

1. WHEN the user initiates recording, THE MeetRec System SHALL create a new session with a unique identifier
2. THE MeetRec System SHALL store session metadata including title, start time, end time, and folder location
3. THE MeetRec System SHALL allow users to assign sessions to hierarchical folders
4. THE MeetRec System SHALL allow users to add multiple tags to each session
5. THE MeetRec System SHALL provide search functionality across session titles, memos, transcripts, and summaries
6. WHEN the user deletes a session, THE MeetRec System SHALL permanently remove all associated data including audio files

### Requirement 5: Note-Taking Interface

**User Story:** As a meeting participant, I want to take quick notes during the meeting, so that I can capture important points and action items in my own words.

#### Acceptance Criteria

1. THE MeetRec System SHALL provide a markdown editor for user-written memos
2. WHILE the user is editing memos, THE MeetRec System SHALL auto-save changes every 2 seconds
3. THE MeetRec System SHALL support markdown formatting including bold, italic, lists, and headings
4. THE MeetRec System SHALL display a word count indicator for the memos content
5. THE MeetRec System SHALL maintain three synchronized views: Memos, Transcript, and Summary

### Requirement 6: AI-Powered Summarization

**User Story:** As a user, I want AI to generate polished summaries from my raw notes and transcripts, so that I can share professional meeting documentation without manual formatting.

#### Acceptance Criteria

1. THE MeetRec System SHALL support multiple LLM providers including OpenAI, Anthropic, OpenRouter, and local models
2. WHEN the user requests summary generation, THE MeetRec System SHALL use the selected autonomy level to determine input sources
3. WHEN autonomy level is "Grounded", THE MeetRec System SHALL generate summaries using only the memos content
4. WHEN autonomy level is "Creative", THE MeetRec System SHALL generate summaries using both memos and full transcript
5. THE MeetRec System SHALL support template-based summary generation with predefined sections
6. WHEN generating summaries, THE MeetRec System SHALL stream results to the UI as they are produced
7. THE MeetRec System SHALL allow users to regenerate summaries with different templates or autonomy levels

### Requirement 7: Calendar Integration

**User Story:** As a user, I want to connect my calendars and link sessions to calendar events, so that I can automatically associate recordings with scheduled meetings.

#### Acceptance Criteria

1. THE MeetRec System SHALL support Apple Calendar, Google Calendar, and Microsoft Outlook Calendar
2. WHEN the user connects a calendar provider, THE MeetRec System SHALL use OAuth authentication for Google and Microsoft
3. THE MeetRec System SHALL sync calendar events every 15 minutes using incremental sync tokens
4. THE MeetRec System SHALL allow users to link a session to a calendar event
5. WHEN a session is linked to an event, THE MeetRec System SHALL display event metadata including title, participants, and meeting link
6. THE MeetRec System SHALL allow users to enable or disable individual calendars within a connected provider

### Requirement 8: Data Persistence

**User Story:** As a user, I want all my session data to be saved locally and reliably, so that I never lose my meeting recordings and notes.

#### Acceptance Criteria

1. THE MeetRec System SHALL use Core Data for persistent storage of sessions, transcripts, and metadata
2. THE MeetRec System SHALL store word-level transcript data with timestamps in the database
3. THE MeetRec System SHALL optionally save audio files to local storage based on user preference
4. WHEN the application terminates unexpectedly, THE MeetRec System SHALL recover in-progress sessions on next launch
5. THE MeetRec System SHALL support database migration for schema updates without data loss
6. THE MeetRec System SHALL encrypt sensitive data including API keys using macOS Keychain

### Requirement 9: Export and Sharing

**User Story:** As a user, I want to export my session summaries in various formats, so that I can share them with colleagues or import them into other tools.

#### Acceptance Criteria

1. THE MeetRec System SHALL support export to Markdown, PDF, and JSON formats
2. WHEN exporting to PDF, THE MeetRec System SHALL apply formatting and preserve document structure
3. THE MeetRec System SHALL support export to Obsidian vaults via file system integration
4. THE MeetRec System SHALL allow users to copy session content to clipboard
5. THE MeetRec System SHALL include session metadata in exported files

### Requirement 10: User Interface and Navigation

**User Story:** As a user, I want an intuitive interface with easy navigation between sessions, so that I can efficiently manage multiple meetings.

#### Acceptance Criteria

1. THE MeetRec System SHALL display a sidebar with timeline view showing sessions and events grouped by date
2. THE MeetRec System SHALL support browser-style tabs for opening multiple sessions simultaneously
3. WHEN the user opens a session, THE MeetRec System SHALL display it in a new tab or switch to an existing tab
4. THE MeetRec System SHALL provide keyboard shortcuts for common actions including new session, search, and tab navigation
5. THE MeetRec System SHALL display recording status with visual indicators including red dot for active recording
6. THE MeetRec System SHALL auto-scroll the timeline to the current time on application launch

### Requirement 11: Settings and Configuration

**User Story:** As a user, I want to configure the application settings including AI providers and preferences, so that I can customize the app to my workflow.

#### Acceptance Criteria

1. THE MeetRec System SHALL provide a settings panel with tabs for General, AI, Calendar, Integrations, Templates, Memory, Notifications, and Account
2. THE MeetRec System SHALL allow users to configure transcription provider, model, and API credentials
3. THE MeetRec System SHALL allow users to configure LLM provider, model, and API credentials
4. THE MeetRec System SHALL test API connections and display connection status
5. THE MeetRec System SHALL store API keys securely in macOS Keychain
6. THE MeetRec System SHALL allow users to set default audio source preference
7. THE MeetRec System SHALL allow users to enable or disable auto-start at login

### Requirement 12: Permissions and Privacy

**User Story:** As a user, I want clear permission requests and control over my data, so that I understand what the app accesses and maintain my privacy.

#### Acceptance Criteria

1. THE MeetRec System SHALL request microphone access before first use with clear usage description
2. WHERE system audio capture is needed, THE MeetRec System SHALL request screen recording permission with clear usage description
3. WHERE calendar integration is enabled, THE MeetRec System SHALL request calendar access with clear usage description
4. THE MeetRec System SHALL display permission status in settings with options to grant access
5. THE MeetRec System SHALL process all data locally by default without cloud transmission
6. THE MeetRec System SHALL only transmit data to cloud providers when explicitly configured by the user

### Requirement 13: Template System

**User Story:** As a user, I want to use and create templates for different meeting types, so that my summaries follow consistent structures.

#### Acceptance Criteria

1. THE MeetRec System SHALL provide built-in templates for common meeting types including 1:1, standup, sales call, and retrospective
2. THE MeetRec System SHALL allow users to create custom templates with defined sections
3. WHEN creating a template, THE MeetRec System SHALL allow users to specify target content sources (memos, transcript, or both)
4. THE MeetRec System SHALL store templates locally in the database
5. THE MeetRec System SHALL allow users to select a template when generating summaries

### Requirement 14: Audio Timeline and Playback

**User Story:** As a user, I want to play back recorded audio and jump to specific moments, so that I can review what was said at any point in the meeting.

#### Acceptance Criteria

1. WHERE audio recording is enabled, THE MeetRec System SHALL display an audio timeline with playback controls
2. THE MeetRec System SHALL allow users to play, pause, and seek through recorded audio
3. WHEN the user clicks a word in the transcript, THE MeetRec System SHALL seek audio playback to that word's timestamp
4. THE MeetRec System SHALL display current playback position and total duration
5. THE MeetRec System SHALL support keyboard shortcuts for play/pause and seeking

### Requirement 15: Onboarding Experience

**User Story:** As a new user, I want a guided setup process, so that I can quickly configure permissions and start using the app.

#### Acceptance Criteria

1. WHEN the application launches for the first time, THE MeetRec System SHALL display an onboarding flow
2. THE MeetRec System SHALL guide users through granting microphone, screen recording, and accessibility permissions
3. THE MeetRec System SHALL offer optional calendar connection during onboarding
4. THE MeetRec System SHALL allow users to skip optional onboarding steps
5. WHEN onboarding is complete, THE MeetRec System SHALL display the main application interface
