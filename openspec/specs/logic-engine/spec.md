# logic-engine Specification

## Purpose
TBD - created by archiving change add-logic-engine. Update Purpose after archive.
## Requirements
### Requirement: Story Schema

The system SHALL define a Page schema with simplified fields.

#### Scenario: Valid page structure
- **WHEN** a story JSON is loaded
- **THEN** each page MUST contain at minimum: id, question_text

#### Scenario: Optional fields have defaults
- **WHEN** a page is missing optional fields
- **THEN** the system SHALL use defaults: empty string for hint_text, "yesno" for question_type, true for correct_answer_is_yes, ["Yes", "No"] for choice_labels

#### Scenario: Question type field
- **WHEN** a page specifies question_type
- **THEN** it SHALL be one of: "yesno", "text", or "multi"

#### Scenario: Text question fields
- **WHEN** question_type is "text"
- **THEN** the page SHALL include a correct_answer string field

#### Scenario: Multi question fields
- **WHEN** question_type is "multi"
- **THEN** the page SHALL include a questions array with objects containing question_text and correct_answer

### Requirement: JSON Story Loading

The system SHALL load story data from JSON files using the rxi/json library.

#### Scenario: Load valid story
- **WHEN** a valid JSON file is provided
- **THEN** the system SHALL parse it into a Lua table and store it in GameState

#### Scenario: Handle invalid JSON
- **WHEN** an invalid JSON file is loaded
- **THEN** the system SHALL display an error message without crashing

### Requirement: State Management

The system SHALL maintain game state including current page ID, game variables, loaded story, and completion status.

#### Scenario: Initialize state
- **WHEN** a story is loaded
- **THEN** GameState SHALL be initialized with current_page_id=1, empty variables table, and is_finished=false

#### Scenario: Track variables
- **WHEN** a page sets a variable value
- **THEN** the variables table SHALL be updated with the variable_name and variable_value

#### Scenario: Track completion
- **WHEN** the player reaches a terminal page (no valid destinations)
- **THEN** is_finished SHALL be set to true

### Requirement: Page Rendering

The system SHALL render the current page with an image area, question text, and choice buttons.

#### Scenario: Render image placeholder
- **WHEN** image_path is empty or file not found
- **THEN** the system SHALL draw a colored placeholder rectangle

#### Scenario: Render loaded image
- **WHEN** image_path points to a valid image file
- **THEN** the system SHALL display the image scaled to fit the designated area

#### Scenario: Render question text
- **WHEN** a page is displayed
- **THEN** question_text SHALL be rendered at the bottom portion of the screen

#### Scenario: Render choice buttons
- **WHEN** a page is displayed
- **THEN** two buttons SHALL be rendered with labels from choice_labels or defaults

### Requirement: Navigation

The system SHALL navigate between pages based on linear page ordering.

#### Scenario: Navigate on correct answer
- **WHEN** user makes a correct choice
- **THEN** current_page_index SHALL advance to the next page

#### Scenario: Navigate on incorrect answer
- **WHEN** user makes an incorrect choice
- **THEN** current_page_index SHALL remain unchanged

#### Scenario: Handle terminal page
- **WHEN** on the last page AND answer is correct
- **THEN** the game SHALL mark is_finished as true and display win screen

### Requirement: Text Answer Evaluation

The system SHALL evaluate text answers using exact string matching.

#### Scenario: Exact match success
- **WHEN** question_type is "text" AND user input exactly matches correct_answer
- **THEN** evaluateTextAnswer SHALL return true

#### Scenario: Exact match failure
- **WHEN** question_type is "text" AND user input does not exactly match correct_answer
- **THEN** evaluateTextAnswer SHALL return false

#### Scenario: Case sensitivity
- **WHEN** comparing text answers
- **THEN** the comparison SHALL be case-sensitive

### Requirement: Multi-Question Evaluation

The system SHALL evaluate multi-question pages with partial scoring and error tracking.

#### Scenario: All answers correct
- **WHEN** question_type is "multi" AND all user answers exactly match their correct_answers
- **THEN** evaluateMultiQuestion SHALL return true with empty errors array

