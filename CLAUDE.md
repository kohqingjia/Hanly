# Hanly — Build Instructions for Claude

You are Claude. Build a production-quality **Flutter** app called **Hanly**: an **English <-> Chinese** vocabulary dictionary + **flashcard review (spaced repetition based on the forgetting curve)** + **quiz app** for language learners.

> **Current build focus:** Login / Sign Up page (`/login`)

---

## 0) Non-negotiables

- **Single Flutter project** at the repo root for the client app. Supabase Edge Functions live in `/supabase/functions/` for any server-side logic (OpenAI calls).
- **Do NOT put the OpenAI API key in the Flutter app.** All OpenAI calls go through Supabase Edge Functions.
- Use **Supabase** for authentication (email/password + OAuth optional), database, and persistence.
- **Authentication is required.** Every screen except login/signup is protected. Use Supabase Auth with `supabase_flutter`.
- **All platforms:** iOS, Android, Web, macOS, Windows.
- Implement a **self-healing dev loop**: when there are build/runtime errors, read logs, identify cause, patch code, re-run until green.

---

## 1) Tech Stack

### Flutter App
- **Framework**: Flutter 3.22+ / Dart 3.4+
- **State management**: Riverpod (`flutter_riverpod` + `riverpod_annotation` + code generation)
- **Routing**: `go_router` with redirect guards for auth
- **Auth & DB**: `supabase_flutter`
- **HTTP**: `dio` (for Edge Function calls) or Supabase client's built-in `functions.invoke()`
- **UI toolkit**: Material 3 as base, heavily customized with glassmorphism theme
- **Icons**: `lucide_icons` or `hugeicons`
- **Fonts**: Inter (Google Fonts via `google_fonts` package)
- **Animations**: `flutter_animate` for entrance/transition animations
- **Shimmer loading**: `shimmer` package
- **Local storage**: `shared_preferences` (theme preference, onboarding flags)

### Supabase Edge Functions (`/supabase/functions/`)
- **Runtime**: Deno (TypeScript) — this is Supabase's Edge Function runtime
- **OpenAI**: `openai` npm package via Deno — all LLM calls happen here
- **Auth**: Edge Functions receive the user's JWT automatically; verify with `supabase.auth.getUser()`

