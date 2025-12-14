# Backend API Testing Guide

## Configuration Notes

- **Gemini Model**: `gemini-2.5-flash-lite` (configured in `src/services/prompt-builder.ts`)
- **Image Aspect Ratio**: `3:2` landscape format (configured in `src/services/image-generator.ts`)
- Valid aspect ratios: `21:9`, `16:9`, `3:2`, `5:4`, `1:1`, `4:5`, `2:3`, `9:16`, `9:21`

## Development Mode (DEV_MODE)

Set `DEV_MODE=true` in `.env` to skip all API calls and return mock responses:

```
DEV_MODE=true
```

When enabled:
- **All endpoints** return instantly without calling Gemini, Stability AI, or Cloudinary
- **Mock image URL**: `https://res.cloudinary.com/dvzbmvrxs/image/upload/v1765646051/logictales/sormpv8m1skh5a18o6uf.png`
- **No API credits consumed**
- Useful for UI development and testing client integration

To use real APIs, set `DEV_MODE=false` or remove the line.

## Prerequisites

### Environment Setup
1. Copy `.env.example` to `.env` and fill in your API keys:
   ```
   GEMINI_API_KEY=your-gemini-key
   STABILITY_API_KEY=your-stability-key
   CLOUDINARY_CLOUD_NAME=your-cloud-name
   CLOUDINARY_API_KEY=your-cloudinary-key
   CLOUDINARY_API_SECRET=your-cloudinary-secret
   ```

2. Install dependencies:
   ```bash
   cd backend
   npm install
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

4. Verify server is running:
   ```bash
   curl http://localhost:3000/
   ```
   Expected: `{"message":"LogicTales AI Pipeline API"}`

---

## Test 1: Cloudinary Upload

Tests the Cloudinary integration by uploading a tiny test image.

### Command
```bash
curl http://localhost:3000/api/test-upload
```

### Acceptance Criteria
- Response status: `200 OK`
- Response contains `"success": true`
- Response contains `"imageUrl"` starting with `https://res.cloudinary.com/`
- Response contains `"publicId"` with format `logictales/xxxxx`

### Expected Response
```json
{
  "success": true,
  "imageUrl": "https://res.cloudinary.com/your-cloud/image/upload/v123/logictales/abc123.png",
  "publicId": "logictales/abc123"
}
```

### Negative Criteria
| Error | Cause | Response |
|-------|-------|----------|
| Missing credentials | `CLOUDINARY_*` env vars not set | `{"success":false,"error":"..."}` with 500 |
| Invalid credentials | Wrong API key/secret | `{"success":false,"error":"..."}` with 500 |

---

## Test 2: Prompt Generation (Gemini)

Tests the Gemini API integration for prompt enhancement.

### Command
```bash
curl -X POST http://localhost:3000/api/test-prompt \
  -H "Content-Type: application/json" \
  -d "{\"description\":\"A magical forest with talking animals\",\"question\":\"How many rabbits are hiding behind the tree?\"}"
```

### Acceptance Criteria
- Response status: `200 OK`
- Response contains `"success": true`
- Response contains `"prompt"` with children's book illustration keywords
- Response contains `"negative_prompt"` with safety terms (scary, violent, nsfw, etc.)
- Response contains `"tokens"` with `input` and `output` counts > 0

### Expected Response
```json
{
  "success": true,
  "prompt": "A whimsical enchanted forest scene with friendly talking woodland animals, cute rabbits peeking from behind a large oak tree, children's book illustration style, soft pastel watercolors, warm inviting atmosphere, educational counting theme",
  "negative_prompt": "scary, dark, violent, realistic, photographic, nsfw, horror, blood, weapons, creepy, nightmare",
  "tokens": {
    "input": 245,
    "output": 87
  }
}
```

### Negative Criteria
| Error | Cause | Response |
|-------|-------|----------|
| Missing fields | No `description` or `question` in body | `{"error":"Missing required fields: description and question"}` with 400 |
| Invalid API key | `GEMINI_API_KEY` not set or invalid | `{"success":false,"error":"..."}` with 500 |
| Empty body | No JSON body sent | `{"error":"Missing required fields..."}` with 400 |
| Quota exceeded | Free tier limit reached | `{"success":false,"error":"...429 Too Many Requests...quota exceeded..."}` with 500 |
| Model not found | Invalid model name in code | `{"success":false,"error":"...404 Not Found..."}` with 500 |

---

## Test 3: Image Generation (Stability AI)

Tests the Stability AI integration for image generation. **Note: This consumes API credits.**

### Command
```bash
curl -X POST http://localhost:3000/api/test-image \
  -H "Content-Type: application/json" \
  -d "{\"prompt\":\"A cheerful cartoon forest with three cute rabbits hiding behind a large oak tree, children's book illustration, soft watercolors, bright colors\"}"
```

### With Custom Negative Prompt
```bash
curl -X POST http://localhost:3000/api/test-image \
  -H "Content-Type: application/json" \
  -d "{\"prompt\":\"A cheerful cartoon forest with rabbits\",\"negative_prompt\":\"scary, dark, realistic, photographic\"}"
```

