# Proposal: Simplify Editor for Educators

## Summary

Simplify the story editor for educators by removing complex logic configuration and adding story-level settings for topic and AI image generation. The goal is a cleaner, more intuitive editor that non-technical educators can use to create educational content.

## Motivation

The current Creator Studio has complexity inherited from the logic engine that educators don't need:
- **Binary question type** with variable/operator/target logic is confusing for non-programmers
- **Per-page image descriptions** require repetitive input when a consistent art style is desired
- **Destination-based navigation** requires understanding page IDs and branching logic

Educators want to:
1. Set a topic for their educational content
2. Define a consistent image style once for the whole story
3. Create simple yes/no questions with a checkbox marking the correct answer
4. Have linear story flow without configuring navigation

## Scope

### In Scope
- Add story-level `topic` and `general_image_prompt` fields
- Replace `binary` question type with simple `yesno` type
- Simplify navigation to linear flow (correct=next page, wrong=retry)
- Keep `text` and `multi` question types unchanged
- Migrate existing stories to new format

### Out of Scope
- Multiple choice (A/B/C/D) questions
- Branching story paths
- Per-page image styling

## Affected Specs
- `creator-studio` - MODIFIED (story settings UI, question type UI)
- `logic-engine` - MODIFIED (data model, navigation logic)
