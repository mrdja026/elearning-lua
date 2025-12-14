# Project Context

## Purpose

**LogicTales** is an educational children's game that combines storytelling with logic puzzles. Users can:

1. **Play** through interactive stories with branching paths based on math/logic decisions
2. **Create** their own stories using a built-in Creator Studio with AI-generated images
3. **Share** stories via an online marketplace

The goal is to make learning logic fun through narrative-driven gameplay.

## Tech Stack

### Client (Game Engine)

- **LÖVE (Love2D)** - Lua-based 2D game framework
- **Slab** - Immediate Mode GUI library for Creator Dashboard
- **lua-https** (or luasec) - HTTPS networking for API calls
- **rxi/json** - JSON serialization for story files
- **love.thread** - Built-in async management for non-blocking operations

### Backend

- **Hono** - TypeScript web framework for API
- **Supabase** - PostgreSQL database with authentication

### External Services - (BYOK model)

- **OpenAI DALL-E 3** - AI image generation
- **Must support other integrations** (e.g., Stable Diffusion)

## Project Conventions

### Code Style

- **Lua (LÖVE client)**: Use local variables, descriptive names, avoid `loadstring` for security
- **TypeScript (Hono backend)**: Standard TypeScript conventions
- Libraries stored in `libraries/` folder

## Coding standards

- **Lua**: Use local variables, descriptive names, avoid `loadstring` for security
- **TypeScript**: Standard TypeScript conventions
- **Documentation**: Do not document small functions (use descriptive names instead)
- **Best practices**: Follow Lua and TypeScript best practices, YAGNI, KISS, DRY but don't over-engineer

### Architecture Patterns

- **5-Phase Development**: Core Engine → Creator UI → AI Pipeline → Backend → Marketplace Integration
- **Data-First**: Define JSON schema before implementation
- **Threaded Networking**: All HTTP requests run in separate threads to prevent UI freezing
- **BYOK (Bring Your Own Key)**: Users provide their own OpenAI API key

### Testing Strategy

- Test game logic processor independently with various conditions
- Validate JSON story files against schema
- Test API endpoints before client integration

### Git Workflow

- Exclude `settings.json` (contains API keys) from version control
- Phase-based feature branches recommended

## Domain Context

### Story Structure

A story consists of **Pages** with:

- `image_path` - Path to illustration
- `question_text` - Text displayed to player
- `variable_name` - Logic variable (e.g., "apples")
- `variable_value` - Current value
- `condition` - Logic expression (e.g., "> 3")
- `true_destination_id` / `false_destination_id` - Branching paths

### User Types

- **Players**: Play downloaded/local stories
- **Creators**: Build stories using Creator Studio
- **Supporters**: Can publish to marketplace (monetization gate)

## Important Constraints

- LÖVE cannot make HTTPS requests natively (requires lua-https)
- AI image generation takes 5-10 seconds (must be async)
- No `loadstring` for logic evaluation (security risk)
- API keys must be stored securely, never committed to git
- Images saved to `love.filesystem.getSaveDirectory()`

## External Dependencies

| Service        | Purpose                   | Notes                                       |
| -------------- | ------------------------- | ------------------------------------------- |
| **OpenAI API** | DALL-E 3 image generation | User provides own key                       |
| **Supabase**   | Database + Auth           | Tables: `users`, `stories`                  |
| **Hono API**   | Story marketplace         | GET /stories, POST /publish, GET /story/:id |

## Development Phases

1. **Phase 1**: Logic Engine (Player Mode) - JSON parsing, state management, rendering
2. **Phase 2**: Creator Studio (UI) - Slab integration, page editor, asset management
3. **Phase 3**: AI Pipeline - OpenAI integration, image generation threads
4. **Phase 4**: Backend - Hono + Supabase marketplace API
5. **Phase 5**: Marketplace Client - Browse, download, publish stories
