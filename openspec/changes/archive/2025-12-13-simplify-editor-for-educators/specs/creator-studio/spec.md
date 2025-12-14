# creator-studio Spec Delta

## ADDED Requirements

### Requirement: Story-Level Settings

The system SHALL provide story-level configuration fields for topic and image generation.

#### Scenario: Topic field
- **WHEN** editing a story in Creator Studio
- **THEN** a "Topic" text input field SHALL be displayed in the Story Settings panel

#### Scenario: General image prompt field
- **WHEN** editing a story in Creator Studio
- **THEN** a "General Image Prompt" text area SHALL be displayed in the Story Settings panel

#### Scenario: Topic storage
- **WHEN** the user enters a topic
- **THEN** it SHALL be stored in the story data as `topic`

#### Scenario: Image prompt storage
- **WHEN** the user enters a general image prompt
- **THEN** it SHALL be stored in the story data as `general_image_prompt`

### Requirement: Yes/No Question Editor

The system SHALL provide a simplified yes/no question type with checkbox-based correct answer selection.

#### Scenario: Yesno checkbox
- **WHEN** question_type is "yesno"
- **THEN** a checkbox labeled "Correct answer is Yes" SHALL be displayed

#### Scenario: Checkbox checked state
- **WHEN** the checkbox is checked
- **THEN** `correct_answer_is_yes` SHALL be true (Yes is the correct answer)

#### Scenario: Checkbox unchecked state
- **WHEN** the checkbox is unchecked
- **THEN** `correct_answer_is_yes` SHALL be false (No is the correct answer)

#### Scenario: Yesno button labels
- **WHEN** question_type is "yesno"
- **THEN** input fields for customizing "Yes" and "No" button labels SHALL be displayed

### Requirement: Story-Level Image Generation

The system SHALL use the story-level image prompt for all page image generation.

#### Scenario: Generate with story prompt
- **WHEN** the user clicks "Generate Image" on a page
- **THEN** the system SHALL use `general_image_prompt` combined with `question_text`

#### Scenario: Prompt required warning
- **WHEN** `general_image_prompt` is empty AND user clicks "Generate Image"
- **THEN** a warning message SHALL indicate the user must set the story-level prompt first

### Requirement: Linear Navigation Display

The system SHALL display simplified navigation information.

#### Scenario: Navigation info text
- **WHEN** editing a page
- **THEN** static text SHALL indicate "Navigation: Linear (correct = next page, wrong = retry)"

#### Scenario: No destination dropdowns
- **WHEN** editing a page
- **THEN** true_destination_id and false_destination_id dropdowns SHALL NOT be displayed

## MODIFIED Requirements

### Requirement: Story Editor

The system SHALL provide UI controls for editing all story and page properties including question type configuration.

#### Scenario: Edit story title
- **WHEN** the user modifies the story title input field
- **THEN** the story title SHALL be updated in editor state

#### Scenario: Edit question text
- **WHEN** the user modifies the question text input
- **THEN** the current page question_text SHALL be updated

#### Scenario: Edit hint text
- **WHEN** the user modifies the hint text input
- **THEN** the current page hint_text SHALL be updated

#### Scenario: Edit image path
- **WHEN** the user modifies the image path input
- **THEN** the current page image_path SHALL be updated

#### Scenario: Edit choice labels
- **WHEN** the user modifies choice label inputs AND question_type is "yesno"
- **THEN** the current page choice_labels SHALL be updated

#### Scenario: Select question type
- **WHEN** the user selects a question type from the dropdown
- **THEN** the current page question_type SHALL be updated and relevant UI fields SHALL be shown/hidden

### Requirement: Question Type Selection

The system SHALL provide a dropdown to select between yesno, text, and multi question types.

#### Scenario: Question type dropdown
- **WHEN** Create mode is active
- **THEN** a dropdown SHALL display options: "Yes/No Question", "Text Answer", "Multi-Question"

#### Scenario: Default question type
- **WHEN** a new page is created
- **THEN** question_type SHALL default to "yesno"

#### Scenario: UI adaptation for yesno
- **WHEN** question_type is "yesno"
- **THEN** the editor SHALL show correct_answer_is_yes checkbox and choice_labels fields

#### Scenario: UI adaptation for text
- **WHEN** question_type is "text"
- **THEN** the editor SHALL show correct_answer field

#### Scenario: UI adaptation for multi
- **WHEN** question_type is "multi"
- **THEN** the editor SHALL show multi-question list editor

## REMOVED Requirements

### Requirement: Image Description Field

This requirement is REMOVED. Per-page image descriptions are replaced by story-level `general_image_prompt`.

#### Scenario: Description input
- REMOVED: Per-page "Image Description" field is no longer available

#### Scenario: Description storage
- REMOVED: `image_description` is no longer stored per-page
