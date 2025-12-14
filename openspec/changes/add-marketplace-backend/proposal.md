# Change: Add Marketplace Backend (Phase 4)

## Why

The game currently only supports local stories. To enable community story sharing, we need a backend marketplace API where creators can publish stories and players can browse/download them.

## What Changes

### New: Marketplace API
- `GET /api/stories` - List published stories (paginated)
- `GET /api/stories/:id` - Get single story with full JSON
- `POST /api/stories` - Publish a story (requires auth)
- `DELETE /api/stories/:id` - Remove own story
- DEV_MODE support for all endpoints (no credits/DB required)

### New: Supabase Integration
- Database tables: `profiles`, `stories`
- Row Level Security (RLS) policies
- Supabase client service
- SQL scripts in `backend/supabase/`

### New: Authentication
- Supabase Auth integration
- JWT token verification middleware
- Supporter status gate for publishing

## Deferred to Phase 5 (Marketplace Client)

- Marketplace browse screen in Love2D
- Publish button in Creator Studio
- Story download functionality

## Impact

- **New specs**: marketplace
- **New files**:
  - `backend/supabase/01_tables.sql`
  - `backend/supabase/02_rls.sql`
  - `backend/src/routes/stories.ts`
  - `backend/src/middleware/auth.ts`
  - `backend/src/services/supabase.ts`
