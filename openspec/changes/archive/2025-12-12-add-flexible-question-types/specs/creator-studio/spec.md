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

#### Scenario: Configure logic operator
- **WHEN** the user selects an operator from the dropdown AND question_type is "binary"
- **THEN** the current page operator SHALL be updated with the selected value

#### Scenario: Configure variable
- **WHEN** the user modifies variable_name or variable_value inputs
- **THEN** the current page variable settings SHALL be updated

#### Scenario: Configure target value
- **WHEN** the user modifies the target_value input
- **THEN** the current page target_value SHALL be updated

#### Scenario: Configure destinations
- **WHEN** the user selects true_destination_id or false_destination_id from dropdowns
- **THEN** the current page navigation settings SHALL be updated

#### Scenario: Edit choice labels
- **WHEN** the user modifies choice label inputs AND question_type is "binary"
- **THEN** the current page choice_labels SHALL be updated

#### Scenario: Select question type
- **WHEN** the user selects a question type from the dropdown
- **THEN** the current page question_type SHALL be updated and relevant UI fields SHALL be shown/hidden

## ADDED Requirements

### Requirement: Question Type Selection

The system SHALL provide a dropdown to select between binary, text, and multi question types.

#### Scenario: Question type dropdown
- **WHEN** Create mode is active
- **THEN** a dropdown SHALL display options: "Binary (True/False)", "Text Answer", "Multi-Question"

#### Scenario: Default question type
- **WHEN** a new page is created
- **THEN** question_type SHALL default to "binary"

#### Scenario: UI adaptation for binary
- **WHEN** question_type is "binary"
- **THEN** the editor SHALL show operator, target_value, and choice_labels fields

#### Scenario: UI adaptation for text
- **WHEN** question_type is "text"
- **THEN** the editor SHALL show correct_answer field and hide operator/choice_labels

#### Scenario: UI adaptation for multi
- **WHEN** question_type is "multi"
- **THEN** the editor SHALL show multi-question list editor

### Requirement: Text Answer Editor

The system SHALL provide UI for configuring text answer questions.

#### Scenario: Correct answer input
- **WHEN** question_type is "text"
- **THEN** an input field for correct_answer SHALL be displayed

#### Scenario: Update correct answer
- **WHEN** the user modifies the correct answer input
- **THEN** the current page correct_answer SHALL be updated

### Requirement: Multi-Question Editor

The system SHALL provide UI for configuring multi-question pages.

#### Scenario: Question list display
- **WHEN** question_type is "multi"
- **THEN** a list of sub-questions SHALL be displayed with their question_text and correct_answer

#### Scenario: Add sub-question
- **WHEN** the user clicks Add Question button in multi-question mode
- **THEN** a new sub-question with empty fields SHALL be added to the questions array

#### Scenario: Remove sub-question
- **WHEN** the user clicks Remove on a sub-question
- **THEN** that sub-question SHALL be removed from the questions array

#### Scenario: Edit sub-question text
- **WHEN** the user modifies a sub-question's question_text input
- **THEN** that sub-question's question_text SHALL be updated

#### Scenario: Edit sub-question answer
- **WHEN** the user modifies a sub-question's correct_answer input
- **THEN** that sub-question's correct_answer SHALL be updated

### Requirement: Question Type Preview

The system SHALL preview different question types appropriately.

#### Scenario: Preview text question
- **WHEN** question_type is "text" AND preview is active
- **THEN** the preview SHALL show a text input field instead of choice buttons

#### Scenario: Preview multi-question
- **WHEN** question_type is "multi" AND preview is active
- **THEN** the preview SHALL show all sub-questions with their input fields

#### Scenario: Preview error feedback
- **WHEN** question_type is "multi" AND Test Play mode has errors
- **THEN** the preview SHALL highlight incorrect answers and show expected values