#### Scenario: Partial answers correct
- **WHEN** question_type is "multi" AND some answers are incorrect
- **THEN** evaluateMultiQuestion SHALL return false with errors array containing indices and expected values of wrong answers

#### Scenario: Error feedback structure
- **WHEN** a multi-question has incorrect answers
- **THEN** the errors array SHALL contain objects with: question_index, user_answer, correct_answer

### Requirement: Question Type Navigation

The system SHALL navigate based on question type evaluation results using linear navigation.

#### Scenario: Yesno navigation
- **WHEN** question_type is "yesno"
- **THEN** navigation SHALL use evaluateYesNo with linear page advancement

#### Scenario: Text question navigation
- **WHEN** question_type is "text" AND text evaluation returns true
- **THEN** current_page_index SHALL advance to next page

#### Scenario: Text question incorrect
- **WHEN** question_type is "text" AND text evaluation returns false
- **THEN** current_page_index SHALL remain unchanged (retry)

#### Scenario: Multi question navigation
- **WHEN** question_type is "multi" AND all answers correct
- **THEN** current_page_index SHALL advance to next page

#### Scenario: Multi question incorrect navigation
- **WHEN** question_type is "multi" AND any answer incorrect
- **THEN** current_page_index SHALL remain unchanged until user corrects errors

### Requirement: Story-Level Fields

The system SHALL support story-level configuration fields.

#### Scenario: Story topic field
- **WHEN** a story is loaded
- **THEN** the story MAY contain an optional `topic` string field

#### Scenario: Story image prompt field
- **WHEN** a story is loaded
- **THEN** the story MAY contain an optional `general_image_prompt` string field

### Requirement: Yes/No Question Type

The system SHALL support a simple yes/no question type with boolean correct answer.

#### Scenario: Yesno question structure
- **WHEN** question_type is "yesno"
- **THEN** the page SHALL include `correct_answer_is_yes` boolean and `choice_labels` array

#### Scenario: Yesno default correct answer
- **WHEN** question_type is "yesno" AND `correct_answer_is_yes` is not specified
- **THEN** it SHALL default to true (Yes is correct)

### Requirement: Yes/No Evaluation

The system SHALL evaluate yes/no answers by comparing user choice to the correct answer boolean.

#### Scenario: Yes is correct and user selects yes
- **WHEN** correct_answer_is_yes is true AND user selects "yes"
- **THEN** evaluateYesNo SHALL return true

#### Scenario: Yes is correct and user selects no
- **WHEN** correct_answer_is_yes is true AND user selects "no"
- **THEN** evaluateYesNo SHALL return false

#### Scenario: No is correct and user selects no
- **WHEN** correct_answer_is_yes is false AND user selects "no"
- **THEN** evaluateYesNo SHALL return true

#### Scenario: No is correct and user selects yes
- **WHEN** correct_answer_is_yes is false AND user selects "yes"
- **THEN** evaluateYesNo SHALL return false

### Requirement: Linear Navigation

The system SHALL navigate between pages in sequential order based on answer correctness.

#### Scenario: Correct answer advances
- **WHEN** user answers correctly (yesno, text, or multi)
- **THEN** current_page_index SHALL advance to the next page in sequence

#### Scenario: Wrong answer retries
- **WHEN** user answers incorrectly
- **THEN** current_page_index SHALL remain unchanged (retry same page)

#### Scenario: Last page completion
- **WHEN** user answers correctly on the last page
- **THEN** is_finished SHALL be set to true with result "win"

#### Scenario: Page index tracking
- **WHEN** a story is loaded
- **THEN** GameState SHALL track current_page_index starting at 1

### Requirement: Story Migration

The system SHALL migrate stories from old format to new format.

#### Scenario: Migrate binary to yesno
- **WHEN** loading a story with question_type "binary"
- **THEN** it SHALL be converted to question_type "yesno" with correct_answer_is_yes true

#### Scenario: Add missing story fields
- **WHEN** loading a story without topic or general_image_prompt
- **THEN** they SHALL be added as empty strings

#### Scenario: Remove deprecated page fields
- **WHEN** migrating a page
- **THEN** variable_name, variable_value, operator, target_value, true_destination_id, false_destination_id, and image_description SHALL be removed

