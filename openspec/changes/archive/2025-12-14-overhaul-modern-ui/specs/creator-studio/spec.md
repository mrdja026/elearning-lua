## MODIFIED Requirements

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

## ADDED Requirements

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
