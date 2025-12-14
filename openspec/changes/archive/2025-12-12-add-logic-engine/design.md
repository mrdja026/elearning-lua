# Design: Logic Engine

## Context

This is Phase 1 of LogicTales - the core engine that powers all gameplay. The engine must be simple, secure, and extensible for future phases (Creator Studio, AI Pipeline).

## Goals / Non-Goals

**Goals:**
- Parse and validate story JSON files
- Manage game state (current page, variables)
- Evaluate logic conditions safely
- Render pages with questions and branching choices

**Non-Goals:**
- No UI framework yet (Phase 2 adds Slab)
- No networking (Phase 3+)
- No story creation interface yet

## Decisions

### Decision 1: Safe Condition Parsing

**What:** Use a simple parser instead of Lua's `loadstring`

**Why:** `loadstring` is a security risk - malicious story files could execute arbitrary code

**Implementation:**
```lua
local function evaluateCondition(operator, currentValue, targetValue)
    if operator == ">" then return currentValue > targetValue
    elseif operator == "<" then return currentValue < targetValue
    elseif operator == "=" then return currentValue == targetValue
    elseif operator == ">=" then return currentValue >= targetValue
    elseif operator == "<=" then return currentValue <= targetValue
    end
    return false
end
```

### Decision 2: Page Schema Structure

**What:** Each page is a Lua table with defined fields

```lua
Page = {
    id = 1,                          -- unique identifier
    image_path = "images/page1.png", -- path to illustration
    question_text = "How many apples are left?",
    hint_text = "Count carefully!",  -- optional
    variable_name = "apples",        -- variable being tested
    variable_value = 4,              -- value to set/check
    operator = ">",                  -- comparison operator
    target_value = 3,                -- value to compare against
    true_destination_id = 2,         -- page if condition true
    false_destination_id = 3,        -- page if condition false
    choice_labels = {"Yes", "No"}    -- button text (optional)
}
```

### Decision 3: State Management

**What:** Centralized game state table

```lua
GameState = {
    current_page_id = 1,
    variables = {},        -- e.g., { apples = 4, coins = 10 }
    story = nil,           -- loaded story data
    is_finished = false,
    result = nil           -- "win" or "lose"
}
```

## Data Flow

```
story.json → json.decode() → story table
                                  ↓
                            GameState.story
                                  ↓
                            getCurrentPage()
                                  ↓
                            renderer.draw()
                                  ↓
                         user makes choice
                                  ↓
                         logic.evaluate()
                                  ↓
                      navigate to next page
```

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| JSON parsing errors | Wrap in pcall, show friendly error |
| Invalid page references | Validate story on load, check destinations exist |
| Missing variables | Initialize variables from story metadata |

## File Structure

```
eai-learning/
├── main.lua           # LÖVE entry point
├── conf.lua           # LÖVE configuration
├── schema.lua         # Page structure definition
├── gamestate.lua      # State management
├── logic.lua          # Condition evaluator
├── renderer.lua       # Drawing functions
├── libraries/
│   └── json.lua       # rxi/json library
└── stories/
    └── test_story.json
```

## Open Questions

- Should we support multiple stories loaded at once? (Probably not for Phase 1)
- Image format preference? (PNG recommended for LÖVE)
