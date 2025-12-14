## Context

The current system evaluates questions using binary logic (>, <, =, >=, <=) with true/false destinations. This limits educational content to comparison-based questions only.

## Goals / Non-Goals

**Goals:**
- Support free-text answer questions with exact matching
- Support multi-question pages with partial scoring
- Show feedback on incorrect answers
- Maintain backwards compatibility with existing stories

**Non-Goals:**
- Fuzzy text matching or AI-based evaluation
- Weighted scoring (all questions equal weight)
- Branching based on partial scores (only pass/fail navigation)

## Decisions

### Question Type Enum
- `binary`: Current behavior (operator comparison, two choice buttons)
- `text`: Single text input, exact match against `correct_answer`
- `multi`: Array of sub-questions, each with own answer, partial scoring

### Text Matching Strategy
- **Decision**: Exact match, case-sensitive
- **Rationale**: Simple, predictable, no edge cases
- **Alternative considered**: Case-insensitive - rejected to allow teaching case sensitivity

### Multi-Question Scoring
- **Decision**: Show all errors, require all correct to proceed to `true_destination`
- **Rationale**: User requested partial scoring with error feedback
- **Navigation**: All correct -> `true_destination_id`, any wrong -> `false_destination_id`

### Schema Addition
```lua
page = {
  -- existing fields...
  question_type = "binary" | "text" | "multi",  -- default: "binary"
  correct_answer = "string",                     -- for type "text"
  questions = {                                  -- for type "multi"
    { question_text = "...", correct_answer = "..." },
    ...
  }
}
```

## Risks / Trade-offs

- **Risk**: Exact match may frustrate users (typos fail)
  - Mitigation: Clear feedback showing expected vs actual
- **Risk**: Schema migration for existing stories
  - Mitigation: Default `question_type = "binary"` preserves existing behavior

## Migration Plan

1. Add fields with defaults (non-breaking)
2. Existing stories work unchanged
3. No data migration required

## Open Questions

- None currently
