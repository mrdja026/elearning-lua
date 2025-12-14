## 1. Database Setup
- [ ] 1.1 Create Supabase project (or use existing)
- [ ] 1.2 Run `backend/supabase/01_tables.sql` in SQL Editor
- [ ] 1.3 Run `backend/supabase/02_rls.sql` in SQL Editor
- [x] 1.4 Add Supabase credentials to `.env.example`

## 2. Backend Services
- [x] 2.1 Install `@supabase/supabase-js` dependency
- [x] 2.2 Create `backend/src/services/supabase.ts` client
- [x] 2.3 Create `backend/src/middleware/auth.ts` JWT verification

## 3. Backend Routes
- [x] 3.1 Create `backend/src/routes/stories.ts`
- [x] 3.2 Implement `GET /api/stories` (list with pagination)
- [x] 3.3 Implement `GET /api/stories/:id` (single story)
- [x] 3.4 Implement `POST /api/stories` (publish with auth)
- [x] 3.5 Implement `DELETE /api/stories/:id` (delete own)
- [x] 3.6 Add DEV_MODE mock responses for all routes
- [x] 3.7 Register routes in `index.ts`

## 4. Testing
- [ ] 4.1 Test all endpoints in DEV_MODE
- [ ] 4.2 Test with real Supabase (optional)

---

## DEFERRED TO NEXT CYCLE (Phase 5: Marketplace Client)

These tasks are for the Love2D client integration, deferred to Phase 5:

- [ ] Create `screens/marketplace.lua` browse screen
- [ ] Create `components/story_card.lua` for story display
- [ ] Add HTTP client for marketplace API calls
- [ ] Add download functionality (save to stories folder)
- [ ] Add publish button to Creator Studio
- [ ] Add mode switching (Play/Create/Marketplace)
- [ ] Test end-to-end publish/download flow
