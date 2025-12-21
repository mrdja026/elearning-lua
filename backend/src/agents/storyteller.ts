import { GoogleGenerativeAI } from '@google/generative-ai';
import type { ResearchData, StoryData, StoryPage, ArtStyle } from '../types/story.js';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

const ART_STYLE_KEYWORDS: Record<ArtStyle, string> = {
  pixel: 'pixel art style, 16-bit retro game art, colorful pixels, cute pixel characters',
  fantasy: 'fantasy illustration style, magical atmosphere, ethereal lighting, rich colors, detailed illustration',
  cartoon: 'cartoon style, bright colors, friendly characters, animated look, fun and playful',
};

const SYSTEM_PROMPT = `You are a children's storyteller creating educational stories for ages 5-8.

TASK: Create a 3-page story based on the provided research facts.

STORY RULES:
1. Create a FRIENDLY CHARACTER as the guide (give them a fun name related to the topic)
2. Each page should teach ONE fact from the research
3. Use SHORT sentences (under 12 words)
4. Make it FUN and ENGAGING
5. Include dialogue and action
6. End with a happy/curious note

PAGE STRUCTURE (each page needs ALL of these):
- story_text: The story content for this page (50-100 words)
- question: A question to check understanding (related to the page's fact)
- hint: A helpful hint for the question
- image_prompt: Description for generating an illustration

QUESTION TYPES:
- "yesno": Yes/No question (set correct_answer_is_yes to true or false)
- "text": Fill-in-the-blank or short answer (set correct_answer to the expected word/phrase)

OUTPUT FORMAT (JSON only, no markdown):
{
  "title": "Story Title",
  "pages": [
    {
      "story_text": "Once upon a time...",
      "question_text": "Is the sky blue?",
      "question_type": "yesno",
      "correct_answer_is_yes": true,
      "hint_text": "Look up at the sky!",
      "image_prompt": "friendly cloud character floating in blue sky, [ART_STYLE]",
      "choice_labels": ["Yes", "No"]
    },
    {
      "story_text": "...",
      "question_text": "What color does light bounce the most?",
      "question_type": "text",
      "correct_answer": "blue",
      "hint_text": "It rhymes with 'glue'!",
      "image_prompt": "...",
      "choice_labels": ["Yes", "No"]
    },
    ...
  ]
}`;

export interface StorytellerResult {
  storyData: StoryData;
  inputTokens: number;
  outputTokens: number;
  durationMs: number;
}

