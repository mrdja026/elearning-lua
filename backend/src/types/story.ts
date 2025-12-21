// Types for ADK Story Generation Pipeline

export type ArtStyle = 'pixel' | 'fantasy' | 'cartoon';
export type TargetAge = '5-8' | '8-12' | '13-17' | '18+' | 'all';
export type QuestionType = 'yesno' | 'text' | 'multi';

export interface ResearchData {
  facts: string[];
  sourceUrls: string[];
}

export interface StoryPage {
  id: number;
  image_path: string;
  image_prompt: string;
  question_text: string;
  hint_text: string;
  question_type: QuestionType;
  choice_labels: [string, string];
  correct_answer_is_yes?: boolean;
  correct_answer?: string;
  questions?: Array<{
    question_text: string;
    correct_answer: string;
  }>;
}

export interface StoryData {
  title: string;
  topic: string;
  general_image_prompt: string;
  pages: StoryPage[];
}

export interface CriticReview {
  approved: boolean;
  warnings: string[];
  readabilityScore: number;
}

export interface GenerationMetadata {
  source: 'ai' | 'manual';
  grounded_facts: string[];
  source_urls: string[];
  timestamp: string;
}

export interface GeneratedStory extends StoryData {
  cover_image_path: string;
  target_age: TargetAge;
  art_style: ArtStyle;
  generation: GenerationMetadata;
  critic_review: CriticReview;
}

export type WizardStep = 'started' | 'researched' | 'generated' | 'completed';

export interface WizardSession {
  id: string;
  topic: string;
  artStyle: ArtStyle;
  step: WizardStep;
  createdAt: string;
  pageCount?: number;
  pageHints?: string[];
  targetAge?: TargetAge;
  researchData?: ResearchData;
  storyData?: StoryData;
  reviewData?: CriticReview;
}

// API Request/Response types
export interface GenerateStoryRequest {
  topic: string;
  artStyle?: ArtStyle;
}

export interface WizardStartRequest {
  topic: string;
  artStyle?: ArtStyle;
  targetAge?: TargetAge;
  pageCount?: number;
  pageHints?: string[];
}

export interface WizardStepRequest {
  sessionId: string;
}
