# Hanly

English-Chinese vocabulary dictionary, flashcard review (FSRS spaced repetition), and quiz app. AI-powered translations personalized to your learning context.

## Features

- **Authentication** — Email/password signup and login via Supabase Auth
- **6-Step Onboarding** — Name, Chinese level, learning purposes, interests, preferences, and AI-generated starter vocabulary
- **Context-Aware Translation** — Translate any word/phrase (English, Chinese, pinyin, or mixed input). Results are tailored to your profile, level, and interests using GPT-4o-mini
- **Personal Dictionary** — Save translations to your word bank. Search, browse, archive, and delete words
- **Flashcard Review** — FSRS-4.5 spaced repetition algorithm schedules reviews at optimal intervals. Grade cards as Again/Hard/Good/Easy
- **Pinyin Ruby Text** — Chinese characters displayed with pinyin annotations above each character, with vocabulary word highlighting in example sentences
- **Profile Management** — Edit Chinese level, learning purposes, interests, and additional context. Regenerate AI context on save
- **Dark/Light Theme** — Light mode by default. Toggle in profile preferences. Theme cached locally via SharedPreferences for instant loading
- **Glassmorphic UI** — Custom glass card components with backdrop blur, gradient backgrounds, and smooth animations

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (iOS, Android, Web, macOS, Windows) |
| State Management | Riverpod |
| Navigation | GoRouter |
| Backend | Supabase (Auth, PostgreSQL, Edge Functions, RLS) |
| AI | OpenAI GPT-4o-mini (via Supabase Edge Functions) |
| Spaced Repetition | FSRS-4.5 algorithm |
| Design | Material 3 + custom glassmorphism theme |

## Project Structure

```
Hanly/
├── lib/
│   ├── main.dart                          # Entry point
│   ├── app.dart                           # MaterialApp configuration
│   ├── core/
│   │   ├── providers/                     # Supabase client, theme, tab state
│   │   ├── router/                        # GoRouter navigation
│   │   ├── theme/                         # Colors, themes, glass decoration
│   │   └── utils/                         # FSRS algorithm
│   ├── features/
│   │   ├── auth/                          # Login/signup
│   │   ├── home/                          # Translation, flashcards
│   │   ├── dictionary/                    # Word bank browser
│   │   ├── onboarding/                    # 6-step profile setup
│   │   └── profile/                       # Settings & profile editing
│   ├── models/                            # Data models (Profile, UserWord, etc.)
│   └── widgets/                           # Shared UI (GlassCard, RubyText, etc.)
├── supabase/
│   ├── functions/                         # Edge functions (translate, save-word, etc.)
│   └── migrations/                        # SQL schema & RLS policies
└── progress/                              # Feature specs & planning docs
```

## Database Schema

Four core tables in Supabase PostgreSQL:

**profiles** — User identity and learning context
- display_name, chinese_level, learning_purposes[], interests[], context_summary, context_tags[], daily_word_goal, theme_preference
- Auto-created on signup via trigger

**global_words** — Shared canonical word bank
- chinese, pinyin, segments (jsonb), meaning, categories[]
- UNIQUE(chinese, pinyin) for deduplication. Tracks add_count across users

**user_words** — Personal word bank entries
- english, chinese, pinyin, meaning, notes, examples (jsonb), segments (jsonb), categories[]
- Links to global_words. Auto-creates review_card on insert via trigger

**review_cards** — FSRS flashcard state
- stability, difficulty, reps, lapses, state, next_review_at
- Indexed on (user_id, next_review_at) for efficient due card queries

**RPC Functions:**
- `get_due_cards(user_id, category)` — Returns due flashcards joined with word data
- `search_user_words(user_id, query, archived)` — Full-text search across user's words

## Supabase Edge Functions

| Function | Purpose |
|----------|---------|
| `translate` | Translates word/phrase via GPT-4o-mini with user context personalization. Returns pinyin segments, example sentences, and category tags |
| `save-word` | Atomically saves word to both global_words and user_words. Handles deduplication |
| `batch-save-words` | Bulk save for onboarding word suggestions (service role) |
| `generate-context` | Generates context_summary and context_tags from user profile data |
| `suggest-words` | Generates 18 personalized starter vocabulary words based on user level and interests |
| `delete-account` | Cascading user deletion with service role |

## Setup

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (3.x+)
- [Supabase CLI](https://supabase.com/docs/guides/cli) (for local dev or deploying functions)
- A Supabase project (free at [supabase.com](https://supabase.com))
- OpenAI API key (for translation functions)

### 1. Clone and install

```bash
git clone https://github.com/your-username/Hanly.git
cd Hanly
flutter pub get
```

### 2. Environment setup

Create a `.env` file in the project root:

```
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=your_anon_key
```

### 3. Database setup

Run migrations in your Supabase SQL editor (in order):
1. `supabase/migrations/001_initial_schema.sql`
2. `supabase/migrations/002_iteration1.sql`
3. `supabase/migrations/003_iteration2.sql`
4. `supabase/migrations/004_iteration3.sql`

Enable **Email/Password** auth in Supabase Dashboard > Authentication > Providers.

### 4. Deploy edge functions

```bash
cd supabase
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set OPENAI_API_KEY=sk-your-key
supabase functions deploy translate
supabase functions deploy save-word
supabase functions deploy batch-save-words
supabase functions deploy generate-context
supabase functions deploy suggest-words
supabase functions deploy delete-account
```

### 5. Run the app

```bash
# Web
flutter run -d chrome

# macOS
flutter run -d macos

# iOS Simulator
flutter run -d ios
```

## Useful Commands

```bash
flutter analyze              # Check for errors
flutter build web            # Build for web
flutter test                 # Run tests
```
