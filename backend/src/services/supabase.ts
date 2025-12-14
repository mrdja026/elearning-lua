import { createClient, SupabaseClient } from '@supabase/supabase-js';

let supabase: SupabaseClient | null = null;

export function getSupabaseClient(): SupabaseClient {
  if (supabase) return supabase;

  const url = process.env.SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !serviceKey) {
    throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  }

  supabase = createClient(url, serviceKey);
  return supabase;
}

export function getSupabaseAnonClient(): SupabaseClient {
  const url = process.env.SUPABASE_URL;
  const anonKey = process.env.SUPABASE_ANON_KEY;

  if (!url || !anonKey) {
    throw new Error('Missing SUPABASE_URL or SUPABASE_ANON_KEY');
  }

  return createClient(url, anonKey);
}

export interface Profile {
  id: string;
  email: string;
  display_name: string | null;
  is_supporter: boolean;
  created_at: string;
}

export interface Story {
  id: string;
  title: string;
  author_id: string;
  json_data: Record<string, unknown>;
  downloads: number;
  created_at: string;
}

export interface StoryWithAuthor extends Story {
  author_name: string;
}
