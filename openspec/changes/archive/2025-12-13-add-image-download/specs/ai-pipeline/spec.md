## ADDED Requirements

### Requirement: Image Download

The system SHALL download generated images from remote URLs and save them locally.

#### Scenario: Download after generation
- **WHEN** the backend returns a successful response with imageUrl
- **THEN** the image thread SHALL download the image binary data from that URL

#### Scenario: Save to local storage
- **WHEN** image binary data is downloaded successfully
- **THEN** the system SHALL save it to `love.filesystem.getSaveDirectory()/images/` with a unique filename

#### Scenario: Return local path
- **WHEN** the image is saved locally
- **THEN** the thread response SHALL contain the local file path instead of the remote URL

#### Scenario: Directory creation
- **WHEN** the images directory does not exist
- **THEN** the system SHALL create it before saving

#### Scenario: Download failure
- **WHEN** image download fails (network error, invalid URL)
- **THEN** the system SHALL return an error response with message describing the failure
