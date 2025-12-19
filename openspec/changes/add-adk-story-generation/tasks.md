# Tasks: Add ADK Story Generation

## 1. Environment Setup

### 1.1 Dependencies
- [x] 1.1.1 Install `@google/adk` package in backend
- [x] 1.1.2 Install `@upstash/redis` package in backend
- [x] 1.1.3 Verify packages in `package.json`

### 1.2 Environment Variables
- [x] 1.2.1 Update `.env.example` with new variables:
  - `UPSTASH_REDIS_REST_URL`
  - `UPSTASH_REDIS_REST_TOKEN`
- [x] 1.2.2 **MANUAL**: User creates Upstash account at https://console.upstash.com
- [x] 1.2.3 **MANUAL**: User creates Redis database (free tier)
- [x] 1.2.4 **MANUAL**: User copies REST URL and token to `.env`
- [x] 1.2.5 **MANUAL**: User confirms existing `GEMINI_API_KEY` works

### 1.3 Verification
- [x] 1.3.1 Add startup log showing ADK dependencies loaded
- [x] 1.3.2 Add startup log showing Redis connection status
- [ ] 1.3.3 Test backend starts without errors

## 2. Backend Services

> **Note**: Reuse existing services where possible:
> - `services/image-uploader.ts` - Use as-is for Cloudinary uploads
> - `services/image-generator.ts` - Use as-is for Stability AI
> - `services/prompt-builder.ts` - Copy DEV_MODE pattern, JSON parsing, logging

### 2.1 Cache Service
- [x] 2.1.1 Create `backend/src/services/cache.ts`
- [x] 2.1.2 Implement Upstash Redis client initialization
- [x] 2.1.3 Implement in-memory fallback for DEV_MODE
- [x] 2.1.4 Implement `getCache(key)` function
- [x] 2.1.5 Implement `setCache(key, value, ttl)` function
- [x] 2.1.6 Implement `deleteCache(key)` function

### 2.2 Types
- [x] 2.2.1 Create `backend/src/types/story.ts` with:
  - `GeneratedStory` interface
  - `ResearchData` interface
  - `StoryData` interface
  - `CriticReview` interface
  - `WizardSession` interface

## 3. Backend Agents (with curl testing)

> **Pattern**: Each agent follows `prompt-builder.ts` patterns:
> - DEV_MODE returns mock response
> - JSON extraction from markdown code blocks
> - Token usage logging
> - Detailed error handling with `[AgentName]` prefix

### 3.1 Agent A: Researcher
- [x] 3.1.1 Create `backend/src/agents/researcher.ts`
- [x] 3.1.2 Implement Researcher agent with Google Search grounding
- [x] 3.1.3 Add DEV_MODE mock response
- [x] 3.1.4 Create test route `POST /api/test-researcher`
- [ ] 3.1.5 **TEST**: curl test researcher endpoint
  ```bash
  curl -X POST http://localhost:3000/api/test-researcher \
    -H "Content-Type: application/json" \
    -d '{"topic": "Why do volcanoes erupt?"}'
  ```
- [ ] 3.1.6 **MANUAL**: Confirm response has facts + source URLs

### 3.2 Agent B: Storyteller
- [x] 3.2.1 Create `backend/src/agents/storyteller.ts`
- [x] 3.2.2 Implement Storyteller agent
- [x] 3.2.3 Add DEV_MODE mock response
- [x] 3.2.4 Create test route `POST /api/test-storyteller`
- [ ] 3.2.5 **TEST**: curl test storyteller endpoint
  ```bash
  curl -X POST http://localhost:3000/api/test-storyteller \
    -H "Content-Type: application/json" \
    -d '{"researchData": {"facts": ["Volcanoes have magma inside"]}, "artStyle": "fantasy"}'
  ```
- [ ] 3.2.6 **MANUAL**: Confirm response has title, 3 pages with questions

### 3.3 Agent D: Critic
- [x] 3.3.1 Create `backend/src/agents/critic.ts`
- [x] 3.3.2 Implement Critic agent (flag only, no rejection)
- [x] 3.3.3 Add DEV_MODE mock response
- [x] 3.3.4 Create test route `POST /api/test-critic`
- [ ] 3.3.5 **TEST**: curl test critic endpoint
  ```bash
  curl -X POST http://localhost:3000/api/test-critic \
    -H "Content-Type: application/json" \
    -d '{"storyData": {"title": "Test", "pages": []}}'
  ```
- [ ] 3.3.6 **MANUAL**: Confirm response has approved, warnings, readabilityScore

