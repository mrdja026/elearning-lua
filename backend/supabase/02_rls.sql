-- LogicTales Row Level Security Policies
-- Run this AFTER 01_tables.sql in Supabase SQL Editor

-- ============================================
-- PROFILES TABLE RLS
-- ============================================

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read profiles (for author names)
CREATE POLICY "Profiles are viewable by everyone"
    ON public.profiles
    FOR SELECT
    USING (true);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Policy: Users cannot delete profiles (handled by auth cascade)
-- No DELETE policy = no manual deletion allowed

-- Policy: Insert handled by trigger, not direct insert
-- No INSERT policy for regular users

-- ============================================
-- STORIES TABLE RLS
-- ============================================

-- Enable RLS on stories
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read published stories
CREATE POLICY "Stories are viewable by everyone"
    ON public.stories
    FOR SELECT
    USING (true);

-- Policy: Only supporters can publish stories
CREATE POLICY "Supporters can insert stories"
    ON public.stories
    FOR INSERT
    WITH CHECK (
        auth.uid() = author_id
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
            AND is_supporter = true
        )
    );

-- Policy: Authors can update their own stories
CREATE POLICY "Authors can update own stories"
    ON public.stories
    FOR UPDATE
    USING (auth.uid() = author_id)
    WITH CHECK (auth.uid() = author_id);

-- Policy: Authors can delete their own stories
CREATE POLICY "Authors can delete own stories"
    ON public.stories
    FOR DELETE
    USING (auth.uid() = author_id);

-- ============================================
-- SERVICE ROLE BYPASS (for backend operations)
-- ============================================
-- Note: The service_role key bypasses RLS automatically.
-- Use anon key for client requests (respects RLS).
-- Use service_role key only for trusted backend operations.

-- ============================================
-- HELPER: Increment download count (bypasses RLS via function)
-- ============================================
CREATE OR REPLACE FUNCTION public.increment_download_count(story_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.stories
    SET downloads = downloads + 1
    WHERE id = story_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated and anon users
GRANT EXECUTE ON FUNCTION public.increment_download_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_download_count(UUID) TO anon;
