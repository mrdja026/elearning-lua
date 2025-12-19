## ADDED Requirements

### Requirement: Procedural Decorations

The system SHALL render procedural pixel-art decorations behind the UI to create a warm storybook atmosphere.

#### Scenario: Decoration layer rendering
- **WHEN** Config mode is active
- **THEN** decorations SHALL be drawn before Slab.Draw() so they appear behind semi-transparent panels

#### Scenario: Pixel-art trees
- **WHEN** rendering decorations
- **THEN** the system SHALL draw stylized trees using triangular foliage and rectangular trunks with pixel-art aesthetic

#### Scenario: Pixel-art stars
- **WHEN** rendering decorations
- **THEN** the system SHALL draw simple 4-point sparkle stars at various positions

#### Scenario: Pixel-art circles
- **WHEN** rendering decorations
- **THEN** the system SHALL draw pixel-perfect circles as decorative elements

#### Scenario: Seeded random placement
- **WHEN** positioning decorations
- **THEN** the system SHALL use a fixed seed for consistent placement across sessions

#### Scenario: Edge placement
- **WHEN** placing decoration elements
- **THEN** trees and large decorations SHALL be positioned along screen edges to avoid obscuring central UI

### Requirement: Warm Storybook Palette

The system SHALL provide warm storybook colors in the design token system.

#### Scenario: Warm background colors
- **WHEN** rendering Config mode background
- **THEN** a warm cream color SHALL be used instead of dark slate

#### Scenario: Decoration colors available
- **WHEN** drawing decorations
- **THEN** forest green, warm brown, and soft gold colors SHALL be available in tokens

#### Scenario: Transparent panel colors
- **WHEN** rendering Slab windows
- **THEN** semi-transparent dark colors (alpha 0.85-0.90) SHALL be available for overlay effect

## MODIFIED Requirements

### Requirement: Layout System

The system SHALL provide layout calculations for responsive panel positioning.

#### Scenario: Play mode layout
- **WHEN** in Play mode
- **THEN** layout SHALL provide left panel (55%), right panel (45%), and status bar positions

#### Scenario: Config mode layout
- **WHEN** in Config mode
- **THEN** layout SHALL provide thumbnails panel (150px left), preview panel (center), story settings header (collapsible), control deck panel (300px right), and dream-it bar (70px bottom) positions

#### Scenario: Safe area support
- **WHEN** running on devices with notches
- **THEN** layout SHALL offset UI using `love.window.getSafeArea()` values

#### Scenario: Responsive preview scaling
- **WHEN** calculating preview panel size
- **THEN** the preview SHALL scale to fit available center space while maintaining aspect ratio
