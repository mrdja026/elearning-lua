## 1. Backend Setup (Hono)
- [x] 1.1 Initialize Hono project with TypeScript
- [x] 1.2 Configure `.env` for API keys (Anthropic, Stability, Cloudinary)
- [x] 1.3 Set up Cloudinary SDK
- [x] 1.4 Create project structure (routes, services, types)

## 2. Prompt Builder Service (Claude)
- [x] 2.1 Create Claude API client with Anthropic SDK
- [x] 2.2 Design system prompt for child-friendly SD prompt generation
- [x] 2.3 Implement prompt builder function (description + question → SD prompt + negative)
- [x] 2.4 Add token usage logging

## 3. Image Generation Service (Stability AI)
- [x] 3.1 Implement Stability AI Core API client
- [x] 3.2 Configure image parameters (800x600, output format)
- [x] 3.3 Handle API response (base64 image data)
- [x] 3.4 Add generation timing logs

## 4. Image Upload Service (Cloudinary)
- [x] 4.1 Implement Cloudinary upload from base64
- [x] 4.2 Configure upload preset
- [x] 4.3 Return secure_url

## 5. API Endpoint
- [x] 5.1 Create POST `/api/generate-image` route
- [x] 5.2 Validate request body (description, question required)
- [x] 5.3 Orchestrate pipeline (Claude → Stability → Cloudinary)
- [x] 5.4 Return success response with imageUrl
- [x] 5.5 Implement error handling with user-friendly messages
- [x] 5.6 Add request logging (timing, tokens, costs)

## 6. Client - Dependencies
- [x] 6.1 Add lua-https or luasec library
- [x] 6.2 Create download_thread.lua for async HTTP

## 7. Client - Creator Studio UI
- [x] 7.1 Add "Image Description" text input field to Page Editor
- [x] 7.2 Add "Generate Image" button next to image field
- [x] 7.3 Store backend URL in settings

## 8. Client - Async Generation
- [x] 8.1 Implement thread-based HTTP POST to backend
- [x] 8.2 Pass description and question_text to thread
- [x] 8.3 Handle thread response (imageUrl or error)

## 9. Client - UI Feedback
- [x] 9.1 Show loading spinner during generation
- [x] 9.2 Display error warning on failure
- [x] 9.3 Update image_path with returned URL on success
- [x] 9.4 Hot-reload preview panel with new image

## 10. Testing
- [x] 10.1 Test backend endpoint with sample requests
- [x] 10.2 Test client generation flow end-to-end
- [x] 10.3 Test error scenarios (invalid keys, rate limits)
