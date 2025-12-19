import { runResearcher, type ResearcherResult } from './researcher.js';
import { runStoryteller, type StorytellerResult } from './storyteller.js';
import { runCritic, type CriticResult } from './critic.js';
import { getCachedResearch, setCachedResearch } from '../services/cache.js';
import type { ArtStyle, ResearchData, StoryData, CriticReview } from '../types/story.js';

export interface PipelineResult {
  research: ResearchData;
  story: StoryData;
  review: CriticReview;
  metadata: {
    cached: boolean;
    totalDurationMs: number;
    tokens: {
      research: { input: number; output: number };
      story: { input: number; output: number };
      critic: { input: number; output: number };
    };
  };
}

export async function runPipeline(
  topic: string,
  artStyle: ArtStyle = 'fantasy'
): Promise<PipelineResult> {
  const startTime = Date.now();
  console.log('\n============================================');
  console.log('[Pipeline] Starting story generation pipeline');
  console.log(`[Pipeline] Topic: "${topic}"`);
  console.log(`[Pipeline] Art style: ${artStyle}`);
  console.log('============================================');

  let researchResult: ResearcherResult;
  let cached = false;

  // Step 1: Check cache for research
  console.log('\n[Pipeline] Step 1: Research');
  const cachedResearch = await getCachedResearch(topic);

  if (cachedResearch) {
    console.log('[Pipeline] Using cached research data');
    cached = true;
    researchResult = {
      facts: cachedResearch.facts,
      sourceUrls: cachedResearch.sourceUrls,
      inputTokens: 0,
      outputTokens: 0,
      durationMs: 0,
    };
  } else {
    console.log('[Pipeline] Running Researcher agent...');
    researchResult = await runResearcher(topic);

    // Cache the research results
    await setCachedResearch(topic, {
      facts: researchResult.facts,
      sourceUrls: researchResult.sourceUrls,
    });
  }

  console.log(`[Pipeline] ✓ Research complete (${researchResult.facts.length} facts)`);

  // Step 2: Generate story
  console.log('\n[Pipeline] Step 2: Story Generation');
  console.log('[Pipeline] Running Storyteller agent...');

  const storyResult: StorytellerResult = await runStoryteller(
    { facts: researchResult.facts, sourceUrls: researchResult.sourceUrls },
    artStyle,
    topic
  );

  console.log(`[Pipeline] ✓ Story generated: "${storyResult.storyData.title}"`);

  // Step 3: Review story
  console.log('\n[Pipeline] Step 3: Content Review');
  console.log('[Pipeline] Running Critic agent...');

  const criticResult: CriticResult = await runCritic(
    storyResult.storyData,
    { facts: researchResult.facts, sourceUrls: researchResult.sourceUrls }
  );

  console.log(`[Pipeline] ✓ Review complete (approved: ${criticResult.review.approved}, score: ${criticResult.review.readabilityScore})`);

  const totalDuration = Date.now() - startTime;

  console.log('\n============================================');
  console.log('[Pipeline] Pipeline Complete!');
  console.log(`[Pipeline] Total duration: ${totalDuration}ms`);
  console.log(`[Pipeline] Research cached: ${cached}`);
  console.log('============================================\n');

  return {
    research: {
      facts: researchResult.facts,
      sourceUrls: researchResult.sourceUrls,
    },
    story: storyResult.storyData,
    review: criticResult.review,
    metadata: {
      cached,
      totalDurationMs: totalDuration,
      tokens: {
        research: { input: researchResult.inputTokens, output: researchResult.outputTokens },
        story: { input: storyResult.inputTokens, output: storyResult.outputTokens },
        critic: { input: criticResult.inputTokens, output: criticResult.outputTokens },
      },
    },
  };
}

// Re-export individual agents for direct use
export { runResearcher } from './researcher.js';
export { runStoryteller } from './storyteller.js';
export { runCritic } from './critic.js';
