## ADDED Requirements

### Requirement: Slab GUI Integration

The system SHALL integrate the Slab Immediate Mode GUI library for editor interface rendering.

#### Scenario: Slab initialization
- **WHEN** the application starts
- **THEN** Slab SHALL be initialized in love.load

#### Scenario: Slab update loop
- **WHEN** the application is in create mode
- **THEN** Slab.Update SHALL be called each frame in love.update

#### Scenario: Slab input handling
- **WHEN** the application is in create mode
- **THEN** Slab SHALL receive keyboard and mouse input events

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

The system SHALL display a split-view layout in Create mode with editor on the left and preview on the right.

#### Scenario: Editor panel dimensions
- **WHEN** Create mode is active
- **THEN** the editor panel SHALL occupy approximately 60% of the window width on the left

#### Scenario: Preview panel dimensions
- **WHEN** Create mode is active
- **THEN** the preview panel SHALL occupy approximately 40% of the window width on the right

#### Scenario: Preview rendering
- **WHEN** Create mode is active
- **THEN** the preview panel SHALL render the currently selected page using the existing renderer

### Requirement: Story Editor

The system SHALL provide UI controls for editing all story and page properties.

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
- **WHEN** the user selects an operator from the dropdown
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
- **WHEN** the user modifies choice label inputs
- **THEN** the current page choice_labels SHALL be updated

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
