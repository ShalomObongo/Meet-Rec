# Repository Guidelines

## Project Structure & Modules
- App source lives in `MeetRec` (SwiftUI app, Core Data, audio services).
- Unit tests live in `MeetRecTests`; UI tests in `MeetRecUITests`.
- Documentation and design notes are in `docs/` (e.g. transcription and microphone behavior).

## Build, Run & Test
- Open in Xcode with `open MeetRec.xcodeproj` and use the MeetRec scheme.
- Run the macOS app from Xcode (`⌘R`) for local development.
- Run unit tests via Xcode (`⌘U`) targeting `MeetRecTests`.
- Run UI tests by selecting the `MeetRecUITests` target and running the test suite.

## Coding Style & Naming
- Swift code uses 4-space indentation and standard Swift API design guidelines.
- Prefer `struct` for value types and `final class` for reference types like services.
- Name files after their primary type (e.g. `AudioService.swift`, `SessionView.swift`).
- Group code by feature: app shell and state in `MeetRec`, audio logic in `MeetRec/Audio`, views in `MeetRec/Views` and `MeetRec/ViewModels`.

## Testing Guidelines
- Use the Swift `Testing` framework in `MeetRecTests` for unit tests and `XCTest` in `MeetRecUITests` for UI tests.
- Name tests descriptively (e.g. `testTranscriptionHandlesPauses()`).
- Aim to cover new branches in audio, transcription, and Core Data behaviors when adding features.

## Commit & Pull Request Guidelines
- Follow the existing Conventional Commit style: `feat(meetrec): ...`, `chore(mcp): ...`.
- Keep commits focused and descriptive; reference related docs in `docs/` when relevant.
- PRs should include: a short summary, screenshots or notes for UI changes, and links to any related issues or tracking documents.

## Security & Configuration
- Do not commit secrets or API keys; keep configuration in local Xcode schemes or environment files.
- Be mindful of microphone and audio permissions—ensure changes still respect platform privacy prompts and documented flows in `docs/`.

