## 1. HTTP Client
- [ ] 1.1 Create `lib/http.lua` with async request support
- [ ] 1.2 Add POST method with JSON body support
- [ ] 1.3 Add error handling and timeout logic

## 2. Publish Modal Component
- [ ] 2.1 Create `components/publish_modal.lua`
- [ ] 2.2 Implement modal overlay with dimmed background
- [ ] 2.3 Add title input field (pre-filled from story)
- [ ] 2.4 Add story info display (page count, question count)
- [ ] 2.5 Add Cancel and Publish buttons
- [ ] 2.6 Implement loading state with spinner/indicator
- [ ] 2.7 Implement success state with confirmation message
- [ ] 2.8 Implement error state with retry option

## 3. Creator Studio Integration
- [ ] 3.1 Add "Publish" button to Creator Studio toolbar
- [ ] 3.2 Wire button to open publish modal
- [ ] 3.3 Pass current story data to modal
- [ ] 3.4 Handle modal close/success callbacks

## 4. API Integration
- [ ] 4.1 Connect modal to `POST /api/stories` endpoint
- [ ] 4.2 Serialize story JSON for upload
- [ ] 4.3 Handle auth token (DEV_MODE: skip auth)

## 5. Testing
- [ ] 5.1 Test modal open/close flow
- [ ] 5.2 Test publish in DEV_MODE
- [ ] 5.3 Test error handling (network failure)