### Project Structure
```
/
├── lib/
│   ├── main.dart                # App entry, ProviderScope, Supabase init
│   ├── app.dart                 # MaterialApp.router, theme, GoRouter
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_theme.dart       # ThemeData for dark & light
│   │   │   ├── app_colors.dart      # Color constants
│   │   │   └── glass_decoration.dart # Glassmorphism BoxDecoration helpers
│   │   ├── router/
│   │   │   └── app_router.dart      # GoRouter config + auth redirect
│   │   ├── providers/
│   │   │   └── supabase_provider.dart  # Supabase client provider
│   │   └── utils/
│   │       ├── sm2.dart             # SM-2 algorithm
│   │       └── debouncer.dart       # Search debounce utility
│   ├── features/
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   │   └── login_screen.dart
│   │   │   └── providers/
│   │   │       └── auth_provider.dart
│   │   ├── home/
│   │   │   ├── screens/
│   │   │   │   └── home_screen.dart
│   │   │   ├── providers/
│   │   │   │   └── flashcard_provider.dart
│   │   │   └── widgets/
│   │   │       ├── flashcard_widget.dart
│   │   │       └── search_bar_widget.dart
│   │   ├── dictionary/
│   │   │   ├── screens/
│   │   │   │   └── dictionary_screen.dart
│   │   │   ├── providers/
│   │   │   │   └── dictionary_provider.dart
│   │   │   └── widgets/
│   │   │       ├── entry_card.dart
│   │   │       └── add_entry_modal.dart
│   │   ├── quiz/
│   │   │   ├── screens/
│   │   │   │   ├── quiz_setup_screen.dart
│   │   │   │   ├── quiz_play_screen.dart
│   │   │   │   └── quiz_results_screen.dart
│   │   │   └── providers/
│   │   │       └── quiz_provider.dart
│   │   └── profile/
│   │       ├── screens/
│   │       │   └── profile_screen.dart
│   │       └── providers/
│   │           └── profile_provider.dart
│   ├── models/
│   │   ├── dictionary_entry.dart     # Freezed data class
│   │   ├── flashcard_progress.dart
│   │   ├── quiz_result.dart
│   │   └── profile.dart
│   └── widgets/
│       ├── glass_card.dart          # Reusable glassmorphism card
│       ├── ruby_text.dart           # Pinyin-above-characters widget
│       ├── shimmer_loader.dart      # Skeleton loading widget
│       ├── app_toast.dart           # Toast/snackbar system
│       └── adaptive_nav.dart        # Bottom tab (mobile) / top bar (desktop)
├── supabase/
│   ├── functions/
│   │   └── translate/
│   │       └── index.ts             # OpenAI translate edge function
│   ├── migrations/
│   │   └── 001_initial_schema.sql
│   └── config.toml
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 2) Supabase Setup

### Authentication
- Enable **Email/Password** sign-up in Supabase Auth dashboard.
- Optionally enable Google OAuth.
- Flutter uses `supabase_flutter` for session management (`Supabase.instance.client.auth`).
- Auth state is exposed via a Riverpod `StreamProvider` that listens to `onAuthStateChange`.
- `GoRouter` redirect guard checks auth state — unauthenticated users are sent to `/login`.

### Database Schema

**profiles**
```sql
id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
display_name text,
avatar_url text,
created_at timestamptz DEFAULT now()
```

**dictionary_entries**
```sql
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
user_id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
english text NOT NULL,
chinese text NOT NULL,
pinyin text,
meaning text,
notes text,
examples jsonb DEFAULT '[]',   -- array of { zh, pinyin, en }
tags text[] DEFAULT '{}',
is_mastered boolean DEFAULT false,
created_at timestamptz DEFAULT now(),
updated_at timestamptz DEFAULT now()
```
Indexes: GIN trigram on english, chinese, pinyin, meaning. Index on (user_id, created_at DESC).

**flashcard_progress**
```sql
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
user_id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
entry_id uuid NOT NULL REFERENCES dictionary_entries ON DELETE CASCADE,
ease float DEFAULT 2.5,
interval_days int DEFAULT 0,
repetitions int DEFAULT 0,
next_review_at timestamptz DEFAULT now(),
last_reviewed_at timestamptz,
UNIQUE(user_id, entry_id)
```

**quiz_results**
```sql
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
user_id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
quiz_type text NOT NULL,            -- 'multiple_choice' | 'fill_blank' | 'pinyin_match' | 'mixed'
total_questions int NOT NULL,
correct_answers int NOT NULL,
score_percent float NOT NULL,
entries_tested uuid[] NOT NULL,     -- array of dictionary_entry IDs tested
details jsonb DEFAULT '[]',         -- per-question breakdown
completed_at timestamptz DEFAULT now()
```
Index on (user_id, completed_at DESC).

### RLS Policies
Enable RLS on all tables. Policy: users can only read/write their own rows where `user_id = auth.uid()`.

---

## 3) Visual Design System — Instagram + Apple Glass Aesthetic

### Design Philosophy
The UI should feel like a premium native app. Think **Instagram's clean layout and navigation** combined with **Apple's glassmorphism, depth, and translucency**. Every surface should feel layered and tactile.

### Color Palette

**Dark mode (DEFAULT — app opens in dark mode):**
```dart
// app_colors.dart
static const background = Color(0xFF0A0A0F);
static const backgroundElevated = Color(0xFF12121A);
static const card = Color(0xFF151520);
static const cardBorder = Color(0xFF2A2A3A);
static const foreground = Color(0xFFEDEDED);
static const muted = Color(0xFF888888);
static const accent = Color(0xFF818CF8);
static const accentLight = Color(0xFFA5B4FC);
static const accentGlow = Color(0x33818CF8); // 20% opacity
static const danger = Color(0xFFF87171);
static const success = Color(0xFF4ADE80);
static const warning = Color(0xFFFBBF24);
```

**Light mode:**
```dart
static const backgroundLight = Color(0xFFF8F9FA);
static const backgroundElevatedLight = Color(0xFFFFFFFF);
static const cardLight = Color(0xFFFFFFFF);
static const cardBorderLight = Color(0xFFE5E7EB);
static const foregroundLight = Color(0xFF111827);
static const mutedLight = Color(0xFF6B7280);
static const accentLightMode = Color(0xFF6366F1);
static const accentLightLight = Color(0xFF818CF8);
static const accentGlowLight = Color(0x1F6366F1); // 12% opacity
static const dangerLight = Color(0xFFEF4444);
static const successLight = Color(0xFF22C55E);
static const warningLight = Color(0xFFF59E0B);
```

### Glassmorphism in Flutter

Use `ClipRRect` + `BackdropFilter` + semi-transparent `Container` for glass effects:

```dart
// glass_decoration.dart
class GlassDecoration {
  /// Standard glass card
  static BoxDecoration card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? const Color(0xFF151520).withValues(alpha: 0.6)
          : Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Elevated glass (modals, sheets)
  static BoxDecoration elevated(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? const Color(0xFF151520).withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.06),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
          blurRadius: 80,
          offset: const Offset(0, 24),
        ),
      ],
    );
  }
}
```

Wrap glass surfaces with `BackdropFilter`:
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
    child: Container(
      decoration: GlassDecoration.card(context),
      child: child,
    ),
  ),
)
```