### Acceptance Criteria
- Response status: `200 OK`
- Response contains `"success": true`
- Response contains `"imageUrl"` starting with `https://res.cloudinary.com/`
- Response contains `"durationMs"` (typically 3000-15000ms)
- Image URL is accessible and displays a valid PNG image

### Expected Response
```json
{
  "success": true,
  "imageUrl": "https://res.cloudinary.com/your-cloud/image/upload/v123/logictales/xyz789.png",
  "durationMs": 8432
}
```

### Negative Criteria
| Error | Cause | Response |
|-------|-------|----------|
| Missing prompt | No `prompt` in body | `{"error":"Missing required field: prompt"}` with 400 |
| Invalid API key | `STABILITY_API_KEY` not set or invalid | `{"success":false,"error":"Stability AI error: 401..."}` with 500 |
| Insufficient credits | Stability AI account out of credits | `{"success":false,"error":"Stability AI error: 402..."}` with 500 |
| Content policy | Prompt violates content policy | `{"success":false,"error":"Stability AI error: 400..."}` with 500 |
| Invalid aspect ratio | Unsupported ratio in code | `{"success":false,"error":"Stability AI error: 400 - invalid enum value..."}` with 500 |

---

## Test 4: Full Pipeline

Tests the complete flow: Gemini prompt enhancement → Stability AI image generation → Cloudinary upload.

### Command
```bash
curl -X POST http://localhost:3000/api/generate-image \
  -H "Content-Type: application/json" \
  -d "{\"description\":\"A magical forest with talking animals\",\"question\":\"How many rabbits are hiding behind the tree?\"}"
```

### Acceptance Criteria
- Response status: `200 OK`
- Response contains `"success": true`
- Response contains `"imageUrl"` starting with `https://res.cloudinary.com/`
- Response contains `"metadata"` object with:
  - `totalDurationMs` (typically 5000-20000ms)
  - `promptTokens.input` > 0
  - `promptTokens.output` > 0
  - `generatedPrompt` containing the enhanced prompt

### Expected Response
```json
{
  "success": true,
  "imageUrl": "https://res.cloudinary.com/your-cloud/image/upload/v123/logictales/full123.png",
  "metadata": {
    "totalDurationMs": 12543,
    "promptTokens": {
      "input": 245,
      "output": 92
    },
    "generatedPrompt": "A whimsical enchanted forest scene..."
  }
}
```

### Negative Criteria
| Error | Cause | Response |
|-------|-------|----------|
| Missing fields | No `description` or `question` | `{"error":"Missing required fields: description and question"}` with 400 |
| Service unavailable | Any API fails | `{"success":false,"error":"Service not available, check usage and keys"}` with 500 |

---

## Server Logs

All endpoints produce detailed console logs. Monitor the server terminal for:

```
========================================
[API] POST /api/generate-image
[API] Timestamp: 2025-12-13T10:30:00.000Z
[API] Description: A magical forest...
[API] Question: How many rabbits...

[API] Step 1: Building prompt...
[PromptBuilder] Calling Gemini API...
[PromptBuilder] Completed in 1234ms
[PromptBuilder] Tokens - Input: 245, Output: 92
[API] Generated prompt: A whimsical enchanted...

[API] Step 2: Generating image...
[ImageGenerator] Calling Stability AI Core...
[ImageGenerator] Completed in 8432ms
[ImageGenerator] Image size: 524288 bytes

[API] Step 3: Uploading image...
[ImageUploader] Uploading to Cloudinary...
[ImageUploader] Completed in 876ms
[ImageUploader] URL: https://res.cloudinary.com/...

[API] ===== SUMMARY =====
[API] Total duration: 10542ms
[API] Claude tokens - Input: 245, Output: 92
[API] Image generation: 8432ms
[API] Image URL: https://res.cloudinary.com/...
========================================
```

---

## Quick Validation Checklist

| # | Test | Command | Pass Criteria |
|---|------|---------|---------------|
| 0 | Server health | `curl localhost:3000/` | Returns API message |
| 1 | Cloudinary | `curl localhost:3000/api/test-upload` | Returns imageUrl |
| 2 | Gemini | `curl -X POST ... /api/test-prompt` | Returns prompt + tokens |
| 3 | Stability AI | `curl -X POST ... /api/test-image` | Returns imageUrl |
| 4 | Full pipeline | `curl -X POST ... /api/generate-image` | Returns imageUrl + metadata |
| 5 | List stories | `curl localhost:3000/api/stories` | Returns stories array |
| 6 | Get story | `curl localhost:3000/api/stories/mock-story-1` | Returns story with json_data |
| 7 | Publish story | `curl -X POST ... /api/stories` | Returns new story id |
| 8 | Delete story | `curl -X DELETE ... /api/stories/:id` | Returns success |

---

## Test 5: List Stories (Marketplace)

Lists all published stories from the marketplace.

### Command
```bash
curl http://localhost:3000/api/stories
```

