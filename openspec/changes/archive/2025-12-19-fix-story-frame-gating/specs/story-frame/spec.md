## MODIFIED Requirements

### Requirement: Backwards Compatibility

The system SHALL handle old stories without cover_image_path by requiring cover generation before editing.

#### Scenario: Load old story without cover field
- **WHEN** an old story JSON without `cover_image_path` field is loaded
- **THEN** `cover_image_path` SHALL default to empty string
- **AND** the Pages panel SHALL be disabled until cover is generated
- **AND** Story Settings SHALL be expanded automatically
- **AND** a message "Generate cover to edit pages" SHALL be displayed
