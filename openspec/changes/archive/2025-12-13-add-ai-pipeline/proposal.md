# Change: Add AI Image Generation Pipeline

## Why

Phase 3 of the LogicTales roadmap requires AI-generated images for stories. This enables creators to generate illustrations without manual asset creation, making the Creator Studio more powerful and accessible.

## What Changes

### New: Hono Backend API
- POST `/api/generate-image` endpoint
- Multi-step pipeline: Claude (prompt builder) → Stability AI (image gen) → Cloudinary (hosting)
- Server-side API keys via `.env`
- Comprehensive logging (tokens, timing, costs)

### Modified: Creator Studio
- Add "Image Description" text field for each page
- Add "Generate Image" button
- Async HTTP calls via `love.thread`
- Loading spinner during generation
- Error display for service failures

## Architecture

```
LÖVE Client                         Hono Backend
    │                                    │
    │ POST /api/generate-image           │
    │ { description, question }  ──────▶ │
    │                                    │ 1. Claude API (haiku)
    │                                    │    → Build SD prompt + negative
    │                                    │
    │                                    │ 2. Stability AI Core
    │                                    │    → Generate 800x600 image
    │                                    │
    │                                    │ 3. Cloudinary Upload
    │                                    │    → Return secure_url
    │                                    │
    │ ◀────────────────────────────────  │
    │ { imageUrl } or { error }          │
```

## Technical Details

| Component | Technology | Notes |
|-----------|------------|-------|
| Prompt Builder | Claude 3 Haiku | Cheapest, optimizes for child-friendly SD prompts |
| Image Generation | Stability AI Core | `api.stability.ai/v2beta/stable-image/generate/core` |
| Image Hosting | Cloudinary | `upload_preset: 'ml_default'` |
| Client HTTP | love.thread + lua-https | Non-blocking async calls |

## Impact

- **New specs**: ai-pipeline (backend)
- **Modified specs**: creator-studio (client UI)
- **New files**: Hono backend project, download_thread.lua
- **Dependencies**: lua-https or luasec for HTTPS

## Configuration

Backend `.env` requires:
```
ANTHROPIC_API_KEY=sk-ant-...
STABILITY_API_KEY=sk-...
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
```
