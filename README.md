# Hanly

English <-> Chinese vocabulary dictionary, flashcard review (spaced repetition), and quiz app.

## Project Structure

```
Hanly/
├── frontend/       # Flutter app (iOS, Android, Web, macOS, Windows)
└── backend/        # Supabase Edge Functions + database migrations
    └── supabase/
        ├── functions/       # Edge Functions (e.g. translate via OpenAI)
        └── migrations/      # SQL schema + RLS policies
```

## Prerequisites

### Flutter (required)

```bash
# Install via Homebrew (macOS)
brew install --cask flutter

# Verify
flutter --version
```

Or download from [flutter.dev](https://flutter.dev/docs/get-started/install).

### Supabase (for backend)

You need a Supabase project. Two options:

**Option A: Hosted (easiest)** — Create a free project at [supabase.com](https://supabase.com). Copy your **Project URL** and **anon key** from Settings > API.

**Option B: Local** — Requires [Docker](https://docs.docker.com/get-docker/) and the Supabase CLI:

```bash
brew install supabase/tap/supabase
```

## Running Locally

### 1. Frontend (Flutter app)

```bash
# Install dependencies
cd frontend
flutter pub get

# Run on Chrome (no Xcode needed)
flutter run -d chrome

# Run on macOS (requires Xcode)
flutter run -d macos \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY

# Run on iOS Simulator (requires Xcode)
flutter run -d ios \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Replace `YOUR_PROJECT` and `YOUR_ANON_KEY` with your actual Supabase credentials.

### 2. Backend (Supabase)

#### Using hosted Supabase

1. Go to your Supabase dashboard > SQL Editor
2. Paste and run the contents of `backend/supabase/migrations/001_initial_schema.sql`
3. Enable **Email/Password** auth in Authentication > Providers
4. To use the translate function, deploy the Edge Function:

```bash
cd backend/supabase
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set OPENAI_API_KEY=sk-your-key
supabase functions deploy translate
```

#### Using local Supabase

```bash
cd backend/supabase

# Start local Supabase (requires Docker running)
supabase start

# This prints your local credentials:
#   API URL:   http://localhost:54321
#   anon key:  eyJ...
#   DB URL:    postgresql://...

# Run migrations
supabase db push

# Deploy edge function locally
supabase functions serve translate --env-file .env
```

Then run the Flutter app pointing to local:

```bash
cd frontend
flutter run -d chrome \
  --dart-define=SUPABASE_URL=http://localhost:54321 \
  --dart-define=SUPABASE_ANON_KEY=YOUR_LOCAL_ANON_KEY
```

## Useful Commands

```bash
# Analyze code for errors
cd frontend && flutter analyze

# Build for web
cd frontend && flutter build web

# Run tests
cd frontend && flutter test

# Code generation (Riverpod, Freezed)
cd frontend && dart run build_runner build --delete-conflicting-outputs
```

## Tech Stack

- **Frontend**: Flutter, Riverpod, GoRouter, Material 3 + Glassmorphism
- **Backend**: Supabase (Auth, PostgreSQL, Edge Functions)
- **AI**: OpenAI GPT-4o-mini (via Supabase Edge Function — key never in client)
