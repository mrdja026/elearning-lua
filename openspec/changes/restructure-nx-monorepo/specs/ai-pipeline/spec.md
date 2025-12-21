# ai-pipeline Spec Delta

## MODIFIED Requirements

### Requirement: Image Download

The system SHALL download generated images from remote URLs and save them locally using the platform-appropriate storage mechanism.

#### Scenario: Download after generation
- **WHEN** image generation succeeds and returns an imageUrl
- **THEN** the download SHALL be handled by the platform:
  - Web mode (Love.js): React downloads the image and stores it
  - Native mode: Lua HTTP library downloads to love.filesystem

#### Scenario: Save to local storage
- **WHEN** image binary data is downloaded successfully
- **THEN** the system SHALL save it:
  - Web mode: React saves via Tauri fs API to app data directory
  - Native mode: Lua saves to `love.filesystem.getSaveDirectory()/images/`

#### Scenario: Return local path
- **WHEN** the image is saved locally
- **THEN** the bridge response SHALL contain the local file path or URL for display

#### Scenario: Directory creation
- **WHEN** the images directory does not exist
- **THEN** the system SHALL create it before saving

#### Scenario: Download failure
- **WHEN** image download fails (network error, invalid URL)
- **THEN** the system SHALL return an error response with message describing the failure

## ADDED Requirements

### Requirement: React Image Handler

The system SHALL handle image downloads in React when running in web mode (Tauri app).

#### Scenario: Receive image generation request
- **WHEN** the game sends a REQUEST_IMAGE_GENERATION message
- **THEN** React SHALL call the Hono backend `/api/generate-image` endpoint

#### Scenario: Download and store image
- **WHEN** the backend returns a successful response with imageUrl
- **THEN** React SHALL download the image and save it using Tauri fs API

#### Scenario: Return image to game
- **WHEN** the image is saved successfully
- **THEN** React SHALL send an IMAGE_GENERATED message with the image path to the game

#### Scenario: Handle generation error
- **WHEN** image generation or download fails
- **THEN** React SHALL send an IMAGE_ERROR message with the error description to the game
