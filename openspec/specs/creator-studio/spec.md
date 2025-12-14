# creator-studio Specification

## Purpose
TBD - created by archiving change add-creator-studio. Update Purpose after archive.
## Requirements
### Requirement: Slab GUI Integration

The system SHALL integrate the Slab Immediate Mode GUI library for editor interface rendering.

#### Scenario: Slab initialization
- **WHEN** the application starts
- **THEN** Slab SHALL be initialized with `Slab.Initialize(args)` in love.load

#### Scenario: Slab update loop
- **WHEN** the application is in create mode
- **THEN** `Slab.Update(dt)` SHALL be called each frame before UI code in love.update

#### Scenario: Slab draw
- **WHEN** the application is in create mode
- **THEN** `Slab.Draw()` SHALL be called in love.draw after editor.draw()

#### Scenario: Slab input handling
- **WHEN** the application is in create mode
- **THEN** Slab SHALL automatically receive keyboard and mouse input events via its interceptors

### Requirement: Mode Switching

The system SHALL support switching between Play mode and Create mode.

#### Scenario: Default mode
- **WHEN** the application starts
- **THEN** the default mode SHALL be Play mode

#### Scenario: Switch to create mode
- **WHEN** the user presses the Tab key in Play mode
- **THEN** the application SHALL switch to Create mode

#### Scenario: Switch to play mode
- **WHEN** the user presses the Tab key in Create mode
- **THEN** the application SHALL switch to Play mode

#### Scenario: Mode indicator
- **WHEN** the user is in either mode
- **THEN** the current mode SHALL be displayed on screen

### Requirement: Split View Layout

The system SHALL display a split-view layout in Create mode with editor on the left and preview on the right, optimized for 1280×720 virtual resolution.

#### Scenario: Fixed virtual resolution
- **WHEN** the application starts
- **THEN** the virtual resolution SHALL be 1280×720 pixels with integer scaling to window

#### Scenario: Three-column layout
- **WHEN** Config mode is active
- **THEN** the layout SHALL be: pages panel (180px left), editor panel (500px center), preview panel (400px right)

#### Scenario: Top bar
- **WHEN** Config mode is active
- **THEN** a 60px top bar SHALL display file operations (New/Load/Save) on left, story title center, and Test Play/Settings on right

#### Scenario: Status bar
- **WHEN** Config mode is active
- **THEN** a 40px status bar SHALL display at bottom for generation feedback

#### Scenario: Preview rendering
- **WHEN** Config mode is active
- **THEN** the preview panel SHALL render the currently selected page at 0.48x scale

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

### Requirement: Page Management

The system SHALL allow users to add, remove, and select pages in the story.

#### Scenario: Add new page
- **WHEN** the user clicks the Add Page button
- **THEN** a new page with default values SHALL be added to the story

#### Scenario: Delete page
- **WHEN** the user clicks the Delete Page button
- **THEN** the currently selected page SHALL be removed from the story

#### Scenario: Select page
- **WHEN** the user clicks a page in the page list
- **THEN** that page SHALL become the currently selected page for editing

#### Scenario: Page list display
- **WHEN** Create mode is active
- **THEN** a list of all pages SHALL be displayed with their IDs

### Requirement: File Operations

The system SHALL support saving stories to JSON files and loading stories from JSON files.

#### Scenario: Save story
- **WHEN** the user clicks the Save button
- **THEN** the current story SHALL be validated and saved as a JSON file

#### Scenario: Save validation failure
- **WHEN** the user clicks Save AND the story fails validation
- **THEN** an error message SHALL be displayed and the file SHALL NOT be saved

#### Scenario: Load story
- **WHEN** the user clicks the Load button
- **THEN** a file picker SHALL display available JSON files in the stories directory

#### Scenario: Load story selection
- **WHEN** the user selects a file from the load dialog
- **THEN** the story SHALL be loaded into the editor state

#### Scenario: New story
- **WHEN** the user clicks the New Story button
- **THEN** the editor state SHALL be reset to a blank story template

