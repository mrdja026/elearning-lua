# Change: Add ADK Multi-Agent Story Generation Pipeline

## Why

Currently, story creation requires users to manually write questions, hints, and image prompts for each page. This is time-consuming and requires creativity that may be challenging for some users. By adding Google ADK (Agent Development Kit) with grounded web search, we can generate complete educational stories automatically from a simple topic input, ensuring factual accuracy for children aged 5-8.

## What Changes

### Backend (ai-pipeline capability)
- **ADDED** Google ADK multi-agent pipeline with 3 agents:
  - Agent A (Researcher): Uses Google Search grounding for facts
  - Agent B (Storyteller): Creates 3-page narrative with questions
  - Agent D (Critic): Reviews content for age-appropriateness
- **ADDED** Upstash Redis caching for research results and wizard sessions
- **ADDED** New endpoint `POST /api/generate-story` for one-shot story generation
- **ADDED** Session management for wizard flow state
- **ADDED** New story metadata fields: `generation`, `target_age`, `art_style`, `critic_review`

### Frontend (creator-studio capability - deferred)
- **ADDED** AI Generate wizard modal with Topic + Art Style inputs
- UX changes are OUT OF SCOPE for initial implementation

## Impact

- **Affected specs**: `ai-pipeline` (primary), `creator-studio` (future phase)
- **Affected code**:
  - `backend/src/agents/` (new)
  - `backend/src/services/cache.ts` (new)
  - `backend/src/routes/generate-story.ts` (new)
  - `backend/package.json` (dependencies)
  - `backend/.env` (new env vars)

## Implementation Order

1. **Phase 1: Environment Setup** - API keys, npm installs, manual confirmations
2. **Phase 2: Backend Agents** - Individual agents with curl testing
3. **Phase 3: Session/Cache** - Redis setup for wizard flow state
4. **Phase 4: Integration** - Full pipeline endpoint
5. **Phase 5: UX** - Lua frontend (deferred to separate change)

## Dependencies

- `@google/adk` - Google Agent Development Kit
- `@upstash/redis` - Serverless Redis for caching

## New Environment Variables

| Variable | Purpose | Where to Get |
|----------|---------|--------------|
| `GEMINI_API_KEY` | Google AI (existing) | https://aistudio.google.com/apikey |
| `UPSTASH_REDIS_REST_URL` | Redis endpoint | https://console.upstash.com |
| `UPSTASH_REDIS_REST_TOKEN` | Redis auth | https://console.upstash.com |
