## MODIFIED Requirements

### Requirement: Story Schema

The system SHALL define a Page schema with the following fields: `id`, `image_path`, `question_text`, `hint_text`, `variable_name`, `variable_value`, `operator`, `target_value`, `true_destination_id`, `false_destination_id`, `choice_labels`, `question_type`, `correct_answer`, and `questions`.

#### Scenario: Valid page structure
- **WHEN** a story JSON is loaded
- **THEN** each page MUST contain at minimum: id, question_text, true_destination_id, false_destination_id

#### Scenario: Optional fields have defaults
- **WHEN** a page is missing optional fields (hint_text, choice_labels, question_type)
- **THEN** the system SHALL use default values (empty string for hint, ["True", "False"] for labels, "binary" for question_type)

#### Scenario: Question type field
- **WHEN** a page specifies question_type
- **THEN** it SHALL be one of: "binary", "text", or "multi"

#### Scenario: Text question fields
- **WHEN** question_type is "text"
- **THEN** the page SHALL include a correct_answer string field

#### Scenario: Multi question fields
- **WHEN** question_type is "multi"
- **THEN** the page SHALL include a questions array with objects containing question_text and correct_answer

## ADDED Requirements

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

The system SHALL navigate based on question type evaluation results.

#### Scenario: Binary navigation unchanged
- **WHEN** question_type is "binary"
- **THEN** navigation SHALL use existing operator-based logic evaluation

#### Scenario: Text question navigation
- **WHEN** question_type is "text" AND text evaluation returns true
- **THEN** current_page_id SHALL be set to true_destination_id

#### Scenario: Text question incorrect navigation
- **WHEN** question_type is "text" AND text evaluation returns false
- **THEN** current_page_id SHALL be set to false_destination_id

#### Scenario: Multi question navigation
- **WHEN** question_type is "multi" AND all answers correct
- **THEN** current_page_id SHALL be set to true_destination_id

#### Scenario: Multi question incorrect navigation
- **WHEN** question_type is "multi" AND any answer incorrect
- **THEN** current_page_id SHALL remain unchanged until user corrects errors
