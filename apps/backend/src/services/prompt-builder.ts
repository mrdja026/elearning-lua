import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

const SYSTEM_PROMPT = `You are a creative prompt enhancer for Stability AI image generation.

TASK: Enhance the user's image description into a detailed, high-quality prompt.

ENHANCEMENT RULES:
1. PRESERVE the user's core concept - enhance it, don't replace it
2. Add vivid descriptive details: composition, lighting, colors, atmosphere
3. Apply fantasy art style: magical, ethereal, dramatic lighting, rich details
4. Structure: [Style keywords] + [Enhanced subject] + [Environment/Setting] + [Lighting/Mood] + [Quality tags]
5. Keep prompt under 150 words
6. Be creative but stay true to what the user described

STYLE TO APPLY:
Fantasy art style, magical atmosphere, ethereal lighting, rich colors, detailed illustration, dramatic composition, professional quality

QUALITY ENHANCERS (include relevant ones):
highly detailed, masterpiece, best quality, intricate details, sharp focus, professional, stunning

OUTPUT FORMAT (JSON only, no markdown):
{
  "prompt": "your enhanced prompt",
  "negative_prompt": "quality and safety blockers"
}

NEGATIVE PROMPT (always include ALL of these):
blurry, low quality, distorted, watermark, text, logo, signature, cropped, out of frame, worst quality, low resolution, ugly, duplicate, deformed, extra fingers, extra limbs, mutated hands, poorly drawn, bad anatomy, horror, violence, blood, gore, scary, dark, creepy, nsfw, nude`;

export interface PromptBuilderResult {
  prompt: string;
  negative_prompt: string;
  inputTokens: number;
  outputTokens: number;
}

export async function buildPrompt(
  description: string,
  question: string
): Promise<PromptBuilderResult> {
  const startTime = Date.now();

  // DEV_MODE: Return mock response to save API credits
  if (process.env.DEV_MODE?.trim().toLowerCase() === 'true') {
    console.log('[PromptBuilder] DEV_MODE: Returning mock prompt');
    return {
      prompt: `Fantasy art style, magical atmosphere, ethereal lighting. ${description}, rich colors, detailed illustration, dramatic composition, highly detailed, masterpiece quality`,
      negative_prompt: 'blurry, low quality, distorted, watermark, text, logo, signature, cropped, out of frame, worst quality, low resolution, ugly, duplicate, deformed, extra fingers, extra limbs, mutated hands, poorly drawn, bad anatomy, horror, violence, blood, gore, scary, dark, creepy, nsfw, nude',
      inputTokens: 0,
      outputTokens: 0,
    };
  }

  const userMessage = `IMAGE IDEA: ${description}

CONTEXT: ${question}

Enhance this into a detailed fantasy-style image generation prompt.`;

  console.log('[PromptBuilder] Calling Gemini API...');
  console.log(`[PromptBuilder] Input: "${description.substring(0, 50)}..." / "${question.substring(0, 50)}..."`);

  const model = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash-lite',
    systemInstruction: SYSTEM_PROMPT,
  });

  let result;
  try {
    result = await model.generateContent(userMessage);
  } catch (err) {
    console.error('[PromptBuilder] Gemini API call failed!');
    console.error('[PromptBuilder] Error:', err instanceof Error ? err.message : err);
    throw new Error(`Gemini API error: ${err instanceof Error ? err.message : String(err)}`);
  }

  const response = result.response;
  const duration = Date.now() - startTime;
  const inputTokens = response.usageMetadata?.promptTokenCount || 0;
  const outputTokens = response.usageMetadata?.candidatesTokenCount || 0;

  console.log(`[PromptBuilder] API call completed in ${duration}ms`);
  console.log(`[PromptBuilder] Tokens - Input: ${inputTokens}, Output: ${outputTokens}`);

  const text = response.text();
  console.log(`[PromptBuilder] Raw response:\n${text}`);

  // Extract JSON from response (handle markdown code blocks)
  let jsonText = text;
  const jsonMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (jsonMatch) {
    jsonText = jsonMatch[1].trim();
    console.log('[PromptBuilder] Extracted JSON from code block');
  }

  let parsed;
  try {
    parsed = JSON.parse(jsonText);
  } catch (err) {
    console.error('[PromptBuilder] Failed to parse JSON response!');
    console.error('[PromptBuilder] JSON text was:', jsonText);
    throw new Error(`Failed to parse Gemini response as JSON: ${err instanceof Error ? err.message : String(err)}`);
  }

  if (!parsed.prompt || !parsed.negative_prompt) {
    console.error('[PromptBuilder] Missing required fields in response!');
    console.error('[PromptBuilder] Parsed object:', JSON.stringify(parsed, null, 2));
    throw new Error('Gemini response missing required fields: prompt or negative_prompt');
  }

  console.log(`[PromptBuilder] Success! Prompt length: ${parsed.prompt.length} chars`);

  return {
    prompt: parsed.prompt,
    negative_prompt: parsed.negative_prompt,
    inputTokens,
    outputTokens,
  };
}
