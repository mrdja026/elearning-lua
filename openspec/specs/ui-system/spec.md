# ui-system Specification

## Purpose
TBD - created by archiving change overhaul-modern-ui. Update Purpose after archive.
## Requirements
### Requirement: Design Tokens

The system SHALL provide centralized design tokens for consistent styling.

#### Scenario: Color tokens available
- **WHEN** any UI component needs colors
- **THEN** it SHALL use colors from `ui/tokens.lua` COLORS table

#### Scenario: Spacing tokens available
- **WHEN** any UI component needs spacing values
- **THEN** it SHALL use values from `ui/tokens.lua` SPACING table (xs=8, sm=16, md=24, lg=32, xl=40, xxl=48)

#### Scenario: Touch target tokens available
- **WHEN** creating interactive elements
- **THEN** they SHALL meet minimum dimensions from TOUCH table (min_target=48px)

### Requirement: Virtual Resolution Scaling

The system SHALL render at 1280×720 virtual resolution with integer scaling.

#### Scenario: Canvas rendering
- **WHEN** the game renders UI
- **THEN** it SHALL draw to a 1280×720 canvas first, then scale to window size

#### Scenario: Integer scaling only
- **WHEN** scaling the canvas to window
- **THEN** it SHALL use integer scale factors (1x, 2x, 3x) to preserve pixel art crispness

#### Scenario: Nearest-neighbor filtering
- **WHEN** any image or canvas is created
- **THEN** it SHALL use nearest-neighbor filtering via `setFilter("nearest", "nearest")`

### Requirement: Layout System

The system SHALL provide layout calculations for responsive panel positioning.

#### Scenario: Play mode layout
- **WHEN** in Play mode
- **THEN** layout SHALL provide left panel (55%), right panel (45%), and status bar positions

#### Scenario: Config mode layout
- **WHEN** in Config mode
- **THEN** layout SHALL provide top bar, pages panel (180px), editor panel (500px), preview panel (400px), and status bar positions

#### Scenario: Safe area support
- **WHEN** running on devices with notches
- **THEN** layout SHALL offset UI using `love.window.getSafeArea()` values

### Requirement: 9-Slice Frame Rendering

The system SHALL render scalable card frames using 9-slice technique.

#### Scenario: Create 9-slice from image
- **WHEN** a 9-slice frame is created
- **THEN** it SHALL load the image with nearest-neighbor filtering

#### Scenario: Draw 9-slice at any size
- **WHEN** drawing a 9-slice frame
- **THEN** corners SHALL remain unscaled while edges and center scale to fill

#### Scenario: Integer dimensions
- **WHEN** drawing 9-slice frames
- **THEN** all positions and sizes SHALL be integers via math.floor()

### Requirement: Unified Input Manager

The system SHALL provide unified input handling for all input methods.

#### Scenario: Focus registration
- **WHEN** an interactive element is created
- **THEN** it SHALL register with input manager including bounds and callbacks

#### Scenario: Keyboard navigation
- **WHEN** arrow keys are pressed
- **THEN** focus SHALL move between registered elements

#### Scenario: Controller navigation
- **WHEN** D-pad is pressed on gamepad
- **THEN** focus SHALL move between registered elements

#### Scenario: Activation
- **WHEN** Enter key, Space key, or gamepad A button is pressed
- **THEN** the focused element's onActivate callback SHALL be called

#### Scenario: Pointer abstraction
- **WHEN** checking pointer position
- **THEN** input manager SHALL return touch position if active, otherwise mouse position

### Requirement: Widget Wrappers

The system SHALL provide wrapper functions for common UI widgets.

#### Scenario: Button widget
- **WHEN** creating a button
- **THEN** it SHALL meet minimum touch target size and use design token colors

#### Scenario: Card widget
- **WHEN** creating a card container
- **THEN** it SHALL render with 9-slice frame and proper padding from tokens

#### Scenario: Panel widget
- **WHEN** creating a panel
- **THEN** it SHALL use surface colors from tokens and apply border styling

