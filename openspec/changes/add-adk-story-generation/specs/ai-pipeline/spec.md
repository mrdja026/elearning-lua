# ai-pipeline Spec Delta

## ADDED Requirements

### Requirement: Story Generation Pipeline

The system SHALL provide an HTTP endpoint for generating complete educational stories using a multi-agent ADK pipeline.

#### Scenario: One-shot story generation
- **WHEN** a POST request is made to `/api/generate-story`
- **AND** the request body contains `topic` and `artStyle` fields
- **THEN** the system SHALL run the full agent pipeline and return a complete story JSON

#### Scenario: Missing topic
- **WHEN** a POST request is missing `topic`
- **THEN** the system SHALL return a 400 error with validation message

#### Scenario: Invalid art style
- **WHEN** `artStyle` is not one of "pixel", "fantasy", "cartoon"
- **THEN** the system SHALL default to "fantasy"

#### Scenario: Pipeline timing
- **WHEN** story generation completes
- **THEN** the system SHALL log total duration and per-agent timing

### Requirement: Researcher Agent

The system SHALL use Google ADK with Google Search grounding to research topics for children aged 5-8.

#### Scenario: Research with grounding
- **WHEN** the Researcher agent receives a topic
- **THEN** it SHALL use Google Search to find 3-5 accurate facts

#### Scenario: Simple language
- **WHEN** generating facts
- **THEN** facts SHALL use short sentences with no jargon suitable for ages 5-8

#### Scenario: Source URLs
- **WHEN** grounded search completes
- **THEN** the agent SHALL return source URLs for transparency

#### Scenario: Research caching
- **WHEN** researching a previously cached topic
- **THEN** the system SHALL return cached results instead of calling Google Search

#### Scenario: Cache TTL
- **WHEN** caching research results
- **THEN** the cache TTL SHALL be 24 hours

### Requirement: Storyteller Agent

The system SHALL use an LLM agent to create 3-page educational stories from research facts.

#### Scenario: Story structure
- **WHEN** the Storyteller agent receives research data
- **THEN** it SHALL generate a story with title and exactly 3 pages

#### Scenario: Page content
- **WHEN** generating each page
- **THEN** the page SHALL contain: story text (50-100 words), question, hint, and image prompt

#### Scenario: Question types
- **WHEN** generating questions
- **THEN** the agent SHALL use "yesno" or "text" question types

#### Scenario: Art style integration
- **WHEN** generating image prompts
- **THEN** prompts SHALL include the specified art style keywords

#### Scenario: Fact integration
- **WHEN** creating story narrative
- **THEN** research facts SHALL be naturally woven into the story

### Requirement: Critic Agent

The system SHALL use an LLM agent to review generated stories for age-appropriateness.

#### Scenario: Content review
- **WHEN** the Critic agent receives a story
- **THEN** it SHALL check for age-appropriateness, factual accuracy, and scary content

#### Scenario: Flag only mode
- **WHEN** issues are found
- **THEN** the agent SHALL flag warnings but SHALL NOT reject the story

#### Scenario: Review output
- **WHEN** review completes
- **THEN** the agent SHALL return: approved boolean, warnings array, and readability score

### Requirement: Story Wizard Session

The system SHALL support a multi-step wizard flow with session state for story generation.

#### Scenario: Start wizard session
- **WHEN** a POST request is made to `/api/story-wizard/start`
- **AND** the request body contains `topic` and `artStyle`
- **THEN** the system SHALL create a session and return a `sessionId`

#### Scenario: Research step
- **WHEN** a POST request is made to `/api/story-wizard/research`
- **AND** the request body contains a valid `sessionId`
- **THEN** the system SHALL run the Researcher agent and return facts for preview

#### Scenario: Generate step
- **WHEN** a POST request is made to `/api/story-wizard/generate`
- **AND** the request body contains a valid `sessionId`
- **THEN** the system SHALL run Storyteller and Critic agents and return story for preview

#### Scenario: Complete step
- **WHEN** a POST request is made to `/api/story-wizard/complete`
- **AND** the request body contains a valid `sessionId`
- **THEN** the system SHALL generate images and return the final story JSON

#### Scenario: Session expiry
- **WHEN** a session is not accessed for 30 minutes
- **THEN** the session SHALL be automatically deleted

#### Scenario: Invalid session
- **WHEN** a request contains an invalid or expired `sessionId`
- **THEN** the system SHALL return a 404 error

### Requirement: Cache Service

The system SHALL use Upstash Redis for caching research results and wizard sessions.

#### Scenario: Redis connection
- **WHEN** the backend starts with `UPSTASH_REDIS_REST_URL` configured
- **THEN** the system SHALL connect to Upstash Redis

#### Scenario: DEV_MODE fallback
- **WHEN** `DEV_MODE=true` or Redis credentials are missing
- **THEN** the system SHALL use an in-memory cache

#### Scenario: Cache operations
- **WHEN** using the cache service
- **THEN** the system SHALL support get, set (with TTL), and delete operations

### Requirement: Story Metadata Extensions

The system SHALL support additional metadata fields for AI-generated stories.

#### Scenario: Generation metadata
- **WHEN** a story is generated by the AI pipeline
- **THEN** it SHALL include a `generation` object with: `source` ("ai"), `grounded_facts` array, `source_urls` array, and `timestamp`

#### Scenario: Target age
- **WHEN** a story is generated
- **THEN** it SHALL include a `target_age` field (default "5-8")

#### Scenario: Art style
- **WHEN** a story is generated
- **THEN** it SHALL include an `art_style` field matching the requested style

#### Scenario: Critic review
- **WHEN** a story is generated
- **THEN** it SHALL include a `critic_review` object with: `approved`, `warnings`, and `readability_score`

### Requirement: Configuration Extensions

The system SHALL read additional API credentials from environment variables.

#### Scenario: Redis environment variables
- **WHEN** the backend starts
- **THEN** it SHALL read `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN` (optional)

#### Scenario: Gemini API key
- **WHEN** the backend starts
- **THEN** it SHALL require `GEMINI_API_KEY` for ADK agents

### Requirement: Agent Test Routes

The system SHALL provide test endpoints for individual agents during development.

#### Scenario: Test researcher
- **WHEN** a POST request is made to `/api/test-researcher`
- **THEN** the system SHALL run only the Researcher agent and return results

#### Scenario: Test storyteller
- **WHEN** a POST request is made to `/api/test-storyteller`
- **THEN** the system SHALL run only the Storyteller agent with provided research data

#### Scenario: Test critic
- **WHEN** a POST request is made to `/api/test-critic`
- **THEN** the system SHALL run only the Critic agent with provided story data

#### Scenario: Test pipeline
- **WHEN** a POST request is made to `/api/test-pipeline`
- **THEN** the system SHALL run the full agent pipeline without image generation
