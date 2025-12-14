## ADDED Requirements

### Requirement: Story Schema

The system SHALL define a Page schema with the following fields: `id`, `image_path`, `question_text`, `hint_text`, `variable_name`, `variable_value`, `operator`, `target_value`, `true_destination_id`, `false_destination_id`, and `choice_labels`.

#### Scenario: Valid page structure
- **WHEN** a story JSON is loaded
- **THEN** each page MUST contain at minimum: id, question_text, operator, target_value, true_destination_id, false_destination_id

#### Scenario: Optional fields have defaults
- **WHEN** a page is missing optional fields (hint_text, choice_labels)
- **THEN** the system SHALL use default values (empty string for hint, ["True", "False"] for labels)

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

### Requirement: Logic Evaluation

The system SHALL evaluate conditions safely without using Lua's loadstring function.

#### Scenario: Greater than comparison
- **WHEN** operator is ">" and current value is 5, target is 3
- **THEN** evaluateCondition SHALL return true

#### Scenario: Less than comparison
- **WHEN** operator is "<" and current value is 2, target is 5
- **THEN** evaluateCondition SHALL return true

#### Scenario: Equality comparison
- **WHEN** operator is "=" and current value is 4, target is 4
- **THEN** evaluateCondition SHALL return true

#### Scenario: Greater than or equal comparison
- **WHEN** operator is ">=" and current value is 3, target is 3
- **THEN** evaluateCondition SHALL return true

#### Scenario: Less than or equal comparison
- **WHEN** operator is "<=" and current value is 2, target is 5
- **THEN** evaluateCondition SHALL return true

#### Scenario: Invalid operator
- **WHEN** an unknown operator is provided
- **THEN** evaluateCondition SHALL return false

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

The system SHALL navigate between pages based on user choices and logic evaluation.

#### Scenario: Navigate on correct answer
- **WHEN** user makes a choice AND logic evaluation returns true
- **THEN** current_page_id SHALL be set to true_destination_id

#### Scenario: Navigate on incorrect answer
- **WHEN** user makes a choice AND logic evaluation returns false
- **THEN** current_page_id SHALL be set to false_destination_id

#### Scenario: Handle terminal page
- **WHEN** destination_id is 0 or nil
- **THEN** the game SHALL mark is_finished as true and display result screen
