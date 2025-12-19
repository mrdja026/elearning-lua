## MODIFIED Requirements

### Requirement: Split View Layout

The system SHALL display a preview-centric layout in Create mode with page thumbnails on the left, large preview in the center, and control deck on the right, optimized for 1280x720 virtual resolution.

#### Scenario: Fixed virtual resolution
- **WHEN** the application starts
- **THEN** the virtual resolution SHALL be 1280x720 pixels with integer scaling to window

#### Scenario: Three-column storybook layout
- **WHEN** Config mode is active
- **THEN** the layout SHALL be: page thumbnails panel (150px left), preview panel (center, remaining width), control deck panel (300px right)

#### Scenario: Page thumbnails panel
- **WHEN** Config mode is active
- **THEN** the left panel SHALL display visual thumbnail cards for each page with placeholder images

#### Scenario: Center preview panel
- **WHEN** Config mode is active
- **THEN** the center panel SHALL display the currently selected page at maximum scale that fits the available space

#### Scenario: Control deck panel
- **WHEN** Config mode is active
- **THEN** the right panel SHALL contain all page editor fields (question text, hint, image path, question type configuration)

#### Scenario: Collapsible story settings
- **WHEN** Config mode is active
- **THEN** the top of the control deck SHALL display a collapsible "Story Settings" header containing title, topic, and general image prompt fields

#### Scenario: Dream It button bar
- **WHEN** Config mode is active
- **THEN** a 70px bottom bar SHALL display a prominent "Dream It" button for AI image generation

#### Scenario: Semi-transparent panels
- **WHEN** Config mode is active
- **THEN** all Slab windows SHALL use semi-transparent backgrounds (alpha 0.85-0.90) to reveal decorations beneath

#### Scenario: Status bar
- **WHEN** Config mode is active
- **THEN** status messages SHALL appear as toast notifications overlaid on the interface

#### Scenario: Preview rendering
- **WHEN** Config mode is active
- **THEN** the preview panel SHALL render the currently selected page scaled to fit center area with visible border

## ADDED Requirements

### Requirement: Page Thumbnails

The system SHALL display visual thumbnail representations of story pages in the left sidebar.

#### Scenario: Thumbnail display
- **WHEN** viewing the pages panel
- **THEN** each page SHALL be displayed as a visual card with placeholder image and page number

#### Scenario: Thumbnail selection
- **WHEN** the user clicks a page thumbnail
- **THEN** that page SHALL become selected and appear in the center preview

#### Scenario: Thumbnail placeholder
- **WHEN** a page has no generated image
- **THEN** the thumbnail SHALL display a hardcoded placeholder image

#### Scenario: Selected thumbnail highlight
- **WHEN** a page is selected
- **THEN** its thumbnail SHALL be visually highlighted with primary color border

### Requirement: Dream It Button

The system SHALL provide a prominent button for triggering AI image generation.

#### Scenario: Button placement
- **WHEN** Config mode is active
- **THEN** the "Dream It" button SHALL be displayed in a dedicated bottom bar, centered horizontally

#### Scenario: Button triggers generation
- **WHEN** the user clicks "Dream It"
- **THEN** the system SHALL trigger image generation for the currently selected page using the story-level image prompt

#### Scenario: Button disabled during generation
- **WHEN** image generation is in progress
- **THEN** the "Dream It" button SHALL be disabled and display "Generating..." text

#### Scenario: Prompt required validation
- **WHEN** the user clicks "Dream It" AND general_image_prompt is empty
- **THEN** a warning message SHALL indicate the user must set the story-level prompt first
