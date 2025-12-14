const STABILITY_API_URL = 'https://api.stability.ai/v2beta/stable-image/generate/core';

export interface ImageGeneratorResult {
  base64Image: string;
  durationMs: number;
}

export async function generateImage(
  prompt: string,
  negativePrompt: string
): Promise<ImageGeneratorResult> {
  const startTime = Date.now();

  // DEV_MODE: Skip Stability AI call, return empty base64 (uploader will return mock URL)
  if (process.env.DEV_MODE === 'true') {
    console.log('[ImageGenerator] DEV_MODE: Skipping Stability AI call');
    return {
      base64Image: '',
      durationMs: 0,
    };
  }

  console.log('[ImageGenerator] Calling Stability AI Core...');

  const formData = new FormData();
  formData.append('prompt', prompt);
  formData.append('negative_prompt', negativePrompt);
  formData.append('output_format', 'png');
  formData.append('aspect_ratio', '3:2'); // Landscape format

  const response = await fetch(STABILITY_API_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.STABILITY_API_KEY}`,
      'Accept': 'image/*',
    },
    body: formData,
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('[ImageGenerator] Error:', response.status, errorText);
    throw new Error(`Stability AI error: ${response.status} - ${errorText}`);
  }

  const arrayBuffer = await response.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);
  const base64Image = buffer.toString('base64');

  const durationMs = Date.now() - startTime;

  console.log(`[ImageGenerator] Completed in ${durationMs}ms`);
  console.log(`[ImageGenerator] Image size: ${buffer.length} bytes`);

  return {
    base64Image,
    durationMs,
  };
}
