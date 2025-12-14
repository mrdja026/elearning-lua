## MODIFIED Requirements

### Requirement: Split View Layout

The system SHALL display a split-view layout in Create mode with editor on the left and preview on the right, optimized for 1024x768 fixed resolution.

#### Scenario: Fixed window size
- **WHEN** the application starts
- **THEN** the window SHALL be 1024x768 pixels and non-resizable

#### Scenario: Editor panel dimensions
- **WHEN** Create mode is active
- **THEN** the editor panel SHALL occupy approximately 60% of the window width on the left

#### Scenario: Preview panel dimensions
- **WHEN** Create mode is active
- **THEN** the preview panel SHALL occupy approximately 40% of the window width on the right

#### Scenario: Preview rendering
- **WHEN** Create mode is active
- **THEN** the preview panel SHALL render the currently selected page using the existing renderer

## ADDED Requirements

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