export async function runStoryteller(
  researchData: ResearchData,
  artStyle: ArtStyle,
  topic: string
): Promise<StorytellerResult> {
  const startTime = Date.now();

  // DEV_MODE: Return mock response
  if (process.env.DEV_MODE?.trim().toLowerCase() === 'true') {
    console.log('[Storyteller] DEV_MODE: Returning mock story');
    return {
      storyData: {
        title: `The Amazing ${topic} Adventure`,
        topic,
        general_image_prompt: `${ART_STYLE_KEYWORDS[artStyle]}, educational children's book`,
        pages: [
          {
            id: 1,
            image_path: '',
            image_prompt: `friendly character learning about ${topic}, ${ART_STYLE_KEYWORDS[artStyle]}`,
            question_text: `Let's learn about ${topic}! Are you ready to explore?`,
            hint_text: 'Say yes to start the adventure!',
            question_type: 'yesno',
            choice_labels: ['Yes!', 'Not yet'],
            correct_answer_is_yes: true,
          },
          {
            id: 2,
            image_path: '',
            image_prompt: `character discovering something amazing, ${ART_STYLE_KEYWORDS[artStyle]}`,
            question_text: 'What did we learn today?',
            hint_text: 'Think about the main topic!',
            question_type: 'text',
            choice_labels: ['Yes', 'No'],
            correct_answer: topic.split(' ')[0].toLowerCase(),
          },
          {
            id: 3,
            image_path: '',
            image_prompt: `happy ending celebration, ${ART_STYLE_KEYWORDS[artStyle]}`,
            question_text: 'Did you have fun learning?',
            hint_text: 'We hope so!',
            question_type: 'yesno',
            choice_labels: ['Yes!', 'Kinda'],
            correct_answer_is_yes: true,
          },
        ],
      },
      inputTokens: 0,
      outputTokens: 0,
      durationMs: Date.now() - startTime,
    };
  }

  const styleKeywords = ART_STYLE_KEYWORDS[artStyle];
  const factsFormatted = researchData.facts.map((f, i) => `${i + 1}. ${f}`).join('\n');

  const userMessage = `TOPIC: ${topic}

ART STYLE TO USE IN IMAGE PROMPTS: ${styleKeywords}

RESEARCH FACTS TO TEACH:
${factsFormatted}

Create a 3-page children's story that teaches these facts in a fun way.
Remember to replace [ART_STYLE] in image prompts with: ${styleKeywords}`;

  console.log('[Storyteller] Calling Gemini API...');
  console.log(`[Storyteller] Topic: "${topic.substring(0, 50)}..."`);
  console.log(`[Storyteller] Art style: ${artStyle}`);
  console.log(`[Storyteller] Facts count: ${researchData.facts.length}`);

  const model = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash-lite',
    systemInstruction: SYSTEM_PROMPT,
  });

  let result;
  try {
    result = await model.generateContent(userMessage);
  } catch (err) {
    console.error('[Storyteller] Gemini API call failed!');
    console.error('[Storyteller] Error:', err instanceof Error ? err.message : err);
    throw new Error(`Gemini API error: ${err instanceof Error ? err.message : String(err)}`);
  }

  const response = result.response;
  const duration = Date.now() - startTime;
  const inputTokens = response.usageMetadata?.promptTokenCount || 0;
  const outputTokens = response.usageMetadata?.candidatesTokenCount || 0;

  console.log(`[Storyteller] API call completed in ${duration}ms`);
  console.log(`[Storyteller] Tokens - Input: ${inputTokens}, Output: ${outputTokens}`);

  const text = response.text();
  console.log(`[Storyteller] Raw response:\n${text.substring(0, 500)}...`);

  // Extract JSON from response
  let jsonText = text;
  const jsonMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (jsonMatch) {
    jsonText = jsonMatch[1].trim();
    console.log('[Storyteller] Extracted JSON from code block');
  }

  let parsed;
  try {
    parsed = JSON.parse(jsonText);
  } catch (err) {
    console.error('[Storyteller] Failed to parse JSON response!');
    console.error('[Storyteller] JSON text was:', jsonText.substring(0, 300));
    throw new Error(`Failed to parse Gemini response as JSON: ${err instanceof Error ? err.message : String(err)}`);
  }

  if (!parsed.title || !parsed.pages || !Array.isArray(parsed.pages)) {
    console.error('[Storyteller] Missing required fields in response!');
    throw new Error('Gemini response missing required fields: title or pages');
  }

  // Transform pages to match our schema
  const pages: StoryPage[] = parsed.pages.map((p: Record<string, unknown>, index: number) => ({
    id: index + 1,
    image_path: '',
    image_prompt: String(p.image_prompt || ''),
    question_text: String(p.story_text || '') + '\n\n' + String(p.question_text || ''),
    hint_text: String(p.hint_text || ''),
    question_type: p.question_type === 'text' ? 'text' : 'yesno',
    choice_labels: Array.isArray(p.choice_labels) ? p.choice_labels as [string, string] : ['Yes', 'No'],
    correct_answer_is_yes: p.question_type === 'yesno' ? Boolean(p.correct_answer_is_yes) : undefined,
    correct_answer: p.question_type === 'text' ? String(p.correct_answer || '') : undefined,
  }));

  console.log(`[Storyteller] Success! Created story "${parsed.title}" with ${pages.length} pages`);

  return {
    storyData: {
      title: parsed.title,
      topic,
      general_image_prompt: `${styleKeywords}, educational children's book illustration`,
      pages,
    },
    inputTokens,
    outputTokens,
    durationMs: duration,
  };
}
