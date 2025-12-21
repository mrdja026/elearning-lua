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

export interface HintEnhancedPromptResult {
  visualMetaphor: string;
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

function getHintMetaphorSystem(topic: string, artStyle: string, targetAge: TargetAge): string {
  return `You are a visual metaphor expert for children's educational content.
Given a learning hint/concept, create a concrete visual metaphor.

EXAMPLES BY CATEGORY:

## Programming Concepts
- "if statement" → "a path splitting into two different roads at a crossroads with signs"
- "for loop" → "a race car driving around a circular track multiple times"
- "while loop" → "a hamster running on a wheel until it gets tired"
- "variables" → "labeled jars or containers holding different colored items"
- "functions" → "a magic box: put something in, get something different out"
- "arrays" → "a train with numbered cars, each carrying one item"
- "debugging" → "a detective with magnifying glass searching for bugs"
- "recursion" → "Russian nesting dolls, each containing a smaller version"
- "API" → "a restaurant waiter taking orders between kitchen and customers"
- "database" → "a giant filing cabinet with many organized drawers"

## File Management & Organization
- "folder structure" → "a tree with branches, each branch is a folder"
- "file naming" → "labeled library books on organized shelves"
- "file search" → "a librarian helping find the right book"
- "saving files" → "putting a letter in a labeled envelope in a drawer"
- "file versions" → "stacked photo albums showing the same scene at different times"
- "backup" → "making a copy of your favorite toy in case you lose one"
- "cloud storage" → "magical floating boxes in the sky you can reach from anywhere"
- "file extensions" → "different shaped boxes: square for documents, round for music"

## Cybersecurity & Safety
- "password" → "a secret key that only opens your treasure chest"
- "strong password" → "a complicated lock with many unique symbols"
- "phishing" → "a wolf dressed as grandma trying to trick Little Red Riding Hood"
- "spam email" → "junk mail being thrown in a trash can by a guard"
- "two-factor authentication" → "two keys needed to open a special vault"
- "encryption" → "a secret code only you and your friend can read"
- "firewall" → "a castle wall with guards checking everyone who enters"
- "malware/virus" → "germs trying to make your computer sick"
- "VPN" → "an invisible tunnel only you can travel through"

## Internet & Networking
- "WiFi" → "invisible radio waves carrying messages through the air"
- "bandwidth" → "a highway: more lanes means more cars can travel"
- "download/upload" → "receiving a package vs sending a package"
- "URL/website address" → "a house address that tells you where to go"
- "browser" → "a magic window that shows you places around the world"
- "cookies" → "breadcrumbs websites leave to remember you visited"
- "server" → "a giant computer library that serves books to visitors"
- "cache" → "a small pocket where you keep frequently used items"

## Financial Literacy
- "budget" → "a piggy bank divided into sections for different needs"
- "interest" → "a tree that grows more fruit the longer you wait"
- "compound interest" → "snowball rolling downhill, getting bigger over time"
- "stocks" → "owning a small piece of a pizza (company)"
- "savings" → "squirrels collecting nuts for winter"
- "debt" → "borrowing toys from a friend and owing them back with extra"
- "investment" → "planting seeds today to harvest vegetables tomorrow"
- "inflation" → "same money buying fewer toys each year"

## General Computer Skills
- "copy/paste" → "making a photocopy of a drawing"
- "undo/redo" → "a time machine going back and forward"
- "keyboard shortcuts" → "secret quick paths through a maze"
- "multitasking" → "a juggler keeping multiple balls in the air"
- "software update" → "giving your computer new superpowers"
- "restart" → "waking up refreshed after a good night's sleep"
- "RAM vs storage" → "desk space (RAM) vs filing cabinet (storage)"
- "CPU" → "the brain of the computer thinking and making decisions"

The metaphor must be:
1. Visually concrete (can be drawn/illustrated)
2. Age-appropriate for ${targetAge}
3. Related to the topic: ${topic}
4. Suitable for ${artStyle} art style
5. Culturally neutral and universally understood

OUTPUT FORMAT (JSON only, no markdown):
{
  "visual_metaphor": "description of the visual metaphor scene",
  "enhanced_prompt": "full enhanced prompt incorporating the metaphor",
  "negative_prompt": "standard negative prompt for quality"
}`;
}

export async function enhanceImagePromptWithHint(
  hint: string,
  topic: string,
  artStyle: string,
  targetAge: TargetAge = '8-12'
): Promise<HintEnhancedPromptResult> {
  const startTime = Date.now();

  // DEV_MODE: Return mock response
  if (process.env.DEV_MODE?.trim().toLowerCase() === 'true') {
    console.log('[PromptEnhancer] DEV_MODE: Returning mock hint-enhanced prompt');
    return {
      visualMetaphor: `A visual representation of "${hint}" - an engaging scene that makes the concept easy to understand`,
      enhancedPrompt: `${artStyle} style, visual metaphor for ${hint}, ${topic} theme, vibrant colors, child-friendly, highly detailed, masterpiece quality, educational illustration for ${targetAge} audience`,
      negativePrompt: 'blurry, low quality, distorted, watermark, text, logo, signature, cropped, out of frame, worst quality, low resolution, ugly, duplicate, deformed, extra fingers, extra limbs, mutated hands, poorly drawn, bad anatomy, horror, violence, blood, gore, scary, dark, creepy, nsfw, nude',
      inputTokens: 0,
      outputTokens: 0,
      durationMs: Date.now() - startTime,
    };
  }

  const userMessage = `HINT/CONCEPT: ${hint}
STORY TOPIC: ${topic}
ART STYLE: ${artStyle}
TARGET AGE: ${targetAge}

Create a visual metaphor for this educational concept.`;

  console.log('[PromptEnhancer] Generating visual metaphor for hint...');
  console.log(`[PromptEnhancer] Hint: "${hint}"`);
  console.log(`[PromptEnhancer] Topic: "${topic}"`);
  console.log(`[PromptEnhancer] Art Style: ${artStyle}`);
  console.log(`[PromptEnhancer] Target Age: ${targetAge}`);

  const model = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash-lite',
    systemInstruction: getHintMetaphorSystem(topic, artStyle, targetAge),
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

  console.log(`[PromptEnhancer] Visual metaphor generated in ${duration}ms`);

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
    visualMetaphor: parsed.visual_metaphor,
    enhancedPrompt: parsed.enhanced_prompt,
    negativePrompt: parsed.negative_prompt,
    inputTokens,
    outputTokens,
    durationMs: duration,
  };
}
