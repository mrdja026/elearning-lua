import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

const SYSTEM_PROMPT = `You are an expert at creating image generation prompts for children's educational content.

Your task is to take a description and a question from a children's story, and create an optimized prompt for Stable Diffusion that:
1. Is appropriate for children (no scary, violent, or inappropriate content)
2. Uses a consistent art style: vibrant children's book illustration, soft colors, friendly characters
3. Incorporates visual elements that relate to the question (e.g., if asking about "5 apples", show apples)
4. Is descriptive but concise (under 200 words)

You must respond with a JSON object containing:
- "prompt": The optimized Stable Diffusion prompt
- "negative_prompt": Things to avoid (always include: scary, dark, violent, realistic, photographic, nsfw, horror, blood, weapons)

Example output:
{
  "prompt": "A cheerful cartoon forest scene with a friendly squirrel counting colorful acorns, children's book illustration style, soft watercolors, bright and inviting atmosphere, educational theme",
  "negative_prompt": "scary, dark, violent, realistic, photographic, nsfw, horror, blood, weapons, creepy, nightmare"
}`;

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
  if (process.env.DEV_MODE === 'true') {
    console.log('[PromptBuilder] DEV_MODE: Returning mock prompt');
    return {
      prompt: `A whimsical children's book illustration of ${description}, soft pastel colors, friendly atmosphere, educational theme`,
      negative_prompt: 'scary, dark, violent, realistic, photographic, nsfw, horror, blood, weapons',
      inputTokens: 0,
      outputTokens: 0,
    };
  }

  const userMessage = `Description: ${description}
Question from the story: ${question}

Create an optimized Stable Diffusion prompt for this children's story scene.`;

  console.log('[PromptBuilder] Calling Gemini API...');

  const model = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash-lite',
    systemInstruction: SYSTEM_PROMPT,
  });

  const result = await model.generateContent(userMessage);
  const response = result.response;

  const duration = Date.now() - startTime;
  const inputTokens = response.usageMetadata?.promptTokenCount || 0;
  const outputTokens = response.usageMetadata?.candidatesTokenCount || 0;

  console.log(`[PromptBuilder] Completed in ${duration}ms`);
  console.log(`[PromptBuilder] Tokens - Input: ${inputTokens}, Output: ${outputTokens}`);

  const text = response.text();

  // Extract JSON from response (handle markdown code blocks)
  let jsonText = text;
  const jsonMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (jsonMatch) {
    jsonText = jsonMatch[1].trim();
  }

  const parsed = JSON.parse(jsonText);

  return {
    prompt: parsed.prompt,
    negative_prompt: parsed.negative_prompt,
    inputTokens,
    outputTokens,
  };
}