### Key Visual Patterns

1. **Depth & Layers**: Use `BoxShadow` with multiple layers. Cards float above the background. Active elements have a subtle inner glow.

2. **Gradient Accent**: The app name "Hanly" uses `ShaderMask` with `LinearGradient(colors: [accent, accentLight])` on text.

3. **Border Radius**: Cards = 16, buttons = 12, pills/tags = 999 (StadiumBorder), inputs = 12.

4. **Press/Hover States**: Cards scale down slightly on press (`Transform.scale(scale: 0.98)`) with `AnimatedContainer`. On desktop, hover lifts with translateY(-2).

5. **Transitions**: Use `flutter_animate` for staggered entrance animations. Page transitions via `GoRouter` custom `TransitionPage`.

6. **Skeleton Loading**: `Shimmer` package for all loading states — never show spinners alone.

7. **Spacing**: Use 4px grid. Padding inside cards: 20. Gap between cards: 12-16. Page padding: 16 mobile, 24 desktop.

8. **Typography**:
   - Headings: `FontWeight.w600`, letter spacing -0.5
   - Chinese characters: 24-36sp, `FontWeight.w500`
   - Pinyin: 12sp, accent color, centered above characters
   - Labels: 10sp, uppercase, letter spacing 1.2, muted color
   - Body: 14-16sp, height 1.5

9. **Tag Pills**: `Container` with `StadiumBorder`, semi-transparent accent backgrounds (e.g., `Colors.pink.withValues(alpha: 0.15)`).

---

## 4) App Screens & Navigation

### Navigation — Adaptive: Bottom Tab Bar (Mobile) + Side Rail or Top Bar (Desktop)

Use `LayoutBuilder` or `MediaQuery` to switch layouts:

**Mobile (width < 640):** Fixed `BottomNavigationBar` with 4 items + labels. Glass background, safe area padding.
```
[ Home ]  [ Dictionary ]  [ Quiz ]  [ Profile ]
```

**Desktop (width >= 640):** `NavigationRail` on the left or a sticky top `AppBar` with glass background. Logo left, nav items center, theme toggle + avatar right.

**Active tab**: accent-colored icon + label, with an accent indicator (dot or bar).

### Screens & Routes (`GoRouter`)

