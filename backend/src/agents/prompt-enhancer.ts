import { GoogleGenerativeAI } from '@google/generative-ai';
import type { TargetAge } from '../types/story.js';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

const AGE_TONE_GUIDE: Record<TargetAge, string> = {
  '5-8': `TONE: Simple, playful, wonder-filled. Use short sentences, friendly characters, and magical elements. Avoid complex concepts. Make learning feel like an adventure.`,
  '8-12': `TONE: Curious and exploratory. Use relatable characters, mild humor, and discovery-driven narratives. Can introduce basic scientific concepts. Balance fun with learning.`,
  '13-17': `TONE: Engaging and thought-provoking. Use compelling narratives, real-world connections, and deeper exploration of concepts. Can include challenges and problem-solving elements.`,
  '18+': `TONE: Sophisticated and analytical. Use nuanced explanations, real-world applications, and intellectual depth. Can include technical details, complex reasoning, and adult perspectives.`,
  'all': `TONE: Universal and accessible. Balance simplicity with depth. Use relatable analogies and engaging narratives that work across age groups.`,
};

function getStoryPromptSystem(targetAge: TargetAge): string {
  return `You are a creative prompt enhancer for educational stories.

TARGET AUDIENCE: ${targetAge} years old
${AGE_TONE_GUIDE[targetAge]}

TASK: Enhance the user's topic into a rich, engaging story prompt appropriate for the target age.

ENHANCEMENT RULES:
1. PRESERVE the core topic - enhance it, don't replace it
2. Add engaging elements appropriate for the age group
3. Match complexity and vocabulary to the target age
4. Keep it educational and engaging
5. Add sensory details that will help with storytelling

OUTPUT FORMAT (JSON only, no markdown):
{
  "enhanced_prompt": "your enhanced story prompt",
  "suggested_character": "a character name and type appropriate for the age group",
  "key_themes": ["theme1", "theme2", "theme3"]
}`;
}

const IMAGE_PROMPT_SYSTEM = `You are a creative prompt enhancer for Stability AI image generation.

TASK: Enhance the image prompt into a detailed, high-quality image generation prompt.

ENHANCEMENT RULES:
1. PRESERVE the core concept - enhance it, don't replace it
2. Add vivid descriptive details: composition, lighting, colors, atmosphere
3. Apply the specified art style consistently
4. Structure: [Style keywords] + [Enhanced subject] + [Environment/Setting] + [Lighting/Mood] + [Quality tags]
5. Keep prompt under 150 words
6. Make it child-friendly and appealing

QUALITY ENHANCERS (include relevant ones):
highly detailed, masterpiece, best quality, intricate details, sharp focus, professional, stunning, vibrant colors

OUTPUT FORMAT (JSON only, no markdown):
{
  "enhanced_prompt": "your enhanced image prompt",
  "negative_prompt": "blurry, low quality, distorted, watermark, text, logo, signature, cropped, out of frame, worst quality, low resolution, ugly, duplicate, deformed, extra fingers, extra limbs, mutated hands, poorly drawn, bad anatomy, horror, violence, blood, gore, scary, dark, creepy, nsfw, nude"
}`;

export interface StoryPromptEnhancerResult {
  enhancedPrompt: string;
  suggestedCharacter: string;
  keyThemes: string[];
  inputTokens: number;
  outputTokens: number;
  durationMs: number;
}

export interface ImagePromptEnhancerResult {
  enhancedPrompt: string;
  negativePrompt: string;
  inputTokens: number;
  outputTokens: number;
  durationMs: number;
}

