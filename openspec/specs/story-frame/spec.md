# story-frame Specification

## Purpose
TBD - created by archiving change add-story-frame. Update Purpose after archive.
## Requirements
### Requirement: Story Frame Display

The system SHALL display a Story Frame intro screen before Page 1 in Play mode when the story has a cover image.

#### Scenario: Story with cover image enters play mode
- **WHEN** a story with `cover_image_path` set to a valid path enters Play mode
- **THEN** the Story Frame screen SHALL be displayed first
- **AND** the cover image SHALL be centered on screen
- **AND** the story title SHALL be displayed
- **AND** the story topic/description SHALL be displayed
- **AND** a "Tap anywhere to start" prompt SHALL be shown

#### Scenario: Story without cover image enters play mode
- **WHEN** a story with empty `cover_image_path` enters Play mode
- **THEN** Play mode SHALL go directly to Page 1
- **AND** no Story Frame SHALL be shown

### Requirement: Story Frame Dismissal

The system SHALL allow users to dismiss the Story Frame and proceed to Page 1.

#### Scenario: Dismiss with mouse click
- **WHEN** the Story Frame is displayed and user clicks anywhere
- **THEN** the Story Frame SHALL be dismissed
- **AND** Page 1 SHALL be displayed

#### Scenario: Dismiss with keyboard
- **WHEN** the Story Frame is displayed and user presses any key (except Tab)
- **THEN** the Story Frame SHALL be dismissed
- **AND** Page 1 SHALL be displayed

### Requirement: Cover Image Generation

The system SHALL allow users to generate a cover image from the story prompt in Story Settings.

#### Scenario: Generate cover from story prompt
- **WHEN** user has entered a story image prompt and clicks "Generate Cover"
- **THEN** a cover image SHALL be generated
- **AND** `story.cover_image_path` SHALL be set to the generated image path
- **AND** `story.general_image_prompt` SHALL be cleared
- **AND** a success message SHALL be shown

### Requirement: Pages Panel Gating

The system SHALL disable the Pages panel until a cover image is generated for new stories.

#### Scenario: New story without cover
- **WHEN** a new story has no cover image
- **THEN** the Pages panel SHALL be disabled/grayed out
- **AND** a message "Generate cover first" SHALL be displayed
- **AND** Add/Remove page buttons SHALL be disabled

#### Scenario: Story with cover
- **WHEN** a story has a cover image generated
- **THEN** the Pages panel SHALL be fully functional
- **AND** the user SHALL be able to add, edit, and remove pages

### Requirement: Story Settings Default State

The system SHALL expand Story Settings by default for new stories.

#### Scenario: New story created
- **WHEN** the user creates a new story
- **THEN** Story Settings panel SHALL be expanded
- **AND** the user SHALL be able to immediately fill in title, topic, and prompt

### Requirement: Backwards Compatibility

The system SHALL handle old stories without cover_image_path by requiring cover generation before editing.

#### Scenario: Load old story without cover field
- **WHEN** an old story JSON without `cover_image_path` field is loaded
- **THEN** `cover_image_path` SHALL default to empty string
- **AND** the Pages panel SHALL be disabled until cover is generated
- **AND** Story Settings SHALL be expanded automatically
- **AND** a message "Generate cover to edit pages" SHALL be displayed