| Route | Screen | Auth Required |
|-------|--------|--------------|
| `/login` | `LoginScreen` | No |
| `/` | `HomeScreen` (flashcard review) | Yes |
| `/dictionary` | `DictionaryScreen` | Yes |
| `/quiz` | `QuizSetupScreen` | Yes |
| `/quiz/play` | `QuizPlayScreen` | Yes |
| `/quiz/results` | `QuizResultsScreen` | Yes |
| `/profile` | `ProfileScreen` | Yes |

#### Login / Sign Up (`/login`)
- Full-screen glass card centered on a gradient background.
- Email + password `TextFormField`s. "Sign Up" and "Log In" toggle via `TabBar` or segmented control.
- App logo + tagline at top.
- After login, redirect to `/`.

#### Home — Flashcard Review (`/`)
This is the **main landing screen after login**. It shows flashcard review front-and-center.

**Layout (top to bottom):**
1. **Header area**: "X cards due today" counter + streak indicator.
2. **Flashcard**: A large centered glass card with `GestureDetector` for tap-to-reveal.
   - **Front**: Shows the **English** word/phrase. Large, centered text. Subtle "Tap to reveal" hint at bottom.
   - **Back** (after tap): Reveals **Chinese characters** (large, bold) with **pinyin above each character** using `RubyText` widget. Below that: meaning, notes, and first example sentence.
   - Flip animation using `AnimatedSwitcher` or a custom `AnimationController` with `Transform` (3D flip).
   - **Grade buttons** appear after reveal: `Again` / `Hard` / `Good` / `Easy` — styled as glass pills in a `Row`.
3. **Search Bar**: Below the flashcard. Glass-styled `TextField` with search icon. Debounced (300ms). Searches across all dictionary entries.
   - Results appear in an overlay (`OverlayEntry` or `ListView` below) as compact cards.
   - Each result shows: Chinese (bold) + pinyin + English + meaning preview.
   - Tapping a result opens a detail bottom sheet or navigates to dictionary.
4. **Empty state** (no due cards): Celebratory message + "Browse Dictionary" button + search bar still visible.

**Flashcard Behavior:**
- Query due cards: `next_review_at <= now()` for current user via Supabase query.
- Auto-create `flashcard_progress` rows when dictionary entries are saved (use a Supabase database trigger or insert in the same transaction).
- SM-2 scheduling (see algorithm spec below).
- After grading, show next card with `AnimatedSwitcher` slide/fade transition.

#### Dictionary (`/dictionary`)
Searchable, filterable list of all saved vocabulary.

- **Search bar** at top: filters across english/chinese/pinyin/meaning.
- **Filter chips**: All | Mastered | Unmastered (using `FilterChip` or `ChoiceChip`).
- **Sort**: Newest | Alphabetical (dropdown or toggle).
- **Entry cards** (glass cards in a `ListView.builder`):
  - Chinese characters (large, bold) with pinyin above (`RubyText`)
  - English + meaning (max 2 lines, `TextOverflow.ellipsis`)
  - Tags as colored pills
  - Actions: Edit (pencil icon), Delete (trash icon), Toggle mastered (checkmark icon)
- **Edit modal**: Glass elevated `showModalBottomSheet` with fields for pinyin, meaning, notes, tags, examples.
- **Add entry**: A `FloatingActionButton` (bottom-right, accent gradient, glass shadow) that opens a bottom sheet to add a new word.
- **Translate & Add**: Inside the add modal, a "Translate" button next to the English input. Calls the Supabase Edge Function `translate` and auto-fills Chinese, pinyin, meaning, notes, tags. User can review/edit before saving.

#### Quiz (`/quiz`)
Interactive quiz mode to test knowledge.

**Quiz Setup Screen (`/quiz`):**
- Glass card with options:
  - **Quiz type**: Multiple Choice | Fill in the Blank | Pinyin Match | Mixed — using `SegmentedButton` or `ChoiceChip`s
  - **Number of questions**: 5 / 10 / 15 / 20 — `Slider` or radio buttons
  - **Source**: All words | Unmastered only | Specific tags (multi-select chips)
  - **Direction**: EN -> ZH | ZH -> EN | Mixed
- "Start Quiz" button (accent gradient, glass shadow)

