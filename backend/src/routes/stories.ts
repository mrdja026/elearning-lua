import { Hono } from 'hono';
import { authMiddleware, requireSupporter } from '../middleware/auth.js';
import { getSupabaseClient, StoryWithAuthor } from '../services/supabase.js';

export const storiesRoute = new Hono();

// Mock data for DEV_MODE
const MOCK_STORIES: StoryWithAuthor[] = [
  {
    id: 'mock-story-1',
    title: 'The Counting Forest',
    author_id: 'dev-user-123',
    author_name: 'Dev User',
    json_data: {
      title: 'The Counting Forest',
      pages: [
        {
          id: 1,
          question_type: 'yesno',
          question_text: 'Are there 3 rabbits in the forest?',
          correct_answer_is_yes: true,
          choice_labels: ['Yes', 'No'],
        },
      ],
    },
    downloads: 42,
    created_at: '2025-01-01T00:00:00Z',
  },
  {
    id: 'mock-story-2',
    title: 'Math Adventure',
    author_id: 'user-456',
    author_name: 'Story Creator',
    json_data: {
      title: 'Math Adventure',
      pages: [
        {
          id: 1,
          question_type: 'text',
          question_text: 'What is 2 + 2?',
          correct_answer: '4',
        },
      ],
    },
    downloads: 128,
    created_at: '2025-01-02T00:00:00Z',
  },
];

