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
- **THEN** a placeholder with "No Cover" message SHALL be displayed
