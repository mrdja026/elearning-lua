# Change: Add Flexible Question Types

## Why

Currently the system only supports binary true/false logic evaluation (comparison operators). Users need more expressive question formats including free-text answers, multi-question pages with partial scoring, and explicit single-question modes.

## What Changes

- Add new question type field to page schema: `binary` (current), `text`, `multi`
- Add free-text answer evaluation with exact string matching
- Add multi-question support with partial scoring and error feedback
- Update Creator Studio UI to configure question types and answers
- **BREAKING**: Page schema adds required `question_type` field (defaults to `binary` for backwards compatibility)

## Impact

- Affected specs: logic-engine, creator-studio
- Affected code: logic.lua, renderer.lua, editor.lua, page schema