export async function enhanceStoryPrompt(
  topic: string,
  targetAge: TargetAge = '5-8'
): Promise<StoryPromptEnhancerResult> {
  const startTime = Date.now();

  // DEV_MODE: Return mock response
  if (process.env.DEV_MODE?.trim().toLowerCase() === 'true') {
    console.log('[PromptEnhancer] DEV_MODE: Returning mock enhanced story prompt');
    const ageDescriptor = targetAge === '18+' ? 'sophisticated' : targetAge === '13-17' ? 'thought-provoking' : 'exciting';
    return {
      enhancedPrompt: `A ${ageDescriptor} exploration of ${topic} where an engaging guide helps discover fascinating facts through interactive learning moments tailored for ${targetAge} audience.`,
      suggestedCharacter: targetAge === '18+' ? `Dr. ${topic.split(' ')[0]} the Expert` : `Professor ${topic.split(' ')[0]} the Wise Owl`,
      keyThemes: ['discovery', 'learning', 'exploration'],
      inputTokens: 0,
      outputTokens: 0,
      durationMs: Date.now() - startTime,
    };
  }

  const userMessage = `TOPIC: ${topic}

Enhance this topic into an engaging story prompt for ${targetAge} audience.`;

  console.log('[PromptEnhancer] Enhancing story prompt...');
  console.log(`[PromptEnhancer] Topic: "${topic}"`);
  console.log(`[PromptEnhancer] Target Age: ${targetAge}`);

  const model = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash-lite',
    systemInstruction: getStoryPromptSystem(targetAge),
  });

  let result;
  try {
    result = await model.generateContent(userMessage);
  } catch (err) {
    console.error('[PromptEnhancer] Gemini API call failed!');
    throw new Error(`Gemini API error: ${err instanceof Error ? err.message : String(err)}`);
  }

  const response = result.response;
  const duration = Date.now() - startTime;
  const inputTokens = response.usageMetadata?.promptTokenCount || 0;
  const outputTokens = response.usageMetadata?.candidatesTokenCount || 0;

  console.log(`[PromptEnhancer] Story prompt enhanced in ${duration}ms`);

  const text = response.text();
  let jsonText = text;
  const jsonMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (jsonMatch) {
    jsonText = jsonMatch[1].trim();
  }

  let parsed;
  try {
    parsed = JSON.parse(jsonText);
  } catch (err) {
    throw new Error(`Failed to parse response: ${err instanceof Error ? err.message : String(err)}`);
  }

  return {
    enhancedPrompt: parsed.enhanced_prompt,
    suggestedCharacter: parsed.suggested_character,
    keyThemes: parsed.key_themes || [],
    inputTokens,
    outputTokens,
    durationMs: duration,
  };
}

export async function enhanceImagePrompt(
  imagePrompt: string,
  artStyle: string,
  topic: string
): Promise<ImagePromptEnhancerResult> {
  const startTime = Date.now();

  // DEV_MODE: Return mock response
  if (process.env.DEV_MODE?.trim().toLowerCase() === 'true') {
    console.log('[PromptEnhancer] DEV_MODE: Returning mock enhanced image prompt');
    return {
      enhancedPrompt: `${artStyle} style, ${imagePrompt}, vibrant colors, child-friendly, highly detailed, masterpiece quality, magical atmosphere, educational illustration`,
      negativePrompt: 'blurry, low quality, distorted, watermark, text, logo, signature, cropped, out of frame, worst quality, low resolution, ugly, duplicate, deformed, extra fingers, extra limbs, mutated hands, poorly drawn, bad anatomy, horror, violence, blood, gore, scary, dark, creepy, nsfw, nude',
      inputTokens: 0,
      outputTokens: 0,
      durationMs: Date.now() - startTime,
    };
  }

  const userMessage = `IMAGE PROMPT: ${imagePrompt}
ART STYLE: ${artStyle}
STORY TOPIC: ${topic}

Enhance this image prompt for child-friendly educational illustration.`;

  console.log('[PromptEnhancer] Enhancing image prompt...');
  console.log(`[PromptEnhancer] Original: "${imagePrompt.substring(0, 50)}..."`);

  const model = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash-lite',
    systemInstruction: IMAGE_PROMPT_SYSTEM,
  });

  let result;
  try {
    result = await model.generateContent(userMessage);
  } catch (err) {
    console.error('[PromptEnhancer] Gemini API call failed!');
    throw new Error(`Gemini API error: ${err instanceof Error ? err.message : String(err)}`);
  }

  const response = result.response;
  const duration = Date.now() - startTime;
  const inputTokens = response.usageMetadata?.promptTokenCount || 0;
  const outputTokens = response.usageMetadata?.candidatesTokenCount || 0;

  console.log(`[PromptEnhancer] Image prompt enhanced in ${duration}ms`);

  const text = response.text();
  let jsonText = text;
  const jsonMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (jsonMatch) {
    jsonText = jsonMatch[1].trim();
  }

  let parsed;
  try {
    parsed = JSON.parse(jsonText);
  } catch (err) {
    throw new Error(`Failed to parse response: ${err instanceof Error ? err.message : String(err)}`);
  }

  return {
    enhancedPrompt: parsed.enhanced_prompt,
    negativePrompt: parsed.negative_prompt,
    inputTokens,
    outputTokens,
    durationMs: duration,
  };
}
