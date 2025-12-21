# creator-studio Spec Delta

## MODIFIED Requirements

### Requirement: Async Image Generation

The system SHALL generate images without blocking the UI using the platform-appropriate async mechanism.

#### Scenario: Non-blocking request
- **WHEN** image generation is triggered
- **THEN** the request SHALL be handled asynchronously:
  - In web mode (Love.js): via `bridge.requestImageGeneration()` which sends postMessage to React
  - In native mode: via `bridge.requestImageGeneration()` with HTTP fallback

#### Scenario: Loading indicator
- **WHEN** generation is in progress
- **THEN** a loading spinner SHALL be displayed in the preview panel

#### Scenario: Generation complete
- **WHEN** the bridge callback returns successfully
- **THEN** the page's image_path SHALL be updated with the returned image URL or local path

## ADDED Requirements

### Requirement: Bridge Module Integration

The system SHALL use the bridge module for all async I/O operations to support both web (Love.js) and native (Love2D) environments.

#### Scenario: Bridge initialization
- **WHEN** the game starts in web mode
- **THEN** `bridge.init()` SHALL be called to set up postMessage listeners

#### Scenario: Native mode fallback
- **WHEN** the game starts in native mode (detected via `love.system.getOS()`)
- **THEN** bridge operations SHALL use direct HTTP requests instead of postMessage

#### Scenario: Request ID tracking
- **WHEN** an async request is made via the bridge
- **THEN** it SHALL include a unique requestId for matching responses to callbacks

### Requirement: Speech-to-Text Answer Input (LOW PRIORITY - Phase 2)

The system SHALL support voice input for answer questions via the React bridge. This feature is deferred until the core app port is complete.

#### Scenario: Voice input button
- **WHEN** Play mode displays a text answer input
- **THEN** a microphone button SHALL be displayed next to the input field

#### Scenario: Request speech transcription
- **WHEN** the user activates voice input
- **THEN** the game SHALL call `bridge.requestSpeechToText()` to request transcription from React

#### Scenario: Receive transcription
- **WHEN** React returns a speech transcription
- **THEN** the text SHALL be populated in the answer input field

#### Scenario: Voice input unavailable
- **WHEN** speech recognition is not available (native mode or unsupported browser)
- **THEN** the microphone button SHALL be hidden or disabled