// GET /api/stories - List all stories (public)
storiesRoute.get('/stories', async (c) => {
  console.log('\n[Stories] GET /api/stories');

  const page = parseInt(c.req.query('page') || '1');
  const limit = Math.min(parseInt(c.req.query('limit') || '20'), 50);
  const offset = (page - 1) * limit;

  // DEV_MODE: Return mock data
  if (process.env.DEV_MODE === 'true') {
    console.log('[Stories] DEV_MODE: Returning mock stories');
    const paged = MOCK_STORIES.slice(offset, offset + limit);
    return c.json({
      success: true,
      stories: paged.map(({ json_data, ...rest }) => rest),
      pagination: {
        page,
        limit,
        total: MOCK_STORIES.length,
        hasMore: offset + limit < MOCK_STORIES.length,
      },
    });
  }

  try {
    const supabase = getSupabaseClient();

    // Get stories with author name
    const { data: stories, error, count } = await supabase
      .from('stories')
      .select(`
        id,
        title,
        author_id,
        downloads,
        created_at,
        profiles!inner(display_name)
      `, { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.error('[Stories] Database error:', error);
      return c.json({ success: false, error: 'Failed to fetch stories' }, 500);
    }

    const formattedStories = stories?.map((s: any) => ({
      id: s.id,
      title: s.title,
      author_id: s.author_id,
      author_name: s.profiles?.display_name || 'Unknown',
      downloads: s.downloads,
      created_at: s.created_at,
    })) || [];

    return c.json({
      success: true,
      stories: formattedStories,
      pagination: {
        page,
        limit,
        total: count || 0,
        hasMore: offset + limit < (count || 0),
      },
    });
  } catch (error) {
    console.error('[Stories] Error:', error);
    return c.json({ success: false, error: 'Failed to fetch stories' }, 500);
  }
});

// GET /api/stories/:id - Get single story with full JSON (public)
storiesRoute.get('/stories/:id', async (c) => {
  const id = c.req.param('id');
  console.log(`\n[Stories] GET /api/stories/${id}`);

  // DEV_MODE: Return mock data
  if (process.env.DEV_MODE === 'true') {
    console.log('[Stories] DEV_MODE: Returning mock story');
    const story = MOCK_STORIES.find((s) => s.id === id);
    if (!story) {
      return c.json({ success: false, error: 'Story not found' }, 404);
    }
    return c.json({ success: true, story });
  }

  try {
    const supabase = getSupabaseClient();

    const { data: story, error } = await supabase
      .from('stories')
      .select(`
        *,
        profiles!inner(display_name)
      `)
      .eq('id', id)
      .single();

    if (error || !story) {
      console.log('[Stories] Story not found:', id);
      return c.json({ success: false, error: 'Story not found' }, 404);
    }

    // Increment download count
    await supabase.rpc('increment_download_count', { story_id: id });

    return c.json({
      success: true,
      story: {
        id: story.id,
        title: story.title,
        author_id: story.author_id,
        author_name: (story as any).profiles?.display_name || 'Unknown',
        json_data: story.json_data,
        downloads: story.downloads + 1,
        created_at: story.created_at,
      },
    });
  } catch (error) {
    console.error('[Stories] Error:', error);
    return c.json({ success: false, error: 'Failed to fetch story' }, 500);
  }
});

// POST /api/stories - Publish a story (requires auth + supporter)
storiesRoute.post('/stories', authMiddleware, async (c) => {
  console.log('\n[Stories] POST /api/stories');

  const auth = c.get('auth');

  // Check supporter status (DEV_MODE always passes)
  if (!requireSupporter(c)) {
    console.log('[Stories] User is not a supporter');
    return c.json({ success: false, error: 'Supporters only' }, 403);
  }

  let body: { title?: string; json_data?: Record<string, unknown> };
  try {
    body = await c.req.json();
  } catch {
    return c.json({ success: false, error: 'Invalid JSON body' }, 400);
  }

  if (!body.title || !body.json_data) {
    return c.json({ success: false, error: 'Missing required fields: title, json_data' }, 400);
  }

  // DEV_MODE: Return mock response
  if (process.env.DEV_MODE === 'true') {
    console.log('[Stories] DEV_MODE: Returning mock publish response');
    const mockId = `mock-${Date.now()}`;
    return c.json({
      success: true,
      story: {
        id: mockId,
        title: body.title,
        author_id: auth.userId,
        author_name: auth.profile.display_name,
        downloads: 0,
        created_at: new Date().toISOString(),
      },
    });
  }

  try {
    const supabase = getSupabaseClient();

    const { data: story, error } = await supabase
      .from('stories')
      .insert({
        title: body.title,
        author_id: auth.userId,
        json_data: body.json_data,
      })
      .select()
      .single();

    if (error) {
      console.error('[Stories] Insert error:', error);
      return c.json({ success: false, error: 'Failed to publish story' }, 500);
    }

    console.log(`[Stories] Published: ${story.id} by ${auth.profile.email}`);

    return c.json({
      success: true,
      story: {
        id: story.id,
        title: story.title,
        author_id: story.author_id,
        author_name: auth.profile.display_name,
        downloads: 0,
        created_at: story.created_at,
      },
    });
  } catch (error) {
    console.error('[Stories] Error:', error);
    return c.json({ success: false, error: 'Failed to publish story' }, 500);
  }
});

// DELETE /api/stories/:id - Delete own story (requires auth)
storiesRoute.delete('/stories/:id', authMiddleware, async (c) => {
  const id = c.req.param('id');
  const auth = c.get('auth');
  console.log(`\n[Stories] DELETE /api/stories/${id}`);

  // DEV_MODE: Return mock response
  if (process.env.DEV_MODE === 'true') {
    console.log('[Stories] DEV_MODE: Returning mock delete response');
    return c.json({ success: true, message: 'Story deleted' });
  }

  try {
    const supabase = getSupabaseClient();

    // Check ownership
    const { data: story, error: fetchError } = await supabase
      .from('stories')
      .select('author_id')
      .eq('id', id)
      .single();

    if (fetchError || !story) {
      return c.json({ success: false, error: 'Story not found' }, 404);
    }

    if (story.author_id !== auth.userId) {
      console.log('[Stories] Unauthorized delete attempt');
      return c.json({ success: false, error: 'You can only delete your own stories' }, 403);
    }

    const { error: deleteError } = await supabase
      .from('stories')
      .delete()
      .eq('id', id);

    if (deleteError) {
      console.error('[Stories] Delete error:', deleteError);
      return c.json({ success: false, error: 'Failed to delete story' }, 500);
    }

    console.log(`[Stories] Deleted: ${id} by ${auth.profile.email}`);
    return c.json({ success: true, message: 'Story deleted' });
  } catch (error) {
    console.error('[Stories] Error:', error);
    return c.json({ success: false, error: 'Failed to delete story' }, 500);
  }
});
