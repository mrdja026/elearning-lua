import { Hono } from 'hono';
import { buildPrompt } from '../services/prompt-builder.js';
import { generateImage } from '../services/image-generator.js';
import { uploadImage } from '../services/image-uploader.js';

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
