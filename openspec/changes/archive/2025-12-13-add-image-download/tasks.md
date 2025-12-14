## 1. Image Download Logic
- [x] 1.1 Add download function to image_thread.lua that fetches binary data from URL
- [x] 1.2 Generate unique filename based on timestamp or page ID
- [x] 1.3 Save image to `love.filesystem.getSaveDirectory()/images/` directory
- [x] 1.4 Return local file path in thread response instead of URL

## 2. Directory Management
- [x] 2.1 Create images directory on first use if it doesn't exist
- [x] 2.2 Use love.filesystem for cross-platform path handling

## 3. Error Handling
- [x] 3.1 Handle download failures (network errors, invalid URLs)
- [x] 3.2 Return appropriate error message to main thread on failure

## 4. Testing
- [ ] 4.1 Test with DEV_MODE mock URL (existing Cloudinary image)
- [ ] 4.2 Test with real generation pipeline
- [ ] 4.3 Verify image displays in preview panel after download
