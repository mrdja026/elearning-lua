## ADDED Requirements

### Requirement: Story Listing API

The system SHALL provide an API endpoint to list published stories.

#### Scenario: List stories
- **WHEN** a GET request is made to `/api/stories`
- **THEN** the system SHALL return a JSON array of stories with id, title, author_name, downloads, created_at

#### Scenario: Pagination
- **WHEN** a GET request includes `?page=2&limit=20`
- **THEN** the system SHALL return the specified page of results

#### Scenario: DEV_MODE listing
- **WHEN** DEV_MODE is true
- **THEN** the system SHALL return mock story data without database calls

### Requirement: Story Retrieval API

The system SHALL provide an API endpoint to retrieve a single story.

#### Scenario: Get story by ID
- **WHEN** a GET request is made to `/api/stories/:id`
- **THEN** the system SHALL return the full story JSON including all pages

#### Scenario: Story not found
- **WHEN** a GET request is made with an invalid ID
- **THEN** the system SHALL return a 404 error

#### Scenario: DEV_MODE retrieval
- **WHEN** DEV_MODE is true AND a GET request is made to `/api/stories/:id`
- **THEN** the system SHALL return a mock story without database calls

### Requirement: Story Publishing API

The system SHALL provide an API endpoint to publish stories.

#### Scenario: Publish story
- **WHEN** a POST request is made to `/api/stories` with valid auth and story JSON
- **THEN** the system SHALL save the story and return the new story ID

#### Scenario: Unauthorized publish
- **WHEN** a POST request is made without valid authentication
- **THEN** the system SHALL return a 401 error

#### Scenario: Non-supporter publish
- **WHEN** a POST request is made by a user with is_supporter=false
- **THEN** the system SHALL return a 403 error with message "Supporters only"

#### Scenario: DEV_MODE publish
- **WHEN** DEV_MODE is true
- **THEN** the system SHALL skip auth and return a mock story ID

### Requirement: Story Deletion API

The system SHALL provide an API endpoint to delete own stories.

#### Scenario: Delete own story
- **WHEN** a DELETE request is made to `/api/stories/:id` by the story author
- **THEN** the system SHALL remove the story and return success

#### Scenario: Delete other's story
- **WHEN** a DELETE request is made by someone other than the author
- **THEN** the system SHALL return a 403 error

### Requirement: Authentication Middleware

The system SHALL verify JWT tokens from Supabase Auth.

#### Scenario: Valid token
- **WHEN** a request includes a valid Authorization Bearer token
- **THEN** the middleware SHALL extract user ID and attach to request context

#### Scenario: Invalid token
- **WHEN** a request includes an invalid or expired token
- **THEN** the middleware SHALL return a 401 error

#### Scenario: Missing token
- **WHEN** a protected route is accessed without Authorization header
- **THEN** the middleware SHALL return a 401 error

### Requirement: Supabase Database Schema

The system SHALL use Supabase PostgreSQL for data persistence.

#### Scenario: Profiles table
- **WHEN** a user signs up
- **THEN** a profile record SHALL be created with id, email, display_name, is_supporter, created_at

#### Scenario: Stories table
- **WHEN** a story is published
- **THEN** a story record SHALL be created with id, title, author_id, json_data (JSONB), downloads, created_at

#### Scenario: Row Level Security
- **WHEN** RLS is enabled
- **THEN** users SHALL only be able to modify their own stories
