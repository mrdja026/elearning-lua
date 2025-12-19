import { GoogleGenerativeAI } from '@google/generative-ai';
import type { StoryData, CriticReview, ResearchData } from '../types/story.js';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

const SYSTEM_PROMPT = `You are a content reviewer for children's educational stories (ages 5-8).

TASK: Review the story and flag any issues. DO NOT reject - only provide feedback.

REVIEW CRITERIA:
1. AGE-APPROPRIATENESS: No scary, violent, or inappropriate content
2. FACTUAL ACCURACY: Questions and answers match the research facts
3. READING LEVEL: Sentences are short and simple (under 15 words)
4. ENGAGEMENT: Story is fun and interesting for kids
5. SAFETY: No content that could be harmful or misleading

SCORING:
- readabilityScore: 0-100 (based on sentence length, vocabulary complexity)
  - 90-100: Perfect for 5-8 year olds
  - 70-89: Good, minor adjustments helpful
  - 50-69: Needs simplification
  - Below 50: Too complex for target age

OUTPUT FORMAT (JSON only, no markdown):
{
  "approved": true,
  "warnings": ["Warning 1 if any", "Warning 2 if any"],
  "suggestions": ["Suggestion 1", "Suggestion 2"],
  "readabilityScore": 85
}

IMPORTANT:
- Set approved=true unless there are SERIOUS issues (violence, inappropriate content, dangerous misinformation)
- Warnings are for minor issues that don't block approval
- Always provide at least one constructive suggestion`;

export interface CriticResult {
  review: CriticReview;
  inputTokens: number;
  outputTokens: number;
  durationMs: number;
}

export async function runCritic(
  storyData: StoryData,
  researchData: ResearchData
): Promise<CriticResult> {
  const startTime = Date.now();

  // DEV_MODE: Return mock response
  if (process.env.DEV_MODE?.trim().toLowerCase() === 'true') {
    console.log('[Critic] DEV_MODE: Returning mock review');
    return {
      review: {
        approved: true,
        warnings: [],
        readabilityScore: 88,
      },
      inputTokens: 0,
      outputTokens: 0,
      durationMs: Date.now() - startTime,
    };
  }

  const storyContent = storyData.pages
    .map((p, i) => `Page ${i + 1}:\n  Question: ${p.question_text}\n  Answer: ${p.correct_answer || (p.correct_answer_is_yes ? 'Yes' : 'No')}`)
    .join('\n\n');

  const factsFormatted = researchData.facts.map((f, i) => `${i + 1}. ${f}`).join('\n');

  const userMessage = `STORY TO REVIEW:
Title: ${storyData.title}
Topic: ${storyData.topic}

PAGES:
${storyContent}

ORIGINAL RESEARCH FACTS:
${factsFormatted}

Please review this story for children aged 5-8.`;

  console.log('[Critic] Calling Gemini API...');
  console.log(`[Critic] Story: "${storyData.title}"`);
  console.log(`[Critic] Pages: ${storyData.pages.length}`);

  const model = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash-lite',
    systemInstruction: SYSTEM_PROMPT,
  });

  let result;
  try {
    result = await model.generateContent(userMessage);
  } catch (err) {
    console.error('[Critic] Gemini API call failed!');
    console.error('[Critic] Error:', err instanceof Error ? err.message : err);
    throw new Error(`Gemini API error: ${err instanceof Error ? err.message : String(err)}`);
  }

  const response = result.response;
  const duration = Date.now() - startTime;
  const inputTokens = response.usageMetadata?.promptTokenCount || 0;
  const outputTokens = response.usageMetadata?.candidatesTokenCount || 0;

  console.log(`[Critic] API call completed in ${duration}ms`);
  console.log(`[Critic] Tokens - Input: ${inputTokens}, Output: ${outputTokens}`);

  const text = response.text();
  console.log(`[Critic] Raw response:\n${text}`);

  // Extract JSON from response
  let jsonText = text;
  const jsonMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (jsonMatch) {
    jsonText = jsonMatch[1].trim();
    console.log('[Critic] Extracted JSON from code block');
  }

  let parsed;
  try {
    parsed = JSON.parse(jsonText);
  } catch (err) {
    console.error('[Critic] Failed to parse JSON response!');
    console.error('[Critic] JSON text was:', jsonText.substring(0, 200));
    // Return a default approval if parsing fails
    console.log('[Critic] Falling back to default approval');
    return {
      review: {
        approved: true,
        warnings: ['Review parsing failed - manual review recommended'],
        readabilityScore: 75,
      },
      inputTokens,
      outputTokens,
      durationMs: duration,
    };
  }

  console.log(`[Critic] Success! Approved: ${parsed.approved}, Score: ${parsed.readabilityScore}`);

  return {
    review: {
      approved: parsed.approved !== false, // Default to approved
      warnings: Array.isArray(parsed.warnings) ? parsed.warnings : [],
      readabilityScore: typeof parsed.readabilityScore === 'number' ? parsed.readabilityScore : 75,
    },
    inputTokens,
    outputTokens,
    durationMs: duration,
  };
}
