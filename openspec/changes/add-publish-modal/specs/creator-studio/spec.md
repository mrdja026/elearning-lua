## ADDED Requirements

### Requirement: Publish Modal

The Creator Studio SHALL provide a modal dialog for publishing stories to the marketplace.

#### Scenario: Open publish modal
- **WHEN** the user clicks the "Publish" button in Creator Studio
- **THEN** a centered modal overlay SHALL appear with a dimmed background

#### Scenario: Modal content
- **WHEN** the publish modal is open
- **THEN** it SHALL display:
  - A title input field pre-filled with the story title
  - Story summary (page count, question count)
  - A "Cancel" button
  - A "Publish" button

#### Scenario: Cancel publish
- **WHEN** the user clicks "Cancel" or clicks outside the modal
- **THEN** the modal SHALL close without publishing

#### Scenario: Publish story
- **WHEN** the user clicks "Publish" with valid input
- **THEN** the system SHALL send the story to `POST /api/stories`
- **AND** display a loading indicator

#### Scenario: Publish success
- **WHEN** the API returns success
- **THEN** the modal SHALL display a success message
- **AND** close automatically after 2 seconds (or on user dismiss)

#### Scenario: Publish error
- **WHEN** the API returns an error
- **THEN** the modal SHALL display the error message
- **AND** allow the user to retry or cancel

#### Scenario: Keyboard navigation
- **WHEN** the modal is open
- **THEN** pressing Escape SHALL close the modal

### Requirement: Publish Button

The Creator Studio SHALL provide a button to trigger the publish flow.

#### Scenario: Button placement
- **WHEN** the Creator Studio is displayed
- **THEN** a "Publish" button SHALL be visible in the toolbar area

#### Scenario: Button state
- **WHEN** the story has no pages
- **THEN** the Publish button SHALL be disabled with a tooltip "Add pages first"

### Requirement: HTTP Client

The game SHALL include an HTTP client for API communication.

#### Scenario: POST request
- **WHEN** publishing a story
- **THEN** the HTTP client SHALL send a POST request with JSON body to the backend

#### Scenario: DEV_MODE requests
- **WHEN** DEV_MODE is enabled in the backend
- **THEN** requests SHALL succeed without authentication

#### Scenario: Network error
- **WHEN** the network request fails
- **THEN** the HTTP client SHALL return an error that can be displayed to the user
