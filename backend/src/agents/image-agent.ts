import { enhanceImagePrompt } from './prompt-enhancer.js';
import { generateImage } from '../services/image-generator.js';
import { uploadImage } from '../services/image-uploader.js';

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
