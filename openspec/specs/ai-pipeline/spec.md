# ai-pipeline Specification

## Purpose
TBD - created by archiving change add-ai-pipeline. Update Purpose after archive.
## Requirements
### Requirement: Image Generation Endpoint

The system SHALL provide an HTTP endpoint for generating story images.

#### Scenario: Generate image request
- **WHEN** a POST request is made to `/api/generate-image`
- **AND** the request body contains `description` and `question` fields
- **THEN** the system SHALL return a JSON response with `imageUrl`

#### Scenario: Missing required fields
- **WHEN** a POST request is missing `description` or `question`
- **THEN** the system SHALL return a 400 error with validation message

#### Scenario: Service failure
- **WHEN** any pipeline step fails (Claude, Stability, Cloudinary)
- **THEN** the system SHALL return an error response with message "Service not available, check usage and keys"

### Requirement: Prompt Builder Service

The system SHALL use Claude API to build optimized Stable Diffusion prompts.

#### Scenario: Prompt optimization
- **WHEN** the prompt builder receives description and question
- **THEN** it SHALL generate a child-friendly SD prompt incorporating both inputs

#### Scenario: Negative prompt generation
- **WHEN** building an SD prompt
- **THEN** the system SHALL also generate a negative prompt excluding inappropriate content

#### Scenario: Claude model selection
- **WHEN** calling Claude API
- **THEN** the system SHALL use claude-3-haiku model for cost efficiency

#### Scenario: Token logging
- **WHEN** Claude API responds
- **THEN** the system SHALL log input and output token counts

### Requirement: Image Generation Service

The system SHALL use Stability AI Core API to generate images.

#### Scenario: Image generation
- **WHEN** calling Stability AI with an optimized prompt
- **THEN** the system SHALL request an 800x600 image

#### Scenario: API endpoint
- **WHEN** generating images
- **THEN** the system SHALL use `api.stability.ai/v2beta/stable-image/generate/core`

#### Scenario: Timing logs
- **WHEN** image generation completes
- **THEN** the system SHALL log generation duration

### Requirement: Image Upload Service

The system SHALL upload generated images to Cloudinary.

#### Scenario: Upload from base64
- **WHEN** Stability AI returns image data
- **THEN** the system SHALL upload it to Cloudinary as base64

#### Scenario: Return URL
- **WHEN** upload succeeds
- **THEN** the system SHALL return the Cloudinary secure_url

### Requirement: Configuration

The system SHALL read API credentials from environment variables.

#### Scenario: Required environment variables
- **WHEN** the backend starts
- **THEN** it SHALL require ANTHROPIC_API_KEY, STABILITY_API_KEY, CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET

### Requirement: Logging

The system SHALL log pipeline execution details.

#### Scenario: Request logging
- **WHEN** processing a generation request
- **THEN** the system SHALL log: request timestamp, token usage, generation timing, total cost estimate

### Requirement: Image Download

The system SHALL download generated images from remote URLs and save them locally.

#### Scenario: Download after generation
- **WHEN** the backend returns a successful response with imageUrl
- **THEN** the image thread SHALL download the image binary data from that URL

#### Scenario: Save to local storage
- **WHEN** image binary data is downloaded successfully
- **THEN** the system SHALL save it to `love.filesystem.getSaveDirectory()/images/` with a unique filename

#### Scenario: Return local path
- **WHEN** the image is saved locally
- **THEN** the thread response SHALL contain the local file path instead of the remote URL

#### Scenario: Directory creation
- **WHEN** the images directory does not exist
- **THEN** the system SHALL create it before saving

#### Scenario: Download failure
- **WHEN** image download fails (network error, invalid URL)
- **THEN** the system SHALL return an error response with message describing the failure

