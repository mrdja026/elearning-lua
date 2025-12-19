## ADDED Requirements

### Requirement: Unified Preview Display

The system SHALL use the Play screen component to render both story cover and page images in the config preview panel, distinguished by display mode.

#### Scenario: Preview display mode selection
- **WHEN** Config mode is active
- **THEN** the preview panel SHALL use PlayScreen with `displayMode` parameter
- **AND** `displayMode` SHALL be "STORY" when viewing story settings with a cover image
- **AND** `displayMode` SHALL be "PAGE" when viewing a specific page

#### Scenario: Story mode preview
- **WHEN** `displayMode` is "STORY"
- **THEN** the preview SHALL display the story cover image centered
- **AND** the story title SHALL be displayed
- **AND** the story topic SHALL be displayed if set

#### Scenario: Page mode preview
- **WHEN** `displayMode` is "PAGE"
- **THEN** the preview SHALL display the currently selected page image
- **AND** existing page preview behavior SHALL be maintained

#### Scenario: No cover yet
- **WHEN** `displayMode` is "STORY" AND no cover image exists
- **THEN** a placeholder with "Generate cover image" message SHALL be displayed

## MODIFIED Requirements

### Requirement: Center preview panel

The system SHALL display the currently selected content using the Play screen component in preview mode.

#### Scenario: Center preview panel
- **WHEN** Config mode is active
- **THEN** the center panel SHALL use PlayScreen.draw() with preview=true
- **AND** the displayMode SHALL be determined by current selection (story settings vs page)
