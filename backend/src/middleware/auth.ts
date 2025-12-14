import { Context, Next } from 'hono';
import { getSupabaseClient, Profile } from '../services/supabase.js';

export interface AuthContext {
  userId: string;
  profile: Profile;
}

declare module 'hono' {
  interface ContextVariableMap {
    auth: AuthContext;
  }
}

export async function authMiddleware(c: Context, next: Next) {
  // DEV_MODE: Skip auth, use mock user
  if (process.env.DEV_MODE === 'true') {
    console.log('[Auth] DEV_MODE: Using mock user');
    c.set('auth', {
      userId: 'dev-user-123',
      profile: {
        id: 'dev-user-123',
        email: 'dev@logictales.test',
        display_name: 'Dev User',
        is_supporter: true,
        created_at: new Date().toISOString(),
      },
    });
    return next();
  }

  const authHeader = c.req.header('Authorization');

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    console.log('[Auth] Missing or invalid Authorization header');
    return c.json({ error: 'Missing or invalid Authorization header' }, 401);
  }

  const token = authHeader.substring(7);

  try {
    const supabase = getSupabaseClient();

    // Verify the JWT and get user
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      console.log('[Auth] Invalid token:', authError?.message);
      return c.json({ error: 'Invalid or expired token' }, 401);
    }

    // Get profile with supporter status
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();

    if (profileError || !profile) {
      console.log('[Auth] Profile not found:', profileError?.message);
      return c.json({ error: 'User profile not found' }, 401);
    }

    console.log(`[Auth] Authenticated: ${profile.email} (supporter: ${profile.is_supporter})`);

    c.set('auth', {
      userId: user.id,
      profile: profile as Profile,
    });

    return next();
  } catch (error) {
    console.error('[Auth] Error:', error);
    return c.json({ error: 'Authentication failed' }, 500);
  }
}

export function requireSupporter(c: Context): boolean {
  const auth = c.get('auth');
  if (!auth?.profile?.is_supporter) {
    return false;
  }
  return true;
}