**Quiz Types:**

1. **Multiple Choice**: Show prompt, pick correct answer from 4 options. Wrong options randomly selected from other entries.
2. **Fill in the Blank**: Show English, user types Chinese (or pinyin). Fuzzy matching for pinyin (tone-insensitive).
3. **Pinyin Match**: Show Chinese characters, user types correct pinyin.
4. **Mixed**: Randomly alternates between the above.

**Quiz Flow (`/quiz/play`):**
- One question at a time, centered glass card.
- `LinearProgressIndicator` at top (accent gradient fill).
- After answering: show correct/incorrect with full entry details.
- Green glow for correct, shake animation (`flutter_animate`) for incorrect.
- "Next" button to proceed.

**Quiz Results Screen (`/quiz/results`):**
- Score: X/Y correct (large, centered)
- Percentage with `CircularProgressIndicator` (accent gradient)
- Breakdown list with correct/incorrect indicators
- "Review Mistakes" button
- "Save Results" button: persists to `quiz_results` table
- "Try Again" or "Back to Home" buttons

#### Profile (`/profile`)
- User info: email, display name (editable), avatar
- **Stats dashboard** (glass cards in a grid):
  - Total words saved
  - Words mastered
  - Current review streak (days)
  - Quiz accuracy (average)
  - Flashcards reviewed today
- **Recent quiz history**: `ListView` of last 10 quizzes with date, type, score
- **Settings**:
  - Theme toggle (dark/light) — persisted via `shared_preferences`
  - Default quiz settings
  - Export dictionary to JSON/CSV (use `share_plus` or `file_saver`)
- **Sign Out** button

---

## 5) Supabase Edge Functions & Data Access

### Edge Function: `translate`

Deployed at `/supabase/functions/translate/index.ts`. Invoked from Flutter via:
```dart
final response = await Supabase.instance.client.functions.invoke(
  'translate',
  body: {'text': inputText},
);
```

**Implementation (Deno/TypeScript):**
```typescript
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";
import OpenAI from "https://esm.sh/openai";

serve(async (req) => {
  // Verify auth
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
  );
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return new Response("Unauthorized", { status: 401 });

  const { text } = await req.json();
  // Validate: 1-1000 chars, non-empty

  const openai = new OpenAI({ apiKey: Deno.env.get("OPENAI_API_KEY") });
  // Call gpt-4o-mini with response_format: { type: "json_object" }
  // Return: { english, chinese, pinyin, meaning, notes, examples, tags_suggested, segments }
});
```

**Response shape:**
```json
{
  "english": "decouple",
  "chinese": "解耦",
  "pinyin": "jiě ǒu",
  "meaning": "to separate or disengage components in a system",
  "notes": "Common in software architecture.",
  "examples": [
    { "zh": "我们需要解耦系统中的各个模块。", "pinyin": "...", "en": "We need to decouple the modules." }
  ],
  "tags_suggested": ["tech"],
  "segments": [
    { "char": "解", "py": "jiě" },
    { "char": "耦", "py": "ǒu" }
  ]
}
```

**OpenAI prompt rules:**
- Use `gpt-4o-mini` (cost-optimized), `response_format: { type: "json_object" }`.
- Prefer natural, conversational Chinese.
- Always generate pinyin with tone marks.
- Include `segments` array: one object per character with its pinyin syllable.

### Direct Supabase Queries (from Flutter)

All other data operations use the Supabase client directly from Flutter — no edge functions needed:

