# Design: Interactive Story Wizard with Hint-Driven Images

## Context

The current story generation flow uses generic image prompts that don't visually represent the educational concepts being taught. Research shows that nearly 1 in 3 workers lack foundational digital skills, and visual metaphors can make abstract concepts more accessible.

### Problem Statement

- Shell script uses positional args: `./e2eADKFlow.sh "topic" "style" "age"` - error-prone
- Image prompts are generic: "A curious child discovering something amazing about ${topic}"
- No connection between the educational hint and the generated image

### Solution

1. Interactive guided wizard with validation
2. Hint-driven image generation using AI-generated visual metaphors
3. Comprehensive metaphor examples for common digital literacy gaps

## Goals / Non-Goals

### Goals
- Make script interactive with step-by-step prompts
- Generate images that visually represent educational concepts
- Support variable page count (1-5)
- Allow custom hints per page

### Non-Goals
- Changing the backend API structure significantly
- Adding new database tables
- Modifying the Lua frontend (deferred)

## Decisions

### Decision 1: Hint→Metaphor in Prompt Enhancer

**Choice**: Add `enhanceImagePromptWithHint()` to existing `prompt-enhancer.ts`

**Why**:
- Keeps prompt enhancement logic in one place
- Reuses existing Gemini integration patterns
- Can be tested independently via test routes

**Alternatives considered**:
- New dedicated "Visual Metaphor Agent": Too complex for this use case
- Hardcoded metaphor mappings: Not flexible enough for varied topics

### Decision 2: AI-Generated Metaphors with Few-Shot Examples

**Choice**: Use Gemini to generate metaphors, guided by 51 few-shot examples

**Why**:
- Handles novel hints not in examples
- Age-appropriate adjustments built-in
- Art style considerations included

**Risk mitigation**:
- Comprehensive few-shot examples reduce hallucination
- Fallback to generic prompts if metaphor generation fails

## Visual Metaphor System Prompt

```
You are a visual metaphor expert for children's educational content.
Given a learning hint/concept, create a concrete visual metaphor.

EXAMPLES BY CATEGORY:

## Programming Concepts
- "if statement" → "a path splitting into two different roads at a crossroads with signs"
- "for loop" → "a race car driving around a circular track multiple times"
- "while loop" → "a hamster running on a wheel until it gets tired"
- "variables" → "labeled jars or containers holding different colored items"
- "functions" → "a magic box: put something in, get something different out"
- "arrays" → "a train with numbered cars, each carrying one item"
- "debugging" → "a detective with magnifying glass searching for bugs"
- "recursion" → "Russian nesting dolls, each containing a smaller version"
- "API" → "a restaurant waiter taking orders between kitchen and customers"
- "database" → "a giant filing cabinet with many organized drawers"

## File Management & Organization
- "folder structure" → "a tree with branches, each branch is a folder"
- "file naming" → "labeled library books on organized shelves"
- "file search" → "a librarian helping find the right book"
- "saving files" → "putting a letter in a labeled envelope in a drawer"
- "file versions" → "stacked photo albums showing the same scene at different times"
- "backup" → "making a copy of your favorite toy in case you lose one"
- "cloud storage" → "magical floating boxes in the sky you can reach from anywhere"
- "file extensions" → "different shaped boxes: square for documents, round for music"

## Cybersecurity & Safety
- "password" → "a secret key that only opens your treasure chest"
- "strong password" → "a complicated lock with many unique symbols"
- "phishing" → "a wolf dressed as grandma trying to trick Little Red Riding Hood"
- "spam email" → "junk mail being thrown in a trash can by a guard"
- "two-factor authentication" → "two keys needed to open a special vault"
- "encryption" → "a secret code only you and your friend can read"
- "firewall" → "a castle wall with guards checking everyone who enters"
- "malware/virus" → "germs trying to make your computer sick"
- "VPN" → "an invisible tunnel only you can travel through"

## Internet & Networking
- "WiFi" → "invisible radio waves carrying messages through the air"
- "bandwidth" → "a highway: more lanes means more cars can travel"
- "download/upload" → "receiving a package vs sending a package"
- "URL/website address" → "a house address that tells you where to go"
- "browser" → "a magic window that shows you places around the world"
- "cookies" → "breadcrumbs websites leave to remember you visited"
- "server" → "a giant computer library that serves books to visitors"
- "cache" → "a small pocket where you keep frequently used items"

## Financial Literacy
- "budget" → "a piggy bank divided into sections for different needs"
- "interest" → "a tree that grows more fruit the longer you wait"
- "compound interest" → "snowball rolling downhill, getting bigger over time"
- "stocks" → "owning a small piece of a pizza (company)"
- "savings" → "squirrels collecting nuts for winter"
- "debt" → "borrowing toys from a friend and owing them back with extra"
- "investment" → "planting seeds today to harvest vegetables tomorrow"
- "inflation" → "same money buying fewer toys each year"

## General Computer Skills
- "copy/paste" → "making a photocopy of a drawing"
- "undo/redo" → "a time machine going back and forward"
- "keyboard shortcuts" → "secret quick paths through a maze"
- "multitasking" → "a juggler keeping multiple balls in the air"
- "software update" → "giving your computer new superpowers"
- "restart" → "waking up refreshed after a good night's sleep"
- "RAM vs storage" → "desk space (RAM) vs filing cabinet (storage)"
- "CPU" → "the brain of the computer thinking and making decisions"

The metaphor must be:
1. Visually concrete (can be drawn/illustrated)
2. Age-appropriate for {targetAge}
3. Related to the topic: {topic}
4. Suitable for {artStyle} art style
5. Culturally neutral and universally understood

OUTPUT FORMAT (JSON only, no markdown):
{
  "visual_metaphor": "description of the visual metaphor scene",
  "enhanced_prompt": "full enhanced prompt incorporating the metaphor",
  "negative_prompt": "standard negative prompt for quality"
}
```

