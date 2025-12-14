## ADDED Requirements

### Requirement: Image Description Field

The system SHALL provide a text input for describing the desired image.

#### Scenario: Description input
- **WHEN** editing a page in Creator Studio
- **THEN** an "Image Description" text field SHALL be available

#### Scenario: Description storage
- **WHEN** the user enters an image description
- **THEN** it SHALL be stored in the page data as `image_description`

### Requirement: Image Generation Button

The system SHALL provide explicit control for generating images.

#### Scenario: Generate button
- **WHEN** viewing the Page Editor
- **THEN** a "Generate Image" button SHALL be displayed next to the image section

#### Scenario: Button triggers generation
- **WHEN** the user clicks "Generate Image"
- **THEN** the system SHALL send description and question_text to the backend

### Requirement: Async Image Generation

The system SHALL generate images without blocking the UI.

#### Scenario: Non-blocking request
- **WHEN** image generation is triggered
- **THEN** the request SHALL run in a separate thread using love.thread

#### Scenario: Loading indicator
- **WHEN** generation is in progress
- **THEN** a loading spinner SHALL be displayed in the preview panel

#### Scenario: Generation complete
- **WHEN** the backend returns successfully
- **THEN** the page's image_path SHALL be updated with the returned URL

### Requirement: Error Handling

The system SHALL display user-friendly error messages for generation failures.

#### Scenario: Service error display
- **WHEN** image generation fails
- **THEN** the system SHALL display "Service not available, check usage and keys"

#### Scenario: Error dismissal
- **WHEN** an error is displayed
- **THEN** the user SHALL be able to dismiss it and retry

### Requirement: Preview Hot Reload

The system SHALL update the preview when a new image is generated.

#### Scenario: Image hot reload
- **WHEN** a new image URL is received
- **THEN** the preview panel SHALL reload to display the new image
