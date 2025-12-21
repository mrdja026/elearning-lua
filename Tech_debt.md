# Tech Debt

## Known Issues

### Download requires elevated privileges (Windows)
- curl fallback for HTTPS downloads needs admin privileges on Windows
- Investigate: temp file permissions, or use a different temp directory
- Consider: bundle LuaSec with the app

### Critique agent status unknown
- We don't know if the critique agent in the backend works
- Needs testing and verification

## Future Improvements

### Autosave after changes
- Auto-save story to saves/ folder after edits
- Debounce saves to avoid excessive writes
- Show "unsaved changes" indicator

### More automation scripts
- Scripts to automate common tasks
- Build/packaging scripts
- Testing automation

## Completed
- [x] Wizard image downloads use curl fallback when LuaSec unavailable
- [x] Stories save to source directory (not LÖVE save dir)
- [x] Downloads go to images/ in source directory
