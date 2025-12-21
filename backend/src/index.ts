import { serve } from '@hono/node-server';
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import 'dotenv/config';

import { generateImageRoute } from './routes/generate-image.js';
import { generateStoryRoute } from './routes/generate-story.js';
import { testRoutes } from './routes/test-routes.js';
import { storiesRoute } from './routes/stories.js';
import { wizardRoutes } from './routes/wizard-routes.js';
import { flowTestRoutes } from './routes/flow-test-routes.js';

const app = new Hono();

app.use('*', logger());
app.use('*', cors());

app.get('/', (c) => {
  return c.json({ message: 'LogicTales AI Pipeline API' });
});

app.route('/api', generateImageRoute);
app.route('/api', generateStoryRoute);
app.route('/api', testRoutes);
app.route('/api', storiesRoute);
app.route('/api/story-wizard', wizardRoutes);
app.route('/api/flow-test', flowTestRoutes);

const port = parseInt(process.env.PORT || '3000');

console.log('\n============================================');
console.log('   LogicTales Backend Starting...');
console.log('============================================');
console.log(`Port: ${port}`);
console.log(`DEV_MODE: ${process.env.DEV_MODE?.trim().toLowerCase() === 'true' ? 'ON (mock data)' : 'OFF (live APIs)'}`);
console.log('');
console.log('API Keys Status:');
console.log(`  GEMINI_API_KEY: ${process.env.GEMINI_API_KEY ? '✓ Set (' + process.env.GEMINI_API_KEY.substring(0, 8) + '...)' : '✗ MISSING'}`);
console.log(`  STABILITY_API_KEY: ${process.env.STABILITY_API_KEY ? '✓ Set (' + process.env.STABILITY_API_KEY.substring(0, 8) + '...)' : '✗ MISSING'}`);
console.log(`  CLOUDINARY_CLOUD_NAME: ${process.env.CLOUDINARY_CLOUD_NAME ? '✓ Set' : '✗ MISSING'}`);
console.log(`  CLOUDINARY_API_KEY: ${process.env.CLOUDINARY_API_KEY ? '✓ Set' : '✗ MISSING'}`);
console.log(`  CLOUDINARY_API_SECRET: ${process.env.CLOUDINARY_API_SECRET ? '✓ Set' : '✗ MISSING'}`);
console.log('');
console.log('ADK + Cache Status:');
const hasRedis = process.env.UPSTASH_REDIS_REST_URL && process.env.UPSTASH_REDIS_REST_TOKEN;
console.log(`  UPSTASH_REDIS: ${hasRedis ? '✓ Configured' : '○ Not set (using in-memory cache)'}`);
console.log(`  @google/adk: ✓ Loaded`);
console.log('============================================\n');

serve({
  fetch: app.fetch,
  port,
});
