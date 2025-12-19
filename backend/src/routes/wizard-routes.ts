import { Hono } from 'hono';
import { runResearcher } from '../agents/researcher.js';
import { runStoryteller } from '../agents/storyteller.js';
import { runCritic } from '../agents/critic.js';
import {
  createSession,
  getSession,
  updateSession,
  deleteSession,
  getCachedResearch,
  setCachedResearch,
} from '../services/cache.js';
import type { ArtStyle, ResearchData } from '../types/story.js';

export const wizardRoutes = new Hono();

// Step 1: Start wizard session
wizardRoutes.post('/start', async (c) => {
  console.log('\n========================================');
  console.log('[Wizard] POST /api/story-wizard/start');

  try {
    const body = await c.req.json<{ topic: string; artStyle?: ArtStyle }>();

    if (!body.topic) {
      return c.json({ error: 'Missing required field: topic' }, 400);
    }

    const artStyle = body.artStyle || 'fantasy';

    console.log(`[Wizard] Topic: "${body.topic}"`);
    console.log(`[Wizard] Art style: ${artStyle}`);

    const session = await createSession(body.topic, artStyle);

    console.log(`[Wizard] Session created: ${session.id}`);
    console.log('========================================\n');

    return c.json({
      success: true,
      sessionId: session.id,
      topic: session.topic,
      artStyle: session.artStyle,
      step: session.step,
    });
  } catch (error) {
    console.error('[Wizard] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Step 2: Run research
wizardRoutes.post('/research', async (c) => {
  const startTime = Date.now();
  console.log('\n========================================');
  console.log('[Wizard] POST /api/story-wizard/research');

  try {
    const body = await c.req.json<{ sessionId: string }>();

    if (!body.sessionId) {
      return c.json({ error: 'Missing required field: sessionId' }, 400);
    }

    const session = await getSession(body.sessionId);
    if (!session) {
      return c.json({ error: 'Session not found or expired' }, 404);
    }

    if (session.step !== 'started') {
      return c.json({ error: `Invalid step: expected 'started', got '${session.step}'` }, 400);
    }

    console.log(`[Wizard] Session: ${session.id}`);
    console.log(`[Wizard] Topic: "${session.topic}"`);

    // Check cache first
    let researchData: ResearchData | null = await getCachedResearch(session.topic);
    let cached = false;

    if (researchData) {
      console.log('[Wizard] Using cached research');
      cached = true;
    } else {
      console.log('[Wizard] Running Researcher agent...');
      const result = await runResearcher(session.topic);
      researchData = {
        facts: result.facts,
        sourceUrls: result.sourceUrls,
      };
      await setCachedResearch(session.topic, researchData);
    }

    // Update session
    await updateSession(session.id, {
      step: 'researched',
      researchData,
    });

    console.log(`[Wizard] Research complete (${researchData.facts.length} facts, cached: ${cached})`);
    console.log(`[Wizard] Duration: ${Date.now() - startTime}ms`);
    console.log('========================================\n');

    return c.json({
      success: true,
      sessionId: session.id,
      step: 'researched',
      cached,
      research: researchData,
    });
  } catch (error) {
    console.error('[Wizard] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Step 3: Generate story
wizardRoutes.post('/story', async (c) => {
  const startTime = Date.now();
  console.log('\n========================================');
  console.log('[Wizard] POST /api/story-wizard/story');

  try {
    const body = await c.req.json<{ sessionId: string }>();

    if (!body.sessionId) {
      return c.json({ error: 'Missing required field: sessionId' }, 400);
    }

    const session = await getSession(body.sessionId);
    if (!session) {
      return c.json({ error: 'Session not found or expired' }, 404);
    }

    if (session.step !== 'researched') {
      return c.json({ error: `Invalid step: expected 'researched', got '${session.step}'` }, 400);
    }

    if (!session.researchData) {
      return c.json({ error: 'Research data missing from session' }, 400);
    }

    console.log(`[Wizard] Session: ${session.id}`);
    console.log(`[Wizard] Topic: "${session.topic}"`);
    console.log(`[Wizard] Art style: ${session.artStyle}`);

    console.log('[Wizard] Running Storyteller agent...');
    const result = await runStoryteller(session.researchData, session.artStyle, session.topic);

    // Update session
    await updateSession(session.id, {
      step: 'generated',
      storyData: result.storyData,
    });

    console.log(`[Wizard] Story generated: "${result.storyData.title}"`);
    console.log(`[Wizard] Duration: ${Date.now() - startTime}ms`);
    console.log('========================================\n');

    return c.json({
      success: true,
      sessionId: session.id,
      step: 'generated',
      story: result.storyData,
    });
  } catch (error) {
    console.error('[Wizard] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Step 4: Review story
wizardRoutes.post('/review', async (c) => {
  const startTime = Date.now();
  console.log('\n========================================');
  console.log('[Wizard] POST /api/story-wizard/review');

  try {
    const body = await c.req.json<{ sessionId: string }>();

    if (!body.sessionId) {
      return c.json({ error: 'Missing required field: sessionId' }, 400);
    }

    const session = await getSession(body.sessionId);
    if (!session) {
      return c.json({ error: 'Session not found or expired' }, 404);
    }

    if (session.step !== 'generated') {
      return c.json({ error: `Invalid step: expected 'generated', got '${session.step}'` }, 400);
    }

    if (!session.storyData || !session.researchData) {
      return c.json({ error: 'Story or research data missing from session' }, 400);
    }

    console.log(`[Wizard] Session: ${session.id}`);
    console.log(`[Wizard] Story: "${session.storyData.title}"`);

    console.log('[Wizard] Running Critic agent...');
    const result = await runCritic(session.storyData, session.researchData);

    // Update session
    await updateSession(session.id, {
      step: 'completed',
      reviewData: result.review,
    });

    console.log(`[Wizard] Review complete (approved: ${result.review.approved})`);
    console.log(`[Wizard] Duration: ${Date.now() - startTime}ms`);
    console.log('========================================\n');

    return c.json({
      success: true,
      sessionId: session.id,
      step: 'completed',
      review: result.review,
    });
  } catch (error) {
    console.error('[Wizard] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Get complete story from session
wizardRoutes.get('/complete/:sessionId', async (c) => {
  console.log('\n========================================');
  console.log('[Wizard] GET /api/story-wizard/complete/:sessionId');

  try {
    const sessionId = c.req.param('sessionId');

    const session = await getSession(sessionId);
    if (!session) {
      return c.json({ error: 'Session not found or expired' }, 404);
    }

    if (session.step !== 'completed') {
      return c.json({ error: `Story not complete. Current step: ${session.step}` }, 400);
    }

    console.log(`[Wizard] Session: ${session.id}`);
    console.log(`[Wizard] Story: "${session.storyData?.title}"`);
    console.log('========================================\n');

    return c.json({
      success: true,
      story: {
        title: session.storyData!.title,
        topic: session.storyData!.topic,
        general_image_prompt: session.storyData!.general_image_prompt,
        pages: session.storyData!.pages,
        target_age: '5-8',
        art_style: session.artStyle,
        generation: {
          source: 'ai',
          grounded_facts: session.researchData!.facts,
          source_urls: session.researchData!.sourceUrls,
          timestamp: new Date().toISOString(),
        },
        critic_review: session.reviewData,
      },
    });
  } catch (error) {
    console.error('[Wizard] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Get session status
wizardRoutes.get('/status/:sessionId', async (c) => {
  try {
    const sessionId = c.req.param('sessionId');

    const session = await getSession(sessionId);
    if (!session) {
      return c.json({ error: 'Session not found or expired' }, 404);
    }

    return c.json({
      success: true,
      sessionId: session.id,
      topic: session.topic,
      artStyle: session.artStyle,
      step: session.step,
      hasResearch: !!session.researchData,
      hasStory: !!session.storyData,
      hasReview: !!session.reviewData,
    });
  } catch (error) {
    console.error('[Wizard] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Cancel/delete session
wizardRoutes.delete('/:sessionId', async (c) => {
  console.log('\n========================================');
  console.log('[Wizard] DELETE /api/story-wizard/:sessionId');

  try {
    const sessionId = c.req.param('sessionId');

    await deleteSession(sessionId);

    console.log(`[Wizard] Session deleted: ${sessionId}`);
    console.log('========================================\n');

    return c.json({
      success: true,
      message: 'Session deleted',
    });
  } catch (error) {
    console.error('[Wizard] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});
