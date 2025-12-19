import { GoogleGenAI } from '@google/genai';
import type { ResearchData } from '../types/story.js';

const genAI = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY || '' });

const SYSTEM_PROMPT = `You are a research assistant for children aged 5-8.

TASK: Research the given topic and find accurate, beginner-friendly facts.

RULES:
1. Find 3-5 simple, accurate facts about the topic
2. Use SHORT sentences (under 15 words each)
3. NO jargon - explain like you're talking to a 6-year-old
4. Focus on "why" and "how" explanations
5. Make facts interesting and memorable

OUTPUT FORMAT (JSON only, no markdown):
{
  "facts": ["Fact 1 in simple words", "Fact 2 in simple words", ...],
  "sourceUrls": ["https://source1.com", "https://source2.com", ...]
}

EXAMPLE for "Why is the sky blue?":
{
  "facts": [
    "Sunlight has all the colors of the rainbow mixed together.",
    "When sunlight hits tiny bits of air, blue light bounces around the most.",
    "Our eyes see all that bouncing blue light in the sky.",
    "At sunset, sunlight travels farther and we see orange and red instead."
  ],
  "sourceUrls": ["https://spaceplace.nasa.gov/blue-sky/"]
}`;

export interface ResearcherResult extends ResearchData {
  inputTokens: number;
  outputTokens: number;
  durationMs: number;
}

export async function runResearcher(topic: string): Promise<ResearcherResult> {
  const startTime = Date.now();

  // DEV_MODE: Return mock response to save API credits
  if (process.env.DEV_MODE?.trim().toLowerCase() === 'true') {
    console.log('[Researcher] DEV_MODE: Returning mock research');
    return {
      facts: [
        `${topic} is a fascinating subject for kids to learn about.`,
        'Scientists study this topic to help us understand the world.',
        'There are many fun experiments you can do to learn more.',
        'Kids can explore this topic through books and videos.',
      ],
      sourceUrls: [
        'https://www.nationalgeographic.com/kids/',
        'https://kids.britannica.com/',
      ],
      inputTokens: 0,
      outputTokens: 0,
      durationMs: Date.now() - startTime,
    };
  }

  const userMessage = `TOPIC TO RESEARCH: ${topic}

Find beginner-friendly facts for children aged 5-8.`;

  console.log('[Researcher] Calling Gemini API with Google Search grounding...');
  console.log(`[Researcher] Topic: "${topic.substring(0, 50)}..."`);

  let result;
  try {
    // Use Gemini with Google Search grounding
    result = await genAI.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: userMessage,
      config: {
        systemInstruction: SYSTEM_PROMPT,
        tools: [{ googleSearch: {} }],
      },
    });
  } catch (err) {
    console.error('[Researcher] Gemini API call failed!');
    console.error('[Researcher] Error:', err instanceof Error ? err.message : err);
    throw new Error(`Gemini API error: ${err instanceof Error ? err.message : String(err)}`);
  }

  const duration = Date.now() - startTime;
  const inputTokens = result.usageMetadata?.promptTokenCount || 0;
  const outputTokens = result.usageMetadata?.candidatesTokenCount || 0;

  console.log(`[Researcher] API call completed in ${duration}ms`);
  console.log(`[Researcher] Tokens - Input: ${inputTokens}, Output: ${outputTokens}`);

  const text = result.text || '';
  console.log(`[Researcher] Raw response:\n${text.substring(0, 500)}...`);

  // Extract grounding metadata for source URLs
  const groundingMeta = result.candidates?.[0]?.groundingMetadata;
  const groundingChunks = groundingMeta?.groundingChunks || [];
  const sourceUrls = groundingChunks
    .map((chunk: { web?: { uri?: string } }) => chunk.web?.uri)
    .filter((uri: string | undefined): uri is string => !!uri);

  console.log(`[Researcher] Found ${sourceUrls.length} grounding sources`);

  // Extract JSON from response (handle markdown code blocks)
  let jsonText = text;
  const jsonMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (jsonMatch) {
    jsonText = jsonMatch[1].trim();
    console.log('[Researcher] Extracted JSON from code block');
  }

  let parsed;
  try {
    parsed = JSON.parse(jsonText);
  } catch (err) {
    console.error('[Researcher] Failed to parse JSON response!');
    console.error('[Researcher] JSON text was:', jsonText.substring(0, 200));
    throw new Error(`Failed to parse Gemini response as JSON: ${err instanceof Error ? err.message : String(err)}`);
  }

  if (!parsed.facts || !Array.isArray(parsed.facts)) {
    console.error('[Researcher] Missing facts array in response!');
    throw new Error('Gemini response missing required field: facts');
  }

  // Use grounding sources if available, fallback to parsed ones
  const finalSourceUrls = sourceUrls.length > 0 ? sourceUrls : (parsed.sourceUrls || []);

  console.log(`[Researcher] Success! Found ${parsed.facts.length} facts`);

  return {
    facts: parsed.facts,
    sourceUrls: finalSourceUrls,
    inputTokens,
    outputTokens,
    durationMs: duration,
  };
}