### With Pagination
```bash
curl "http://localhost:3000/api/stories?page=1&limit=10"
```

### Expected Response (DEV_MODE)
```json
{
  "success": true,
  "stories": [
    {
      "id": "mock-story-1",
      "title": "The Counting Forest",
      "author_id": "dev-user-123",
      "author_name": "Dev User",
      "downloads": 42,
      "created_at": "2025-01-01T00:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 2,
    "hasMore": false
  }
}
```

---

## Test 6: Get Single Story

Retrieves a single story with full JSON data for download.

### Command
```bash
curl http://localhost:3000/api/stories/mock-story-1
```

### Expected Response (DEV_MODE)
```json
{
  "success": true,
  "story": {
    "id": "mock-story-1",
    "title": "The Counting Forest",
    "author_id": "dev-user-123",
    "author_name": "Dev User",
    "json_data": {
      "title": "The Counting Forest",
      "pages": [...]
    },
    "downloads": 42,
    "created_at": "2025-01-01T00:00:00Z"
  }
}
```

### Negative Criteria
| Error | Cause | Response |
|-------|-------|----------|
| Story not found | Invalid ID | `{"success":false,"error":"Story not found"}` with 404 |

---

## Test 7: Publish Story

Publishes a new story to the marketplace. Requires authentication (bypassed in DEV_MODE).

### Command
```bash
curl -X POST http://localhost:3000/api/stories \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"My Test Story\",\"json_data\":{\"title\":\"My Test Story\",\"pages\":[{\"id\":1,\"question_type\":\"yesno\",\"question_text\":\"Is this a test?\",\"correct_answer_is_yes\":true}]}}"
```

### Expected Response (DEV_MODE)
```json
{
  "success": true,
  "story": {
    "id": "mock-1234567890",
    "title": "My Test Story",
    "author_id": "dev-user-123",
    "author_name": "Dev User",
    "downloads": 0,
    "created_at": "2025-..."
  }
}
```

### Negative Criteria
| Error | Cause | Response |
|-------|-------|----------|
| Missing fields | No title or json_data | `{"success":false,"error":"Missing required fields: title, json_data"}` with 400 |
| Unauthorized | No auth header (real mode) | `{"error":"Missing or invalid Authorization header"}` with 401 |
| Non-supporter | User not a supporter (real mode) | `{"success":false,"error":"Supporters only"}` with 403 |

---

## Test 8: Delete Story

Deletes a story you own. Requires authentication (bypassed in DEV_MODE).

### Command
```bash
curl -X DELETE http://localhost:3000/api/stories/mock-story-1
```

### Expected Response (DEV_MODE)
```json
{
  "success": true,
  "message": "Story deleted"
}
```

### Negative Criteria
| Error | Cause | Response |
|-------|-------|----------|
| Not found | Invalid story ID | `{"success":false,"error":"Story not found"}` with 404 |
| Forbidden | Not your story (real mode) | `{"success":false,"error":"You can only delete your own stories"}` with 403 |

---

## Running Backend + Love2D Together

Use the `dev.bat` script in the project root to start both services:

```bash
# From project root (C:\Users\...\eai-learning)
dev.bat
```

This will:
1. Start the backend with `DEV_MODE=true` (no API credits consumed)
2. Start the Love2D game

### Manual Start

**Terminal 1 - Backend:**
```bash
cd backend
set DEV_MODE=true
npm run dev
```

**Terminal 2 - Love2D:**
```bash
cd ..
love .
```

---

## Love2D HTTP Integration

The Love2D game uses `image_thread.lua` for async HTTP requests. Here's how it works:

### Architecture
```
main.lua (UI)
    ↓ love.thread.newThread()
image_thread.lua (HTTP worker)
    ↓ lua-https / luasec
Backend API (localhost:3000)
```

### Making HTTP Requests from Lua

**Current implementation** (`image_thread.lua`):
```lua
local https = require("https")  -- or require("ssl.https")

-- POST request example
local response_body = {}
local res, code = https.request{
    url = "http://localhost:3000/api/generate-image",
    method = "POST",
    headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = #json_body
    },
    source = ltn12.source.string(json_body),
    sink = ltn12.sink.table(response_body)
}
```

### Testing Backend from Lua Console

You can test the backend connection using Love2D's console:

```lua
-- In main.lua or love.load(), add a test:
local json = require("libraries.json")
local https = require("https")
local ltn12 = require("ltn12")

function testBackend()
    local response = {}
    local res, code = https.request{
        url = "http://localhost:3000/api/stories",
        sink = ltn12.sink.table(response)
    }
    if code == 200 then
        local data = json.decode(table.concat(response))
        print("Stories count:", #data.stories)
    else
        print("Backend error:", code)
    end
end
```

### Marketplace API Endpoints Summary

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/stories` | GET | No | List all stories |
| `/api/stories/:id` | GET | No | Get single story with JSON |
| `/api/stories` | POST | Yes* | Publish a story |
| `/api/stories/:id` | DELETE | Yes* | Delete own story |

*Auth bypassed in DEV_MODE
