import { Redis } from '@upstash/redis';
import crypto from 'crypto';
import type { ResearchData, WizardSession, ArtStyle, TargetAge } from '../types/story.js';

// In-memory fallback cache for DEV_MODE or when Redis is not configured
const memoryCache = new Map<string, { value: string; expiresAt: number }>();

// Initialize Redis client (lazy - only when needed)
let redisClient: Redis | null = null;

function getRedisClient(): Redis | null {
  if (redisClient) return redisClient;

  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;

  if (!url || !token) {
    return null;
  }

  redisClient = new Redis({ url, token });
  return redisClient;
}

function isDevMode(): boolean {
  return process.env.DEV_MODE?.trim().toLowerCase() === 'true';
}

function useMemoryCache(): boolean {
  return isDevMode() || !getRedisClient();
}

// ============================================
// Generic Cache Operations
// ============================================

export async function getCache<T>(key: string): Promise<T | null> {
  if (useMemoryCache()) {
    const entry = memoryCache.get(key);
    if (!entry) return null;
    if (Date.now() > entry.expiresAt) {
      memoryCache.delete(key);
      return null;
    }
    return JSON.parse(entry.value) as T;
  }

  const redis = getRedisClient();
  if (!redis) return null;

  try {
    const value = await redis.get<T>(key);
    return value;
  } catch (err) {
    console.error('[Cache] Redis get error:', err);
    return null;
  }
}

export async function setCache<T>(key: string, value: T, ttlSeconds: number): Promise<void> {
  const serialized = JSON.stringify(value);

  if (useMemoryCache()) {
    memoryCache.set(key, {
      value: serialized,
      expiresAt: Date.now() + ttlSeconds * 1000,
    });
    console.log(`[Cache] Memory: Set ${key} (TTL: ${ttlSeconds}s)`);
    return;
  }

  const redis = getRedisClient();
  if (!redis) return;

  try {
    await redis.set(key, value, { ex: ttlSeconds });
    console.log(`[Cache] Redis: Set ${key} (TTL: ${ttlSeconds}s)`);
  } catch (err) {
    console.error('[Cache] Redis set error:', err);
  }
}

export async function deleteCache(key: string): Promise<void> {
  if (useMemoryCache()) {
    memoryCache.delete(key);
    console.log(`[Cache] Memory: Deleted ${key}`);
    return;
  }

  const redis = getRedisClient();
  if (!redis) return;

  try {
    await redis.del(key);
    console.log(`[Cache] Redis: Deleted ${key}`);
  } catch (err) {
    console.error('[Cache] Redis delete error:', err);
  }
}

// ============================================
// Research Cache (24h TTL)
// ============================================

const RESEARCH_TTL = 24 * 60 * 60; // 24 hours

function getResearchKey(topic: string): string {
  const hash = crypto.createHash('sha256').update(topic.toLowerCase().trim()).digest('hex').substring(0, 16);
  return `story:research:${hash}`;
}

export async function getCachedResearch(topic: string): Promise<ResearchData | null> {
  const key = getResearchKey(topic);
  const data = await getCache<ResearchData>(key);
  if (data) {
    console.log(`[Cache] Research cache HIT for topic: "${topic.substring(0, 30)}..."`);
  }
  return data;
}

export async function setCachedResearch(topic: string, data: ResearchData): Promise<void> {
  const key = getResearchKey(topic);
  await setCache(key, data, RESEARCH_TTL);
  console.log(`[Cache] Research cached for topic: "${topic.substring(0, 30)}..."`);
}

// ============================================
// Session Management (30min TTL)
// ============================================

const SESSION_TTL = 30 * 60; // 30 minutes

function getSessionKey(sessionId: string): string {
  return `story:session:${sessionId}`;
}

function generateSessionId(): string {
  return crypto.randomBytes(16).toString('hex');
}

export interface CreateSessionOptions {
  topic: string;
  artStyle: ArtStyle;
  targetAge?: TargetAge;
  pageCount?: number;
  pageHints?: string[];
}

export async function createSession(options: CreateSessionOptions): Promise<WizardSession> {
  const session: WizardSession = {
    id: generateSessionId(),
    topic: options.topic,
    artStyle: options.artStyle,
    targetAge: options.targetAge,
    pageCount: options.pageCount,
    pageHints: options.pageHints,
    step: 'started',
    createdAt: new Date().toISOString(),
  };

  await setCache(getSessionKey(session.id), session, SESSION_TTL);
  console.log(`[Cache] Session created: ${session.id}`);
  return session;
}

export async function getSession(sessionId: string): Promise<WizardSession | null> {
  const session = await getCache<WizardSession>(getSessionKey(sessionId));
  if (!session) {
    console.log(`[Cache] Session not found: ${sessionId}`);
  }
  return session;
}

export async function updateSession(sessionId: string, updates: Partial<WizardSession>): Promise<WizardSession | null> {
  const session = await getSession(sessionId);
  if (!session) return null;

  const updated = { ...session, ...updates };
  await setCache(getSessionKey(sessionId), updated, SESSION_TTL);
  console.log(`[Cache] Session updated: ${sessionId} (step: ${updated.step})`);
  return updated;
}

export async function deleteSession(sessionId: string): Promise<void> {
  await deleteCache(getSessionKey(sessionId));
  console.log(`[Cache] Session deleted: ${sessionId}`);
}
