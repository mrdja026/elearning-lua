import { serve } from '@hono/node-server';
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import 'dotenv/config';

import { generateImageRoute } from './routes/generate-image.js';
import { testRoutes } from './routes/test-routes.js';
import { storiesRoute } from './routes/stories.js';

const app = new Hono();

app.use('*', logger());
app.use('*', cors());

app.get('/', (c) => {
  return c.json({ message: 'LogicTales AI Pipeline API' });
});

app.route('/api', generateImageRoute);
app.route('/api', testRoutes);
app.route('/api', storiesRoute);

const port = parseInt(process.env.PORT || '3000');

console.log(`Server starting on port ${port}`);
console.log(`DEV_MODE: ${process.env.DEV_MODE} (type: ${typeof process.env.DEV_MODE})`);

serve({
  fetch: app.fetch,
  port,
});
