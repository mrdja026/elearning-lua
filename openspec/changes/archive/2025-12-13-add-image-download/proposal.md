# Change: Add Image Download from URL

## Why

The current AI pipeline returns a Cloudinary URL, but LÖVE's `love.graphics.newImage()` only loads local files. Images cannot be displayed in the preview panel until they are downloaded and saved locally. This bridges the gap between receiving a URL and actually displaying the image.

## What Changes

### Modified: Image Thread
- After receiving imageUrl from backend, download the image binary data
- Save image to `love.filesystem.getSaveDirectory()/images/`
- Return local file path instead of remote URL

### Modified: Creator Studio
- Update `image_path` with local path (not URL)
- Preview panel displays downloaded image via existing renderer

## Architecture

```
Current Flow (broken):
Backend → imageUrl → image_path = URL → renderer fails (can't load URL)

New Flow:
Backend → imageUrl → download binary → save locally → image_path = local path → renderer works
```

## Impact

- **Modified specs**: ai-pipeline (add download requirement)
- **Modified files**: image_thread.lua (add download logic)
- **No new dependencies**: Uses existing socket.http for download
