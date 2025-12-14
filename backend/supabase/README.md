# Supabase Database Setup

Run these scripts in order in the Supabase SQL Editor.

## Prerequisites

1. Create a Supabase project at https://supabase.com
2. Go to Dashboard > SQL Editor

## Scripts

### 1. `01_tables.sql` - Create Tables

Creates:
- `profiles` table (extends auth.users)
- `stories` table (marketplace stories)
- Indexes for performance
- Triggers for auto-profile creation and updated_at

### 2. `02_rls.sql` - Row Level Security

Sets up:
- **Profiles**: Anyone can read, users can update own
- **Stories**: Anyone can read, supporters can publish, authors can update/delete own
- Download count increment function

## After Running Scripts

1. Go to Dashboard > Settings > API
2. Copy these to your `.env`:
   - `SUPABASE_URL` (Project URL)
   - `SUPABASE_ANON_KEY` (anon/public key)
   - `SUPABASE_SERVICE_ROLE_KEY` (service_role key - keep secret!)

## Testing RLS

```sql
-- Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';

-- Should show: profiles (true), stories (true)
```

## Making a User a Supporter

```sql
UPDATE public.profiles
SET is_supporter = true
WHERE email = 'user@example.com';
```