## Interactive Wizard Flow

```
┌─────────────────────────────────────────────────────────────┐
│  LogicTales Story Generator                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Step 1/6: What topic would you like to teach?              │
│  (e.g., "how computers work", "why is the sky blue")        │
│  > _                                                        │
│                                                             │
│  Step 2/6: Choose an art style                              │
│  [1] pixel   [2] fantasy   [3] cartoon                      │
│  > _                                                        │
│                                                             │
│  Step 3/6: Target age group                                 │
│  [1] 5-8   [2] 8-12   [3] 13-17   [4] 18+   [5] all        │
│  > _                                                        │
│                                                             │
│  Step 4/6: How many pages? (1-5, default: 3)                │
│  > _                                                        │
│                                                             │
│  Step 5/6: Enter a hint for each page                       │
│  (The hint guides what the image will show)                 │
│                                                             │
│  Page 1 hint: _                                             │
│  Page 2 hint: _                                             │
│  Page 3 hint: _                                             │
│                                                             │
│  Step 6/6: Review and confirm                               │
│  ─────────────────────────────────────────                  │
│  Topic:     how computers work                              │
│  Style:     pixel                                           │
│  Age:       8-12                                            │
│  Pages:     3                                               │
│  Hints:     [if statement, for loop, variables]             │
│  ─────────────────────────────────────────                  │
│  Generate story? [y/n] > _                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Validation Rules

| Parameter | Validation | Error Message |
|-----------|------------|---------------|
| topic | non-empty, min 3 chars | "Topic must be at least 3 characters" |
| artStyle | pixel\|fantasy\|cartoon | "Invalid art style. Choose: pixel, fantasy, cartoon" |
| targetAge | 5-8\|8-12\|13-17\|18+\|all | "Invalid age group. Choose: 5-8, 8-12, 13-17, 18+, all" |
| pageCount | integer 1-5 | "Page count must be between 1 and 5" |
| hints | non-empty per page | "Hint for page N cannot be empty" |

## API Changes

### POST /api/flow-test/start

**Before:**
```json
{
  "topic": "string",
  "artStyle": "string",
  "targetAge": "string"
}
```

**After:**
```json
{
  "topic": "string",
  "artStyle": "string",
  "targetAge": "string",
  "pageCount": 3,
  "pageHints": ["if statement", "for loop", "variables"]
}
```

### Session Type Update

```typescript
interface WizardSession {
  // existing fields...
  pageCount: number;        // NEW
  pageHints: string[];      // NEW
}
```

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| AI generates poor metaphors | 51 few-shot examples + fallback to generic |
| Interactive mode breaks automation | Keep positional args as optional fallback |
| Long generation time with hints | Parallel processing where possible |