### 3.4 Pipeline Orchestrator
- [x] 3.4.1 Create `backend/src/agents/index.ts`
- [x] 3.4.2 Implement SequentialAgent pipeline
- [x] 3.4.3 Add research caching (check cache before Agent A)
- [x] 3.4.4 Create test route `POST /api/test-pipeline`
- [ ] 3.4.5 **TEST**: curl test full pipeline
  ```bash
  curl -X POST http://localhost:3000/api/test-pipeline \
    -H "Content-Type: application/json" \
    -d '{"topic": "Why is the sky blue?", "artStyle": "fantasy"}'
  ```
- [ ] 3.4.6 **MANUAL**: Confirm full pipeline output

## 4. Session Management (Wizard Flow)

### 4.1 Session Service
- [x] 4.1.1 Implement `createSession(topic, artStyle)` in cache.ts
- [x] 4.1.2 Implement `getSession(sessionId)` in cache.ts
- [x] 4.1.3 Implement `updateSession(sessionId, data)` in cache.ts
- [x] 4.1.4 Implement `deleteSession(sessionId)` in cache.ts
- [x] 4.1.5 Set session TTL to 30 minutes

### 4.2 Wizard Routes
- [x] 4.2.1 Create `backend/src/routes/wizard-routes.ts`
- [x] 4.2.2 Implement `POST /api/story-wizard/start`
  - Creates session with topic + artStyle
  - Returns sessionId
- [x] 4.2.3 Implement `POST /api/story-wizard/research`
  - Runs Agent A
  - Stores research in session
  - Returns facts preview for confirmation
- [x] 4.2.4 Implement `POST /api/story-wizard/story`
  - Runs Agent B
  - Stores story in session
  - Returns story preview
- [x] 4.2.5 Implement `POST /api/story-wizard/review`
  - Runs Agent D
  - Stores review in session
  - Returns review data
- [x] 4.2.6 Implement `GET /api/story-wizard/complete/:sessionId`
  - Returns final story JSON with all data
- [x] 4.2.7 Implement `GET /api/story-wizard/status/:sessionId`
  - Returns current session state
- [x] 4.2.8 Implement `DELETE /api/story-wizard/:sessionId`
  - Deletes session
- [x] 4.2.9 Register wizard routes in index.ts

### 4.3 Wizard Testing
- [ ] 4.3.1 **TEST**: Full wizard flow with curl
  ```bash
  # Step 1: Start
  SESSION=$(curl -s -X POST http://localhost:3000/api/story-wizard/start \
    -H "Content-Type: application/json" \
    -d '{"topic": "Why do bees make honey?", "artStyle": "cartoon"}' | jq -r '.sessionId')

  # Step 2: Research
  curl -X POST http://localhost:3000/api/story-wizard/research \
    -H "Content-Type: application/json" \
    -d "{\"sessionId\": \"$SESSION\"}"

  # Step 3: Generate story
  curl -X POST http://localhost:3000/api/story-wizard/story \
    -H "Content-Type: application/json" \
    -d "{\"sessionId\": \"$SESSION\"}"

  # Step 4: Review
  curl -X POST http://localhost:3000/api/story-wizard/review \
    -H "Content-Type: application/json" \
    -d "{\"sessionId\": \"$SESSION\"}"

  # Step 5: Get complete story
  curl http://localhost:3000/api/story-wizard/complete/$SESSION
  ```
- [ ] 4.3.2 **MANUAL**: Confirm wizard flow works end-to-end

## 5. One-Shot Endpoint (Convenience)

### 5.1 Generate Story Route
- [x] 5.1.1 Create `backend/src/routes/generate-story.ts`
- [x] 5.1.2 Implement `POST /api/generate-story`
  - Runs full pipeline (research → story → critic)
  - Returns complete story JSON (images generated separately)
- [x] 5.1.3 Register route in index.ts
- [ ] 5.1.4 **TEST**: curl test one-shot endpoint
  ```bash
  curl -X POST http://localhost:3000/api/generate-story \
    -H "Content-Type: application/json" \
    -d '{"topic": "How do planes fly?", "artStyle": "pixel"}'
  ```
- [ ] 5.1.5 **MANUAL**: Confirm complete story output

## 6. Documentation

- [x] 6.1 Update `.env.example` with all new variables
- [x] 6.2 Add logging and comments in route files

## 7. UX Integration (DEFERRED)

> **Note**: Frontend/Lua changes are OUT OF SCOPE for this change.
> Will be implemented in a separate `add-ai-generate-wizard` change after backend is stable.

- [ ] 7.1 (DEFERRED) Update `schema.lua` with new metadata fields
- [ ] 7.2 (DEFERRED) Add AI Generate wizard modal to `editor.lua`
- [ ] 7.3 (DEFERRED) Wire up Lua HTTP calls to wizard endpoints
