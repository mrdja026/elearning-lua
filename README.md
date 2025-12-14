# LogicTales

An educational children's game that combines storytelling with logic puzzles. Players navigate through interactive stories where branching paths are determined by math and logic decisions.

## Features

- **Play Mode** - Play through interactive stories with branching logic
- **Creator Studio** - Build your own stories with a visual editor
- **AI Image Generation** - Generate illustrations using AI (Stability AI + Gemini)
- **Marketplace** - Share and download community stories (coming soon)

## Tech Stack

### Game Client
- **LOVE2D** - Lua-based 2D game framework
- **Slab** - Immediate Mode GUI library for Creator Studio

### Backend
- **Hono** - TypeScript web framework
- **Supabase** - PostgreSQL database with authentication
- **Gemini** - Prompt optimization for image generation
- **Stability AI** - Image generation
- **Cloudinary** - Image hosting

## Prerequisites

- [LOVE2D](https://love2d.org/) (11.x or later)
- [Node.js](https://nodejs.org/) (18.x or later)
- API keys (see below)

## Project Structure

```
eai-learning/
├── main.lua              # Game entry point
├── screens/              # Game screens (play, creator)
├── components/           # UI components
├── libraries/            # Lua libraries (Slab, json)
├── stories/              # Story JSON files
├── backend/              # Node.js API server
│   ├── src/
│   │   ├── routes/       # API endpoints
│   │   ├── services/     # Business logic
│   │   └── middleware/   # Auth middleware
│   └── supabase/         # Database scripts
└── openspec/             # Project specifications
```

## Setup

### 1. Clone and Install

```bash
git clone <repo-url>
cd eai-learning

# Install backend dependencies
cd backend
npm install
```

### 2. Configure Environment

Copy the example environment file:

```bash
cp backend/.env.example backend/.env
```

Edit `backend/.env` with your keys:

```env
# Development mode - skips all API calls, returns mock data
DEV_MODE=true

# AI Pipeline (not needed when DEV_MODE=true)
GEMINI_API_KEY=your_gemini_key
STABILITY_API_KEY=your_stability_key
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_key
CLOUDINARY_API_SECRET=your_cloudinary_secret

# Supabase (not needed when DEV_MODE=true)
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### 3. Database Setup (Optional - not needed for DEV_MODE)

1. Create a [Supabase](https://supabase.com/) project
2. Run the SQL scripts in order:
   - `backend/supabase/01_tables.sql`
   - `backend/supabase/02_rls.sql`

## Running the Project

### Backend Server

```bash
cd backend
npm run dev
```

Server runs at `http://localhost:3000`

### Game Client

```bash
# From project root
love .
```

Or on Windows, drag the project folder onto `love.exe`.

## API Keys

| Service | Purpose | Get Key From |
|---------|---------|--------------|
| Gemini | Prompt optimization | [Google AI Studio](https://aistudio.google.com/) |
| Stability AI | Image generation | [Stability Platform](https://platform.stability.ai/) |
| Cloudinary | Image hosting | [Cloudinary Console](https://cloudinary.com/) |
| Supabase | Database + Auth | [Supabase Dashboard](https://supabase.com/) |

## Development Mode

Set `DEV_MODE=true` in `backend/.env` to:
- Skip all external API calls
- Return mock image URLs
- Skip database operations
- Skip authentication

This allows full development without any API keys or credits.

## Game Controls

| Key | Action |
|-----|--------|
| Tab | Switch between Play/Create modes |
| Arrow Keys | Navigate choices |
| Enter/Space | Select choice |
| Escape | Close dialogs |

## License

ISC
