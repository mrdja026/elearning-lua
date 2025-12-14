import { Hono } from 'hono';
import { buildPrompt } from '../services/prompt-builder.js';
import { generateImage } from '../services/image-generator.js';
import { uploadImage } from '../services/image-uploader.js';

export const generateImageRoute = new Hono();

const DEV_MOCK_IMAGE_URL = 'https://res.cloudinary.com/dvzbmvrxs/image/upload/v1765646051/logictales/sormpv8m1skh5a18o6uf.png';

interface GenerateImageRequest {
  description: string;
  question: string;
}

generateImageRoute.post('/generate-image', async (c) => {
  const startTime = Date.now();
  console.log('\n========================================');
  console.log('[API] POST /api/generate-image');
  console.log(`[API] Timestamp: ${new Date().toISOString()}`);

  try {
    const body = await c.req.json<GenerateImageRequest>();

    if (!body.description || !body.question) {
      console.log('[API] Error: Missing required fields');
      return c.json(
        { error: 'Missing required fields: description and question' },
        400
      );
    }

    console.log(`[API] Description: ${body.description}`);
    console.log(`[API] Question: ${body.question}`);

    // DEV_MODE: Return mock image immediately, skip all API calls
    if (process.env.DEV_MODE?.trim().toLowerCase() === 'true') {
      console.log('[API] DEV_MODE: Returning mock image URL');
      console.log('========================================\n');
      return c.json({
        success: true,
        imageUrl: DEV_MOCK_IMAGE_URL,
        metadata: {
          totalDurationMs: Date.now() - startTime,
          promptTokens: { input: 0, output: 0 },
          generatedPrompt: '[DEV_MODE] Mock prompt',
        },
      });
    }

    // Step 1: Build optimized prompt with Claude
    console.log('\n[API] Step 1: Building prompt...');
    const promptResult = await buildPrompt(body.description, body.question);
    console.log(`[API] Generated prompt: ${promptResult.prompt.substring(0, 100)}...`);

    // Step 2: Generate image with Stability AI
    console.log('\n[API] Step 2: Generating image...');
    const imageResult = await generateImage(
      promptResult.prompt,
      promptResult.negative_prompt
    );

    // Step 3: Upload to Cloudinary
    console.log('\n[API] Step 3: Uploading image...');
    const uploadResult = await uploadImage(imageResult.base64Image);

    const totalDuration = Date.now() - startTime;

    // Log summary
    console.log('\n[API] ===== SUMMARY =====');
    console.log(`[API] Total duration: ${totalDuration}ms`);
    console.log(`[API] Claude tokens - Input: ${promptResult.inputTokens}, Output: ${promptResult.outputTokens}`);
    console.log(`[API] Image generation: ${imageResult.durationMs}ms`);
    console.log(`[API] Image URL: ${uploadResult.imageUrl}`);
    console.log('========================================\n');

    return c.json({
      success: true,
      imageUrl: uploadResult.imageUrl,
      metadata: {
        totalDurationMs: totalDuration,
        promptTokens: {
          input: promptResult.inputTokens,
          output: promptResult.outputTokens,
        },
        generatedPrompt: promptResult.prompt,
      },
    });
  } catch (error) {
    const totalDuration = Date.now() - startTime;
    console.error('[API] Error:', error);
    console.log(`[API] Failed after ${totalDuration}ms`);
    console.log('========================================\n');

    return c.json(
      {
        success: false,
        error: 'Service not available, check usage and keys',
      },
      500
    );
  }
});