```dart
final supabase = Supabase.instance.client;

// Fetch dictionary entries
final entries = await supabase
    .from('dictionary_entries')
    .select()
    .eq('user_id', userId)
    .order('created_at', ascending: false);

// Insert dictionary entry + flashcard progress (transaction)
await supabase.from('dictionary_entries').insert({...}).select().single();
await supabase.from('flashcard_progress').insert({...});

// Fetch due flashcards
final due = await supabase
    .from('flashcard_progress')
    .select('*, dictionary_entries(*)')
    .eq('user_id', userId)
    .lte('next_review_at', DateTime.now().toIso8601String());

// Grade flashcard
await supabase.from('flashcard_progress').update({...}).eq('id', progressId);

// Save quiz results
await supabase.from('quiz_results').insert({...});

// Fetch quiz history
final history = await supabase
    .from('quiz_results')
    .select()
    .eq('user_id', userId)
    .order('completed_at', ascending: false)
    .limit(10);

// Profile stats (use Supabase RPC or multiple queries)
final totalWords = await supabase.from('dictionary_entries').select('id').eq('user_id', userId).count();
```

**Quiz question generation** happens entirely client-side: fetch the user's dictionary entries, then randomly build questions with correct/wrong options from the pool. No edge function needed.

---

## 6) Key Widget Specifications

### RubyText (Pinyin above Characters)
Renders Chinese text with pinyin perfectly aligned above each character.

**Input**: `List<Segment>` where `Segment = { char: String, py: String }`

**Rendering**: `Row` of `Column` widgets:
```dart
class RubyText extends StatelessWidget {
  final List<Segment> segments;
  final double charSize;
  final double pinyinSize;
  final Color? pinyinColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      children: segments.map((seg) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (seg.py.isNotEmpty)
            Text(seg.py, style: TextStyle(
              fontSize: pinyinSize ?? 10,
              color: pinyinColor ?? AppColors.accent,
            )),
          const SizedBox(height: 2),
          Text(seg.char, style: TextStyle(
            fontSize: charSize ?? 28,
            fontWeight: FontWeight.w500,
          )),
        ],
      )).toList(),
    );
  }
}
```

### GlassCard Widget
Reusable card with glassmorphism. Props: `variant` (default / elevated), `child`, `padding`, `borderRadius`.

Uses `ClipRRect` + `BackdropFilter` + `Container` with `GlassDecoration`.

### Toast System
Use `ScaffoldMessenger` with custom `SnackBar` styling (glass background, rounded corners). Types: success, error, info. Auto-dismiss 3s.

### Shimmer Loader
Use the `shimmer` package. Matches the shape of the content it replaces (`Container` with matching border radius).

### AdaptiveNav (Adaptive Navigation Shell)
A `ShellRoute` widget that wraps all authenticated screens:
- `< 640px` width: `Scaffold` with `BottomNavigationBar` (glass background)
- `>= 640px` width: `Scaffold` with `NavigationRail` or top `AppBar`
- Uses `GoRouter`'s `StatefulShellRoute` for preserving tab state.

---

## 7) SM-2 Spaced Repetition Algorithm

```dart
// sm2.dart
enum Grade { again, hard, good, easy }

class SM2Result {
  final double ease;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReviewAt;
  final DateTime lastReviewedAt;
  SM2Result({required this.ease, required this.intervalDays, required this.repetitions, required this.nextReviewAt, required this.lastReviewedAt});
}

SM2Result calculateNext({
  required double ease,
  required int intervalDays,
  required int repetitions,
  required Grade grade,
}) {
  final now = DateTime.now();

  switch (grade) {
    case Grade.again:
      intervalDays = 0;
      repetitions = 0;
      ease = (ease - 0.2).clamp(1.3, 3.0);
      // next_review_at = now + 10 minutes
      return SM2Result(
        ease: ease, intervalDays: 0, repetitions: 0,
        nextReviewAt: now.add(const Duration(minutes: 10)),
        lastReviewedAt: now,
      );
    case Grade.hard:
      intervalDays = intervalDays.clamp(1, 999999);
      ease = (ease - 0.15).clamp(1.3, 3.0);
      break;
    case Grade.good:
      intervalDays = intervalDays == 0 ? 1 : (intervalDays * ease).round();
      repetitions += 1;
      break;
    case Grade.easy:
      intervalDays = (intervalDays * ease * 1.3).round().clamp(1, 999999);
      ease = (ease + 0.1).clamp(1.3, 3.0);
      repetitions += 1;
      break;
  }

  return SM2Result(
    ease: ease,
    intervalDays: intervalDays,
    repetitions: repetitions,
    nextReviewAt: now.add(Duration(days: intervalDays)),
    lastReviewedAt: now,
  );
}
```

