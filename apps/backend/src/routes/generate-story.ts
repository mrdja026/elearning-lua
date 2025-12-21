import { Hono } from 'hono';
import { runPipeline } from '../agents/index.js';
import type { ArtStyle, GeneratedStory } from '../types/story.js';

export const generateStoryRoute = new Hono();

// One-shot story generation endpoint
generateStoryRoute.post('/generate-story', async (c) => {
  const startTime = Date.now();
  console.log('\n============================================');
  console.log('[API] POST /api/generate-story');
  console.log('============================================');

  try {
    const body = await c.req.json<{
      topic: string;
      artStyle?: ArtStyle;
    }>();

    if (!body.topic) {
      return c.json({ error: 'Missing required field: topic' }, 400);
    }

    const artStyle = body.artStyle || 'fantasy';

    console.log(`[API] Topic: "${body.topic}"`);
    console.log(`[API] Art style: ${artStyle}`);

    // Run the full pipeline
    const result = await runPipeline(body.topic, artStyle);

    const totalDuration = Date.now() - startTime;

    // Build the complete story response
    // Note: cover_image_path is empty until images are generated separately
    const generatedStory: GeneratedStory = {
      title: result.story.title,
      topic: result.story.topic,
      general_image_prompt: result.story.general_image_prompt,
      cover_image_path: '', // Generated separately via image pipeline
      pages: result.story.pages,
      target_age: '5-8',
      art_style: artStyle,
      generation: {
        source: 'ai',
        grounded_facts: result.research.facts,
        source_urls: result.research.sourceUrls,
        timestamp: new Date().toISOString(),
      },
      critic_review: result.review,
    };

    console.log('\n============================================');
    console.log(`[API] Story generated: "${generatedStory.title}"`);
    console.log(`[API] Total duration: ${totalDuration}ms`);
    console.log(`[API] Cached research: ${result.metadata.cached}`);
    console.log('============================================\n');

    return c.json({
      success: true,
      story: generatedStory,
      metadata: {
        cached: result.metadata.cached,
        totalDurationMs: totalDuration,
        tokens: result.metadata.tokens,
      },
    });
  } catch (error) {
    console.error('[API] Error:', error);
    return c.json(
      {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      },
      500
    );
  }
});
