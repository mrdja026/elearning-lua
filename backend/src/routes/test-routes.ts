import { Hono } from 'hono';
import { buildPrompt } from '../services/prompt-builder.js';
import { generateImage } from '../services/image-generator.js';
import { uploadImage } from '../services/image-uploader.js';
import { runResearcher } from '../agents/researcher.js';
import { runStoryteller } from '../agents/storyteller.js';
import { runCritic } from '../agents/critic.js';
import { runPipeline } from '../agents/index.js';
import type { ResearchData, StoryData, ArtStyle } from '../types/story.js';

export const testRoutes = new Hono();

const DEV_MOCK_IMAGE_URL = 'https://res.cloudinary.com/dvzbmvrxs/image/upload/v1765646051/logictales/sormpv8m1skh5a18o6uf.png';

// Test prompt building only (Gemini)
testRoutes.post('/test-prompt', async (c) => {
  const startTime = Date.now();
  console.log('\n========================================');
  console.log('[TEST] POST /api/test-prompt');

  try {
    const body = await c.req.json<{ description: string; question: string }>();

    if (!body.description || !body.question) {
      return c.json({ error: 'Missing required fields: description and question' }, 400);
    }

    console.log(`[TEST] Description: ${body.description}`);
    console.log(`[TEST] Question: ${body.question}`);

    // DEV_MODE: Return mock prompt
    if (process.env.DEV_MODE === 'true') {
      console.log('[TEST] DEV_MODE: Returning mock prompt');
      console.log('========================================\n');
      return c.json({
        success: true,
        prompt: `[DEV_MODE] A whimsical children's book illustration of ${body.description}`,
        negative_prompt: 'scary, dark, violent, realistic, photographic, nsfw',
        tokens: { input: 0, output: 0 },
      });
    }

    const result = await buildPrompt(body.description, body.question);

    console.log(`[TEST] Completed in ${Date.now() - startTime}ms`);
    console.log('========================================\n');

    return c.json({
      success: true,
      prompt: result.prompt,
      negative_prompt: result.negative_prompt,
      tokens: {
        input: result.inputTokens,
        output: result.outputTokens,
      },
    });
  } catch (error) {
    console.error('[TEST] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Test image generation only (Stability AI)
testRoutes.post('/test-image', async (c) => {
  const startTime = Date.now();
  console.log('\n========================================');
  console.log('[TEST] POST /api/test-image');

  try {
    const body = await c.req.json<{ prompt: string; negative_prompt?: string }>();

    if (!body.prompt) {
      return c.json({ error: 'Missing required field: prompt' }, 400);
    }

    console.log(`[TEST] Prompt: ${body.prompt.substring(0, 100)}...`);

    // DEV_MODE: Return mock image URL
    if (process.env.DEV_MODE === 'true') {
      console.log('[TEST] DEV_MODE: Returning mock image URL');
      console.log('========================================\n');
      return c.json({
        success: true,
        imageUrl: DEV_MOCK_IMAGE_URL,
        durationMs: 0,
      });
    }

    const negativePrompt = body.negative_prompt || 'scary, dark, violent, realistic, photographic, nsfw, horror, blood, weapons';

    const imageResult = await generateImage(body.prompt, negativePrompt);

    // Upload to cloudinary so we can see the result
    const uploadResult = await uploadImage(imageResult.base64Image);

    console.log(`[TEST] Completed in ${Date.now() - startTime}ms`);
    console.log('========================================\n');

    return c.json({
      success: true,
      imageUrl: uploadResult.imageUrl,
      durationMs: imageResult.durationMs,
    });
  } catch (error) {
    console.error('[TEST] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Test Cloudinary upload only (with a small test image)
testRoutes.get('/test-upload', async (c) => {
  console.log('\n========================================');
  console.log('[TEST] GET /api/test-upload');

  try {
    // DEV_MODE: Return mock URL
    if (process.env.DEV_MODE === 'true') {
      console.log('[TEST] DEV_MODE: Returning mock image URL');
      console.log('========================================\n');
      return c.json({
        success: true,
        imageUrl: DEV_MOCK_IMAGE_URL,
        publicId: 'logictales/dev-mock',
      });
    }

    // Create a tiny 1x1 red PNG for testing
    const tinyPng = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';

    const result = await uploadImage(tinyPng);

    console.log('[TEST] Upload successful');
    console.log('========================================\n');

    return c.json({
      success: true,
      imageUrl: result.imageUrl,
      publicId: result.publicId,
    });
  } catch (error) {
    console.error('[TEST] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// ============================================
// ADK Agent Test Routes
// ============================================

// Test Researcher agent (Google Search grounding)
testRoutes.post('/test-researcher', async (c) => {
  const startTime = Date.now();
  console.log('\n========================================');
  console.log('[TEST] POST /api/test-researcher');

  try {
    const body = await c.req.json<{ topic: string }>();

    if (!body.topic) {
      return c.json({ error: 'Missing required field: topic' }, 400);
    }

    console.log(`[TEST] Topic: ${body.topic}`);

    const result = await runResearcher(body.topic);

    console.log(`[TEST] Completed in ${Date.now() - startTime}ms`);
    console.log('========================================\n');

    return c.json({
      success: true,
      facts: result.facts,
      sourceUrls: result.sourceUrls,
      tokens: {
        input: result.inputTokens,
        output: result.outputTokens,
      },
      durationMs: result.durationMs,
    });
  } catch (error) {
    console.error('[TEST] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Test Storyteller agent
testRoutes.post('/test-storyteller', async (c) => {
  const startTime = Date.now();
  console.log('\n========================================');
  console.log('[TEST] POST /api/test-storyteller');

  try {
    const body = await c.req.json<{
      researchData: ResearchData;
      artStyle?: ArtStyle;
      topic?: string;
    }>();

    if (!body.researchData || !body.researchData.facts) {
      return c.json({ error: 'Missing required field: researchData.facts' }, 400);
    }

    const artStyle = body.artStyle || 'fantasy';
    const topic = body.topic || 'Amazing Science';

    console.log(`[TEST] Topic: ${topic}`);
    console.log(`[TEST] Art style: ${artStyle}`);
    console.log(`[TEST] Facts: ${body.researchData.facts.length}`);

    const result = await runStoryteller(body.researchData, artStyle, topic);

    console.log(`[TEST] Completed in ${Date.now() - startTime}ms`);
    console.log('========================================\n');

    return c.json({
      success: true,
      storyData: result.storyData,
      tokens: {
        input: result.inputTokens,
        output: result.outputTokens,
      },
      durationMs: result.durationMs,
    });
  } catch (error) {
    console.error('[TEST] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Test Critic agent
testRoutes.post('/test-critic', async (c) => {
  const startTime = Date.now();
  console.log('\n========================================');
  console.log('[TEST] POST /api/test-critic');

  try {
    const body = await c.req.json<{
      storyData: StoryData;
      researchData?: ResearchData;
    }>();

    if (!body.storyData || !body.storyData.title) {
      return c.json({ error: 'Missing required field: storyData' }, 400);
    }

    // Default research data if not provided
    const researchData = body.researchData || {
      facts: ['This is a test fact.'],
      sourceUrls: [],
    };

    console.log(`[TEST] Story: ${body.storyData.title}`);
    console.log(`[TEST] Pages: ${body.storyData.pages?.length || 0}`);

    const result = await runCritic(body.storyData, researchData);

    console.log(`[TEST] Completed in ${Date.now() - startTime}ms`);
    console.log('========================================\n');

    return c.json({
      success: true,
      review: result.review,
      tokens: {
        input: result.inputTokens,
        output: result.outputTokens,
      },
      durationMs: result.durationMs,
    });
  } catch (error) {
    console.error('[TEST] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Test full pipeline (Researcher → Storyteller → Critic)
testRoutes.post('/test-pipeline', async (c) => {
  const startTime = Date.now();
  console.log('\n========================================');
  console.log('[TEST] POST /api/test-pipeline');

  try {
    const body = await c.req.json<{
      topic: string;
      artStyle?: ArtStyle;
    }>();

    if (!body.topic) {
      return c.json({ error: 'Missing required field: topic' }, 400);
    }

    const artStyle = body.artStyle || 'fantasy';

    console.log(`[TEST] Topic: ${body.topic}`);
    console.log(`[TEST] Art style: ${artStyle}`);

    const result = await runPipeline(body.topic, artStyle);

    console.log(`[TEST] Completed in ${Date.now() - startTime}ms`);
    console.log('========================================\n');

    return c.json({
      success: true,
      story: {
        title: result.story.title,
        topic: result.story.topic,
        pages: result.story.pages,
      },
      research: {
        facts: result.research.facts,
        sourceUrls: result.research.sourceUrls,
      },
      review: result.review,
      metadata: result.metadata,
    });
  } catch (error) {
    console.error('[TEST] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});
