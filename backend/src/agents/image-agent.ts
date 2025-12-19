import { enhanceImagePrompt, enhanceImagePromptWithHint } from './prompt-enhancer.js';
import { generateImage } from '../services/image-generator.js';
import { uploadImage } from '../services/image-uploader.js';
import type { TargetAge } from '../types/story.js';

export interface ImageAgentResult {
  originalPrompt: string;
  enhancedPrompt: string;
  negativePrompt: string;
  cloudinaryUrl: string;
  publicId: string;
  durationMs: number;
  tokens: {
    input: number;
    output: number;
  };
}

export interface HintImageAgentResult {
  hint: string;
  visualMetaphor: string;
  enhancedPrompt: string;
  negativePrompt: string;
  cloudinaryUrl: string;
  publicId: string;
  durationMs: number;
  tokens: {
    input: number;
    output: number;
  };
}

export async function runImageAgent(
  imagePrompt: string,
  artStyle: string,
  topic: string
): Promise<ImageAgentResult> {
  const startTime = Date.now();
  console.log('\n[ImageAgent] Starting image generation pipeline...');
  console.log(`[ImageAgent] Original prompt: "${imagePrompt.substring(0, 60)}..."`);
  console.log(`[ImageAgent] Art style: ${artStyle}`);

  // Step 1: Enhance the image prompt
  console.log('[ImageAgent] Step 1: Enhancing prompt...');
  const enhanceResult = await enhanceImagePrompt(imagePrompt, artStyle, topic);
  console.log(`[ImageAgent] Enhanced prompt: "${enhanceResult.enhancedPrompt.substring(0, 60)}..."`);

  // Step 2: Generate image with Stability AI
  console.log('[ImageAgent] Step 2: Generating image...');
  const imageResult = await generateImage(
    enhanceResult.enhancedPrompt,
    enhanceResult.negativePrompt
  );
  console.log(`[ImageAgent] Image generated in ${imageResult.durationMs}ms`);

  // Step 3: Upload to Cloudinary
  console.log('[ImageAgent] Step 3: Uploading to Cloudinary...');
  const uploadResult = await uploadImage(imageResult.base64Image);
  console.log(`[ImageAgent] Uploaded: ${uploadResult.imageUrl}`);

  const totalDuration = Date.now() - startTime;
  console.log(`[ImageAgent] Complete! Total duration: ${totalDuration}ms\n`);

  return {
    originalPrompt: imagePrompt,
    enhancedPrompt: enhanceResult.enhancedPrompt,
    negativePrompt: enhanceResult.negativePrompt,
    cloudinaryUrl: uploadResult.imageUrl,
    publicId: uploadResult.publicId,
    durationMs: totalDuration,
    tokens: {
      input: enhanceResult.inputTokens,
      output: enhanceResult.outputTokens,
    },
  };
}

export async function runImageAgentWithHint(
  hint: string,
  topic: string,
  artStyle: string,
  targetAge: TargetAge = '8-12'
): Promise<HintImageAgentResult> {
  const startTime = Date.now();
  console.log('\n[ImageAgent] Starting hint-driven image generation pipeline...');
  console.log(`[ImageAgent] Hint: "${hint}"`);
  console.log(`[ImageAgent] Topic: "${topic}"`);
  console.log(`[ImageAgent] Art style: ${artStyle}`);
  console.log(`[ImageAgent] Target age: ${targetAge}`);

  // Step 1: Generate visual metaphor from hint
  console.log('[ImageAgent] Step 1: Generating visual metaphor from hint...');
  const enhanceResult = await enhanceImagePromptWithHint(hint, topic, artStyle, targetAge);
  console.log(`[ImageAgent] Visual metaphor: "${enhanceResult.visualMetaphor.substring(0, 60)}..."`);
  console.log(`[ImageAgent] Enhanced prompt: "${enhanceResult.enhancedPrompt.substring(0, 60)}..."`);

  // Step 2: Generate image with Stability AI
  console.log('[ImageAgent] Step 2: Generating image...');
  const imageResult = await generateImage(
    enhanceResult.enhancedPrompt,
    enhanceResult.negativePrompt
  );
  console.log(`[ImageAgent] Image generated in ${imageResult.durationMs}ms`);

  // Step 3: Upload to Cloudinary
  console.log('[ImageAgent] Step 3: Uploading to Cloudinary...');
  const uploadResult = await uploadImage(imageResult.base64Image);
  console.log(`[ImageAgent] Uploaded: ${uploadResult.imageUrl}`);

  const totalDuration = Date.now() - startTime;
  console.log(`[ImageAgent] Complete! Total duration: ${totalDuration}ms\n`);

  return {
    hint,
    visualMetaphor: enhanceResult.visualMetaphor,
    enhancedPrompt: enhanceResult.enhancedPrompt,
    negativePrompt: enhanceResult.negativePrompt,
    cloudinaryUrl: uploadResult.imageUrl,
    publicId: uploadResult.publicId,
    durationMs: totalDuration,
    tokens: {
      input: enhanceResult.inputTokens,
      output: enhanceResult.outputTokens,
    },
  };
}
