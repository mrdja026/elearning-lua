# creator-studio Spec Delta

## ADDED Requirements

### Requirement: AI Story Wizard

The system SHALL provide a modal wizard for AI-powered story generation that mirrors the `e2eADKFlow.sh` interactive flow.

#### Scenario: Wizard auto-open on empty story
- **WHEN** the editor initializes with a default empty story
- **AND** the story has only 1 page with default question text
- **THEN** the AI Story Wizard modal SHALL open automatically

#### Scenario: 6-step wizard flow
- **WHEN** the wizard is open
- **THEN** it SHALL guide the user through 6 steps: Topic, Art Style, Target Age, Page Count, Page Hints, Review

#### Scenario: Step 1 - Topic input
- **WHEN** the user is on Step 1
- **THEN** they SHALL enter a topic with minimum 3 characters
- **AND** the Next button SHALL be disabled until valid

#### Scenario: Step 2 - Art style selection
- **WHEN** the user is on Step 2
- **THEN** they SHALL select from: pixel, fantasy, cartoon

#### Scenario: Step 3 - Target age selection
- **WHEN** the user is on Step 3
- **THEN** they SHALL select from: 5-8, 8-12, 13-17, 18+, all

#### Scenario: Step 4 - Page count
- **WHEN** the user is on Step 4
- **THEN** they SHALL enter a page count between 1-5
- **AND** the default SHALL be 3

#### Scenario: Step 5 - Page hints
- **WHEN** the user is on Step 5
- **THEN** they SHALL see one text input per page
- **AND** hints MAY be left empty (fallback to generic prompts)

#### Scenario: Step 6 - Review and confirm
- **WHEN** the user is on Step 6
- **THEN** a summary of all inputs SHALL be displayed
- **AND** a "Generate Story" button SHALL initiate generation

#### Scenario: Back navigation
- **WHEN** the user clicks Back on any step
- **THEN** the wizard SHALL return to the previous step
- **EXCEPT** Back SHALL be disabled on Step 1

### Requirement: Wizard Generation Phase

The system SHALL show a non-cancelable generation overlay with progress and entertaining messages.

#### Scenario: Non-cancelable during generation
- **WHEN** story generation is in progress
- **THEN** the wizard SHALL NOT allow back navigation or closing
- **AND** no cancel button SHALL be available

#### Scenario: Progress phases
- **WHEN** generation is in progress
- **THEN** the current phase SHALL be displayed: "Starting session", "Enhancing prompt", "Generating cover", "Generating pages (X/Y)"

#### Scenario: Absurd life advice messages
- **WHEN** generation is in progress
- **THEN** a funny life advice message SHALL be displayed prominently
- **AND** the message SHALL rotate every 3 seconds

#### Scenario: Generation completion
- **WHEN** generation completes successfully
- **THEN** the wizard SHALL close
- **AND** the generated story SHALL load into the editor
- **AND** a success message SHALL be shown

#### Scenario: Generation error
- **WHEN** generation fails at any phase
- **THEN** an error message SHALL be displayed
- **AND** the user SHALL be able to retry or close the wizard

### Requirement: Wizard HTTP Thread

The system SHALL use a dedicated thread for wizard API calls to prevent UI freezing.

#### Scenario: Threaded API calls
- **WHEN** the wizard initiates generation
- **THEN** all HTTP requests SHALL run in `wizard_thread.lua`
- **AND** the main thread SHALL poll for responses via channels

#### Scenario: Sequential API flow
- **WHEN** generation starts
- **THEN** the thread SHALL call endpoints in order:
  1. `POST /api/flow-test/start`
  2. `POST /api/flow-test/confirm`
  3. `POST /api/flow-test/generate-cover`
  4. `POST /api/flow-test/generate-pages`

#### Scenario: Image download
- **WHEN** API returns Cloudinary image URLs
- **THEN** the thread SHALL download each image
- **AND** save them to local `images/` directory
- **AND** update story paths to use local files