---

## 8) Environment & Configuration

### Flutter App — Environment Variables
Use `--dart-define` or a `.env` file with `flutter_dotenv`:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

Initialize in `main.dart`:
```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

### Supabase Edge Functions — Secrets
Set via Supabase CLI:
```bash
supabase secrets set OPENAI_API_KEY=sk-...
```

The Edge Function accesses it via `Deno.env.get("OPENAI_API_KEY")`.

---

## 9) Development Commands

### Flutter App
```bash
# Install dependencies
flutter pub get

# Run (debug, all platforms)
flutter run                    # Default device
flutter run -d chrome          # Web
flutter run -d macos           # macOS
flutter run -d ios             # iOS simulator

# Build
flutter build apk              # Android
flutter build ios               # iOS
flutter build web               # Web
flutter build macos             # macOS
flutter build windows           # Windows

# Code generation (Riverpod, Freezed)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for codegen
dart run build_runner watch --delete-conflicting-outputs
```

### Supabase
```bash
# Start local Supabase (Docker required)
supabase start

# Deploy edge function
supabase functions deploy translate

# Run migrations
supabase db push

# Generate TypeScript types (for edge functions)
supabase gen types typescript --local > supabase/functions/_shared/types.ts
```

---

## 10) pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^14.0.0
  supabase_flutter: ^2.5.0
  google_fonts: ^6.2.0
  lucide_icons: ^0.257.0
  flutter_animate: ^4.5.0
  shimmer: ^3.0.0
  shared_preferences: ^2.2.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  share_plus: ^9.0.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  flutter_lints: ^4.0.0
```

---

## 11) Error-Handling & Self-Fix Loop

When you encounter errors:
1. Re-run the failing command.
2. Read the full stack trace/log.
3. Identify root cause (wrong import, missing dependency, RLS denied, platform config, etc.).
4. Patch code/config.
5. Re-run until fixed.
6. Summarize what changed and why.

Common issues to anticipate:
- Supabase RLS blocking inserts/reads -> verify policies match `auth.uid()`.
- `BackdropFilter` performance on web -> consider disabling blur on web or using lower sigma.
- Missing platform-specific setup (iOS `Info.plist`, Android `AndroidManifest.xml`, macOS entitlements for network access).
- Code generation not running -> `dart run build_runner build`.
- `supabase_flutter` initialization must happen before `runApp()`.
- Edge Function CORS -> Supabase handles this automatically for `functions.invoke()` calls.
- Google Fonts requires network on first load -> bundle font files in `assets/` for offline support.

---

## 12) Acceptance Criteria

- [ ] OpenAI key never appears in the Flutter app bundle — only in Supabase Edge Function secrets
- [ ] Supabase Auth login/signup works (email/password)
- [ ] All screens are protected — unauthenticated users redirected to `/login`
- [ ] Home screen shows due flashcards immediately after login
- [ ] Search bar below flashcard works and returns results from dictionary
- [ ] Flashcard grading updates SM-2 scheduling correctly
- [ ] Dictionary is searchable, editable, and entries can be added (with translate auto-fill via Edge Function)
- [ ] Quiz generates questions from saved vocabulary (client-side)
- [ ] Quiz supports multiple choice, fill-in-blank, and pinyin match
- [ ] Quiz results are saved and viewable in profile
- [ ] Glassmorphism applied to all cards, nav bar, modals (`BackdropFilter` + semi-transparent surfaces)
- [ ] Dark mode is default and looks intentional
- [ ] Light mode works and maintains glass aesthetic
- [ ] Bottom tab bar on mobile, navigation rail or top bar on desktop
- [ ] App runs on iOS, Android, Web, macOS, and Windows
- [ ] Riverpod providers manage all state; no raw `setState` for data logic
- [ ] `GoRouter` handles all navigation with auth redirect guard

---

Build it now.
