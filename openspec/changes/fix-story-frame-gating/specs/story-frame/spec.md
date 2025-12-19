## MODIFIED Requirements

### Requirement: Backwards Compatibility

The system SHALL handle old stories without cover_image_path by requiring cover generation before editing.

#### Scenario: Load old story without cover field
- **WHEN** an old story JSON without `cover_image_path` field is loaded
- **THEN** `cover_image_path` SHALL default to empty string
- **AND** the Pages panel SHALL be disabled until cover is generated
- **AND** a message "Generate cover to edit pages" SHALL be displayed

## REMOVED Requirements

### Requirement: Backwards Compatibility (Legacy Exception)
**Reason**: The exception allowing old stories to bypass cover gating undermines the core requirement that stories must have a cover before pages can be edited.
**Migration**: Old stories will need to generate a cover image when loaded. This is a one-time action.
