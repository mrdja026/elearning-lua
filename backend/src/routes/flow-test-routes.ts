import { Hono } from 'hono';
import { enhanceStoryPrompt } from '../agents/prompt-enhancer.js';
import { runImageAgent } from '../agents/image-agent.js';
import type { ArtStyle, TargetAge } from '../types/story.js';

export const flowTestRoutes = new Hono();

// In-memory store for flow sessions
const flowSessions = new Map<string, FlowSession>();

interface FlowSession {
  id: string;
  topic: string;
  artStyle: ArtStyle;
  targetAge: TargetAge;
  step: 'started' | 'confirmed' | 'images_started' | 'completed';
  enhancedPrompt?: string;
  suggestedCharacter?: string;
  keyThemes?: string[];
  pages: Array<{
    pageNumber: number;
    originalPrompt: string;
    enhancedPrompt: string;
    cloudinaryUrl: string;
  }>;
  createdAt: Date;
}

function generateId(): string {
  return `flow_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
}

// Clean up old sessions (older than 30 minutes)
function cleanupSessions() {
  const now = Date.now();
  for (const [id, session] of flowSessions.entries()) {
    if (now - session.createdAt.getTime() > 30 * 60 * 1000) {
      flowSessions.delete(id);
    }
  }
}

// Step 1: Start the flow
// curl -X POST http://localhost:3000/api/flow-test/start -H "Content-Type: application/json" -d '{"topic": "why is the sky blue", "artStyle": "fantasy"}'
flowTestRoutes.post('/start', async (c) => {
  cleanupSessions();
  console.log('\n============================================');
  console.log('[FlowTest] POST /api/flow-test/start');

  try {
    const body = await c.req.json<{ topic: string; artStyle?: ArtStyle; targetAge?: TargetAge }>();

    if (!body.topic) {
      return c.json({ error: 'Missing required field: topic' }, 400);
    }

    const session: FlowSession = {
      id: generateId(),
      topic: body.topic,
      artStyle: body.artStyle || 'fantasy',
      targetAge: body.targetAge || '5-8',
      step: 'started',
      pages: [],
      createdAt: new Date(),
    };

    flowSessions.set(session.id, session);

    console.log(`[FlowTest] Session created: ${session.id}`);
    console.log(`[FlowTest] Topic: "${session.topic}"`);
    console.log(`[FlowTest] Target Age: ${session.targetAge}`);
    console.log('============================================\n');

    return c.json({
      success: true,
      sessionId: session.id,
      targetAge: session.targetAge,
      step: session.step,
      question: {
        type: 'yesno',
        text: `Are you ready to generate a story about "${session.topic}"?`,
        hint: 'yes',
        correctAnswer: 'yes',
      },
      nextAction: 'POST /api/flow-test/confirm with { sessionId, answer: "yes" }',
    });
  } catch (error) {
    console.error('[FlowTest] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Step 2: Confirm and enhance story prompt
// curl -X POST http://localhost:3000/api/flow-test/confirm -H "Content-Type: application/json" -d '{"sessionId": "xxx", "answer": "yes"}'
flowTestRoutes.post('/confirm', async (c) => {
  console.log('\n============================================');
  console.log('[FlowTest] POST /api/flow-test/confirm');

  try {
    const body = await c.req.json<{ sessionId: string; answer: string }>();

    if (!body.sessionId || !body.answer) {
      return c.json({ error: 'Missing required fields: sessionId, answer' }, 400);
    }

    const session = flowSessions.get(body.sessionId);
    if (!session) {
      return c.json({ error: 'Session not found or expired' }, 404);
    }

    if (session.step !== 'started') {
      return c.json({ error: `Invalid step: expected 'started', got '${session.step}'` }, 400);
    }

    if (body.answer.toLowerCase() !== 'yes') {
      return c.json({
        success: false,
        message: 'You answered no. Flow cancelled.',
        hint: 'Try again with answer: "yes"',
      });
    }

    console.log(`[FlowTest] Session: ${session.id}`);
    console.log(`[FlowTest] Target Age: ${session.targetAge}`);
    console.log('[FlowTest] Enhancing story prompt...');

    // Enhance the story prompt
    const enhanceResult = await enhanceStoryPrompt(session.topic, session.targetAge);

    session.enhancedPrompt = enhanceResult.enhancedPrompt;
    session.suggestedCharacter = enhanceResult.suggestedCharacter;
    session.keyThemes = enhanceResult.keyThemes;
    session.step = 'confirmed';

    console.log(`[FlowTest] Enhanced prompt ready`);
    console.log('============================================\n');

    return c.json({
      success: true,
      sessionId: session.id,
      step: session.step,
      prompts: {
        original: session.topic,
        enhanced: session.enhancedPrompt,
        suggestedCharacter: session.suggestedCharacter,
        keyThemes: session.keyThemes,
      },
      question: {
        type: 'yesno',
        text: 'Are you sure you want to generate the cover image?',
        hint: 'yes',
        correctAnswer: 'yes',
      },
      nextAction: 'POST /api/flow-test/generate-cover with { sessionId, answer: "yes" }',
    });
  } catch (error) {
    console.error('[FlowTest] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Step 3: Generate cover image
// curl -X POST http://localhost:3000/api/flow-test/generate-cover -H "Content-Type: application/json" -d '{"sessionId": "xxx", "answer": "yes"}'
flowTestRoutes.post('/generate-cover', async (c) => {
  console.log('\n============================================');
  console.log('[FlowTest] POST /api/flow-test/generate-cover');

  try {
    const body = await c.req.json<{ sessionId: string; answer: string }>();

    if (!body.sessionId || !body.answer) {
      return c.json({ error: 'Missing required fields: sessionId, answer' }, 400);
    }

    const session = flowSessions.get(body.sessionId);
    if (!session) {
      return c.json({ error: 'Session not found or expired' }, 404);
    }

    if (session.step !== 'confirmed') {
      return c.json({ error: `Invalid step: expected 'confirmed', got '${session.step}'` }, 400);
    }

    if (body.answer.toLowerCase() !== 'yes') {
      return c.json({
        success: false,
        message: 'You answered no. Staying at current step.',
        hint: 'Try again with answer: "yes"',
      });
    }

    console.log(`[FlowTest] Session: ${session.id}`);
    console.log('[FlowTest] Generating cover image...');

    // Generate cover image
    const coverPrompt = `Book cover illustration for a children's story about ${session.topic}, featuring ${session.suggestedCharacter || 'a friendly character'}`;
    const coverResult = await runImageAgent(coverPrompt, session.artStyle, session.topic);

    session.pages.push({
      pageNumber: 0,
      originalPrompt: coverPrompt,
      enhancedPrompt: coverResult.enhancedPrompt,
      cloudinaryUrl: coverResult.cloudinaryUrl,
    });

    session.step = 'images_started';

    console.log(`[FlowTest] Cover image generated`);
    console.log('============================================\n');

    return c.json({
      success: true,
      sessionId: session.id,
      step: session.step,
      coverImage: {
        originalPrompt: coverPrompt,
        enhancedPrompt: coverResult.enhancedPrompt,
        cloudinaryUrl: coverResult.cloudinaryUrl,
      },
      question: {
        type: 'yesno',
        text: 'Are you sure you want to generate the page images?',
        hint: 'yes',
        correctAnswer: 'yes',
      },
      nextAction: 'POST /api/flow-test/generate-pages with { sessionId, answer: "yes" }',
    });
  } catch (error) {
    console.error('[FlowTest] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Step 4: Generate page images
// curl -X POST http://localhost:3000/api/flow-test/generate-pages -H "Content-Type: application/json" -d '{"sessionId": "xxx", "answer": "yes"}'
flowTestRoutes.post('/generate-pages', async (c) => {
  console.log('\n============================================');
  console.log('[FlowTest] POST /api/flow-test/generate-pages');

  try {
    const body = await c.req.json<{ sessionId: string; answer: string }>();

    if (!body.sessionId || !body.answer) {
      return c.json({ error: 'Missing required fields: sessionId, answer' }, 400);
    }

    const session = flowSessions.get(body.sessionId);
    if (!session) {
      return c.json({ error: 'Session not found or expired' }, 404);
    }

    if (session.step !== 'images_started') {
      return c.json({ error: `Invalid step: expected 'images_started', got '${session.step}'` }, 400);
    }

    if (body.answer.toLowerCase() !== 'yes') {
      return c.json({
        success: false,
        message: 'You answered no. Staying at current step.',
        hint: 'Try again with answer: "yes"',
      });
    }

    console.log(`[FlowTest] Session: ${session.id}`);
    console.log('[FlowTest] Generating page images...');

    // Generate 3 page images
    const pagePrompts = [
      `Page 1: A curious child discovering something amazing about ${session.topic}`,
      `Page 2: ${session.suggestedCharacter || 'A friendly guide'} explaining the science behind ${session.topic}`,
      `Page 3: A happy ending scene celebrating the learning journey about ${session.topic}`,
    ];

    const pageResults = [];
    for (let i = 0; i < pagePrompts.length; i++) {
      // Throttle: wait 3 seconds between API calls to avoid rate limits
      if (i > 0) {
        console.log(`[FlowTest] Throttling: waiting 3s before next image...`);
        await new Promise((resolve) => setTimeout(resolve, 3000));
      }
      console.log(`[FlowTest] Generating page ${i + 1}/3...`);
      const result = await runImageAgent(pagePrompts[i], session.artStyle, session.topic);
      session.pages.push({
        pageNumber: i + 1,
        originalPrompt: pagePrompts[i],
        enhancedPrompt: result.enhancedPrompt,
        cloudinaryUrl: result.cloudinaryUrl,
      });
      pageResults.push({
        page: i + 1,
        originalPrompt: pagePrompts[i],
        enhancedPrompt: result.enhancedPrompt,
        cloudinaryUrl: result.cloudinaryUrl,
      });
    }

    session.step = 'completed';

    console.log(`[FlowTest] All pages generated`);
    console.log('============================================\n');

    return c.json({
      success: true,
      sessionId: session.id,
      step: session.step,
      message: 'Flow complete! All images generated.',
      summary: {
        topic: session.topic,
        artStyle: session.artStyle,
        targetAge: session.targetAge,
        enhancedStoryPrompt: session.enhancedPrompt,
        suggestedCharacter: session.suggestedCharacter,
        keyThemes: session.keyThemes,
        images: session.pages.map((p) => ({
          page: p.pageNumber === 0 ? 'cover' : p.pageNumber,
          originalPrompt: p.originalPrompt,
          enhancedPrompt: p.enhancedPrompt,
          cloudinaryUrl: p.cloudinaryUrl,
        })),
      },
    });
  } catch (error) {
    console.error('[FlowTest] Error:', error);
    return c.json({ success: false, error: String(error) }, 500);
  }
});

// Get session status
flowTestRoutes.get('/status/:sessionId', async (c) => {
  const sessionId = c.req.param('sessionId');
  const session = flowSessions.get(sessionId);

  if (!session) {
    return c.json({ error: 'Session not found or expired' }, 404);
  }

  return c.json({
    success: true,
    sessionId: session.id,
    topic: session.topic,
    artStyle: session.artStyle,
    step: session.step,
    enhancedPrompt: session.enhancedPrompt,
    imagesGenerated: session.pages.length,
    pages: session.pages,
  });
});
