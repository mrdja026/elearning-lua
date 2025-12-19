## 1. Spec Updates
- [x] 1.1 Update story-frame spec to remove backwards compatibility exception
- [x] 1.2 Add unified preview display requirement to creator-studio spec

## 2. Implementation
- [x] 2.1 Refactor PlayScreen.draw() to accept displayMode parameter ("STORY" | "PAGE")
- [x] 2.2 Unify drawStoryFrame() logic into main draw() with STORY mode
- [x] 2.3 Update config preview to use PlayScreen with appropriate mode
- [x] 2.4 Enforce cover gating for all stories (remove legacy exception)

## 3. Testing
- [x] 3.1 Test new story flow: cover required before pages
- [x] 3.2 Test config preview shows cover in STORY mode
- [x] 3.3 Test config preview shows page image in PAGE mode
- [x] 3.4 Test old stories load correctly (cover gating still applies)
