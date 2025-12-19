# Design: ADK Multi-Agent Story Generation

## Context

LogicTales needs automated story generation to lower the barrier for content creation. Users should be able to enter a topic (e.g., "Why do volcanoes erupt?") and receive a complete 3-page educational story with questions, hints, and image prompts.

### Stakeholders
- **Users**: Want quick story creation without writing everything manually
- **Children (5-8)**: Need age-appropriate, factually accurate content
- **Developers**: Need curl-testable endpoints before frontend integration

### Constraints
- Must use existing GEMINI_API_KEY (Google AI Studio)
- Cannot block UI during generation (async required)
- Must support wizard flow with session state

## Goals / Non-Goals

### Goals
- One-shot story generation from topic input
- Grounded facts via Google Search (no hallucination)
- Beginner-friendly content for ages 5-8
- Curl-testable endpoints before UX work
- Session state for multi-step wizard flow

### Non-Goals
- Agent C (Artist) - pixel art generation (out of scope)
- Lua frontend changes (deferred to separate change)
- Real-time streaming responses (future enhancement)

## Decisions

### Decision 0: Reuse Existing Services

**Choice**: Reuse existing `image-uploader.ts` and `prompt-builder.ts` patterns.

**Why**:
- Cloudinary upload logic already works (`backend/src/services/image-uploader.ts`)
- Prompt builder pattern with Gemini already established (`backend/src/services/prompt-builder.ts`)
- DEV_MODE pattern already implemented in both
- Logging patterns already consistent

**Reuse Strategy**:
- `image-uploader.ts` - Use as-is for uploading generated images
- `prompt-builder.ts` - Copy pattern for agent prompts (system instruction, JSON parsing, token logging)
- `image-generator.ts` - Use as-is for Stability AI calls (cover + page images)

**What to copy/adapt**:
```typescript
// From prompt-builder.ts - reuse pattern:
- DEV_MODE mock response pattern
- JSON extraction from markdown code blocks
- Token usage logging
- Error handling with detailed logging

// From image-uploader.ts - use directly:
- uploadImage(base64Image) function
- Cloudinary configuration pattern
```

### Decision 1: Use Google ADK with SequentialAgent

**Choice**: Google ADK's `SequentialAgent` for orchestrating agents in order.

**Why**:
- Native Google Search grounding tool (`GOOGLE_SEARCH`)
- Built-in state management between agents via `outputKey`
- TypeScript support matches existing backend stack
- Works with existing `GEMINI_API_KEY`

**Alternatives considered**:
- LangChain: More complex, doesn't have native Google Search grounding
- Custom orchestration: More work, no benefit over ADK

### Decision 2: Upstash Redis for Caching + Sessions

**Choice**: Upstash Redis with in-memory fallback for dev mode.

**Why**:
- Free tier (500K commands/month) sufficient for development
- HTTP-based API works in serverless/edge environments
- Same client works locally and in cloud
- Stores both research cache AND wizard session state

**Cache Strategy**:
```
Key: story:research:{sha256(topic)}
TTL: 24 hours
Data: { facts: string[], source_urls: string[] }

Key: story:session:{sessionId}
TTL: 30 minutes
Data: { topic, artStyle, step, researchData?, storyData?, reviewData? }
```

### Decision 3: Wizard Session Flow

**Choice**: Server-side session state in Redis with client-provided session ID.

**Flow**:
```
1. POST /api/story-wizard/start
   → Creates session, returns sessionId
   → Client stores sessionId

2. POST /api/story-wizard/research
   → Agent A runs, stores research in session
   → Returns facts preview

3. POST /api/story-wizard/generate
   → Agents B + D run, stores story in session
   → Returns story preview

4. POST /api/story-wizard/complete
   → Generates images, returns final story JSON
   → Clears session
```

**Why sessions**:
- Allows step-by-step confirmation (user approves research before story)
- Enables retry of individual steps without full restart
- Supports future streaming/progressive generation

### Decision 4: Art Style Affects Image Prompts Only

**Choice**: `artStyle` parameter (pixel/fantasy/cartoon) modifies image prompts, not story content.

**Why**:
- Story content should be consistent regardless of visual style
- Image prompts include style keywords: "pixel art style", "fantasy illustration style", "cartoon style"

## Agent Specifications

### Agent A: Researcher (CPA)

```typescript
const researcher = new LlmAgent({
  name: 'ResearcherCPA',
  model: 'gemini-2.5-flash',
  tools: [GOOGLE_SEARCH],
  instruction: `You research topics for children aged 5-8.
    Use Google Search to find accurate, simple facts.
    Output 3-5 facts using short sentences, no jargon.
    Include source URLs for transparency.
    Format: { facts: string[], sourceUrls: string[] }`,
  outputKey: 'research_data'
});
```

### Agent B: Storyteller

```typescript
const storyteller = new LlmAgent({
  name: 'Storyteller',
  model: 'gemini-2.5-flash',
  instruction: `Create a 3-page educational story for ages 5-8.
    Use facts from {research_data}.
    Each page needs:
    - Story text with friendly character (~50-100 words)
    - One question (yesno or text type)
    - Hint for the question
    - Image prompt matching art style: {art_style}
    Format: { title: string, pages: Page[] }`,
  outputKey: 'story_data'
});
```

### Agent D: Critic

```typescript
const critic = new LlmAgent({
  name: 'ContentCritic',
  model: 'gemini-2.5-flash',
  instruction: `Review story for children 5-8.
    Check: age-appropriate, factually accurate, no scary content.
    DO NOT reject - only flag warnings.
    Format: { approved: boolean, warnings: string[], readabilityScore: number }`,
  outputKey: 'review_data'
});
```

## Story Schema Extensions

```typescript
interface GeneratedStory {
  // Existing fields
  title: string;
  topic: string;
  general_image_prompt: string;
  cover_image_path: string;
  pages: Page[];

  // NEW fields
  generation: {
    source: 'ai' | 'manual';
    grounded_facts: string[];
    source_urls: string[];
    timestamp: string; // ISO 8601
  };
  target_age: '5-8' | '8-12' | 'all';
  art_style: 'pixel' | 'fantasy' | 'cartoon';
  critic_review: {
    approved: boolean;
    warnings: string[];
    readability_score: number;
  };
}
```

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Google Search grounding costs | Cache research results for 24h |
| Long generation time (multiple agents) | Session flow allows partial progress |
| ADK package stability (new) | Pin version, have fallback to direct Gemini API |
| Redis connection failures | In-memory fallback for dev mode |

## Migration Plan

1. **No migration needed** - This is additive functionality
2. Existing stories remain unchanged (no `generation` field = manual)
3. New stories from wizard get `generation.source = 'ai'`

## Open Questions

1. ~~Should we store full citations or just URLs?~~ **Resolved**: URLs only
2. ~~What age groups to support?~~ **Resolved**: Start with 5-8 only
3. Should wizard allow editing research before story generation? **TBD - implement basic flow first**
