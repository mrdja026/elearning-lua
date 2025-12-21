# Change: Add Interactive Story Wizard with Hint-Driven Images

## Why

The current `e2eADKFlow.sh` script uses positional command-line arguments which are error-prone and hard to remember. Additionally, the generated images use generic prompts that don't visually represent the educational concepts being taught. By making the script interactive and adding hint-driven image generation, we can:

1. Improve UX with guided parameter collection and validation
2. Generate more meaningful educational images that visually represent concepts (e.g., "if statement" → road with two forks)
3. Support commonly lacking digital skills like file management, cybersecurity, and programming basics through visual metaphors

## What Changes

### Shell Script (e2eADKFlow.sh)
- **MODIFIED** Transform from positional args to interactive guided wizard
- **ADDED** Step-by-step prompts with validation for each parameter
- **ADDED** Support for custom per-page hints that drive image generation
- **ADDED** Page count parameter (1-5 pages)

### Backend (ai-pipeline capability)
- **ADDED** `enhanceImagePromptWithHint()` function in prompt-enhancer.ts
- **ADDED** Visual metaphor generation via Gemini AI
- **ADDED** `runImageAgentWithHint()` wrapper in image-agent.ts
- **MODIFIED** Flow routes to accept `pageCount` and `pageHints` parameters
- **MODIFIED** Session type to store new fields

## Impact

- **Affected specs**: `ai-pipeline`
- **Affected code**:
  - `backend/e2eADKFlow.sh` (rewrite)
  - `backend/src/agents/prompt-enhancer.ts` (add function)
  - `backend/src/agents/image-agent.ts` (add wrapper)
  - `backend/src/routes/flow-test-routes.ts` (modify endpoints)
  - `backend/src/services/cache.ts` (update session type)

## New Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pageCount` | number (1-5) | No (default: 3) | Number of story pages to generate |
| `pageHints` | string[] | No | Hints for each page that drive image content |

## Visual Metaphor Examples

The AI will generate visual metaphors for educational concepts:

| Category | Hint | Visual Metaphor |
|----------|------|-----------------|
| Programming | "if statement" | Path splitting into two roads at a crossroads |
| Programming | "for loop" | Race car driving around a circular track |
| Cybersecurity | "phishing" | Wolf dressed as grandma (Little Red Riding Hood) |
| File Management | "folder structure" | Tree with branches, each branch is a folder |
| Finance | "compound interest" | Snowball rolling downhill, getting bigger |

See `design.md` for comprehensive list of 51 visual metaphor examples across 6 categories.