### Requirement: Live Preview

The system SHALL display a live preview of the currently selected page.

#### Scenario: Preview updates on edit
- **WHEN** the user modifies any page property
- **THEN** the preview panel SHALL update to reflect the changes

#### Scenario: Preview selected page
- **WHEN** the user selects a different page
- **THEN** the preview panel SHALL display the newly selected page

#### Scenario: Test play
- **WHEN** the user clicks the Test Play button
- **THEN** the application SHALL switch to Play mode with the current story loaded

### Requirement: Dropdown Functionality

The system SHALL provide fully functional dropdown menus that respond to user interaction.

#### Scenario: Dropdown toggle
- **WHEN** the user clicks a dropdown button
- **THEN** the dropdown list SHALL open if closed, or close if open

#### Scenario: Dropdown item selection
- **WHEN** the user clicks an item in an open dropdown
- **THEN** that item SHALL be selected and the dropdown SHALL close

#### Scenario: Dropdown close on outside click
- **WHEN** the user clicks outside an open dropdown
- **THEN** the dropdown SHALL close without changing selection

### Requirement: Dropdown Styling

The system SHALL render dropdown menus with proper backgrounds and borders for readability.

#### Scenario: Dropdown background
- **WHEN** a dropdown menu is displayed
- **THEN** it SHALL have a solid background color distinct from the panel background

#### Scenario: Dropdown border
- **WHEN** a dropdown menu is displayed
- **THEN** it SHALL have a visible border to separate it from surrounding elements

#### Scenario: Dropdown item hover
- **WHEN** hovering over a dropdown item
- **THEN** the item SHALL be visually highlighted

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
- **WHEN** a new image is downloaded and saved locally
- **THEN** the preview panel SHALL reload to display the new image

#### Scenario: Status feedback during generation
- **WHEN** image generation is in progress
- **THEN** the status bar SHALL display "Generating image..." with visual indicator

#### Scenario: Status feedback on success
- **WHEN** image generation completes successfully
- **THEN** the status bar SHALL display "Image generated!" for 3 seconds

#### Scenario: Status feedback on error
- **WHEN** image generation fails
- **THEN** the status bar SHALL display error message for 5 seconds

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

### Requirement: Play Mode Split Layout

The system SHALL display Play mode with a split left/right layout.

#### Scenario: Left panel for image
- **WHEN** Play mode is active
- **THEN** the left panel (55% width, 704px) SHALL display the page image in a card frame

#### Scenario: Right panel for question
- **WHEN** Play mode is active
- **THEN** the right panel (45% width, 576px) SHALL display question text and answer controls

#### Scenario: Image card frame
- **WHEN** displaying page image
- **THEN** it SHALL be rendered inside a 4px bordered card with maximum dimensions 656×420

#### Scenario: Answer buttons sizing
- **WHEN** displaying binary choice buttons
- **THEN** they SHALL be 220×64 pixels with 24px gap between them

#### Scenario: Text input sizing
- **WHEN** displaying text answer input
- **THEN** it SHALL be at least 400px wide and 48px tall

### Requirement: Keyboard and Controller Navigation

The system SHALL support keyboard and controller navigation in Play mode.

#### Scenario: Focus on answer buttons
- **WHEN** Play mode displays binary choices
- **THEN** arrow keys or D-pad SHALL move focus between True/False buttons

#### Scenario: Focus on text input
- **WHEN** Play mode displays text input
- **THEN** the input field SHALL receive focus automatically

#### Scenario: Activate with keyboard
- **WHEN** a button is focused and Enter or Space is pressed
- **THEN** the button action SHALL be triggered

#### Scenario: Activate with controller
- **WHEN** a button is focused and gamepad A button is pressed
- **THEN** the button action SHALL be triggered

#### Scenario: Visual focus indicator
- **WHEN** an element is focused
- **THEN** it SHALL display a visible focus ring using accent color and heavy border

