# ai-pipeline Spec Delta

## ADDED Requirements

### Requirement: Hint-Driven Image Prompt Enhancement

The system SHALL generate visual metaphors from educational hints to create more meaningful image prompts.

#### Scenario: Enhance image prompt with hint
- **WHEN** `enhanceImagePromptWithHint()` is called with a hint, topic, art style, and target age
- **THEN** the system SHALL return:
  - `visualMetaphor`: A concrete visual description (e.g., "road splitting into two paths")
  - `enhancedPrompt`: Full image prompt incorporating the metaphor
  - `negativePrompt`: Standard quality/safety negative prompt

#### Scenario: Programming concept hints
- **WHEN** the hint is a programming concept like "if statement", "for loop", or "variables"
- **THEN** the system SHALL generate an age-appropriate visual metaphor (e.g., "crossroads", "race track", "labeled containers")

#### Scenario: Cybersecurity concept hints
- **WHEN** the hint is a cybersecurity concept like "phishing", "password", or "firewall"
- **THEN** the system SHALL generate a child-friendly visual metaphor (e.g., "wolf in disguise", "treasure key", "castle wall")

#### Scenario: DEV_MODE mock response
- **WHEN** DEV_MODE is enabled
- **THEN** the system SHALL return a mock visual metaphor without calling Gemini API

#### Scenario: Unknown hint fallback
- **WHEN** the hint is not recognized or too vague
- **THEN** the system SHALL generate a generic metaphor based on the topic and target age

### Requirement: Variable Page Count Support

The flow test routes SHALL support configurable page counts.

#### Scenario: Custom page count
- **WHEN** `POST /api/flow-test/start` includes `pageCount` parameter
- **THEN** the session SHALL store the page count and generate that many page images

#### Scenario: Default page count
- **WHEN** `pageCount` is not provided
- **THEN** the system SHALL default to 3 pages

#### Scenario: Page count validation
- **WHEN** `pageCount` is less than 1 or greater than 5
- **THEN** the system SHALL return a 400 error with validation message

### Requirement: Per-Page Hints Support

The flow test routes SHALL accept hints for each page to drive image generation.

#### Scenario: Store page hints in session
- **WHEN** `POST /api/flow-test/start` includes `pageHints` array
- **THEN** the session SHALL store the hints for use during image generation

#### Scenario: Use hints for image generation
- **WHEN** generating page images in `POST /api/flow-test/generate-pages`
- **AND** the session contains `pageHints`
- **THEN** each page image SHALL use the corresponding hint for visual metaphor generation

#### Scenario: Missing hints fallback
- **WHEN** a page does not have a corresponding hint in `pageHints`
- **THEN** the system SHALL use a generic prompt based on the topic

### Requirement: Hint-Aware Image Generation

The image agent SHALL support hint-driven image generation.

#### Scenario: Generate image with hint
- **WHEN** `runImageAgentWithHint()` is called with a hint
- **THEN** the system SHALL:
  1. Call `enhanceImagePromptWithHint()` to get the visual metaphor
  2. Generate an image using the enhanced prompt
  3. Return the image URL along with the visual metaphor used

#### Scenario: Image includes metaphor in result
- **WHEN** hint-driven image generation completes
- **THEN** the result SHALL include `visualMetaphor` field for debugging/display

## MODIFIED Requirements

### Requirement: Flow Test Start Endpoint

The flow test start endpoint SHALL accept additional parameters for page count and hints.

#### Scenario: Accept new parameters
- **WHEN** a POST request is made to `/api/flow-test/start`
- **THEN** the request body MAY include:
  - `topic` (required): The story topic
  - `artStyle` (optional): pixel, fantasy, or cartoon
  - `targetAge` (optional): 5-8, 8-12, 13-17, 18+, or all
  - `pageCount` (optional): Number of pages 1-5
  - `pageHints` (optional): Array of hints for each page
