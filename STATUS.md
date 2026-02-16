# Hanly — Project Status

> Last updated: 2026-02-16

## Project Structure

```
Hanly/
├── lib/                    Flutter app code
│   ├── main.dart           App entry, Supabase init, dotenv
│   ├── app.dart            MaterialApp.router, theme, GoRouter
│   ├── core/
│   │   ├── theme/          Dark + light themes, glassmorphism
│   │   ├── router/         GoRouter with auth guard
│   │   ├── providers/      Supabase client + auth stream
│   │   └── utils/          SM-2 algorithm
│   ├── features/
│   │   ├── auth/           Login/signup screen + provider
│   │   └── home/           Flashcard review + translate
│   ├── models/             Data classes (manual serialization)
│   └── widgets/            GlassCard, RubyText, Shimmer, Toast
├── supabase/
│   ├── config.toml         Local dev config
│   ├── migrations/         Database schema (4 tables + RLS)
│   └── functions/          Edge functions (translate)
├── .env                    All secrets (gitignored)
├── pubspec.yaml            Dependencies
└── CLAUDE.md               Full build spec
```

---

## What's Working

### Supabase Backend — 100%
| Component | File | Status |
|-----------|------|--------|
| Config | `supabase/config.toml` | Fully configured (auth, db, edge runtime) |
| Database schema | `supabase/migrations/001_initial_schema.sql` | All 4 tables, RLS policies, indexes, auto-profile trigger |
| Translate function | `supabase/functions/translate/index.ts` | Complete — auth, validation, OpenAI gpt-4o-mini, CORS |
| Environment | `.env` | Single file with `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `OPENAI_API_KEY` |

### Flutter Core — 100%
| Component | File | Status |
|-----------|------|--------|
| App entry | `lib/main.dart` | Loads .env, initializes Supabase, ProviderScope |
| App shell | `lib/app.dart` | MaterialApp.router, dark theme default |
| Colors | `lib/core/theme/app_colors.dart` | Full dark + light palettes |
| Theme | `lib/core/theme/app_theme.dart` | Material 3, Inter font, input/button styling |
| Glassmorphism | `lib/core/theme/glass_decoration.dart` | `card()` and `elevated()` BoxDecoration helpers |
| Router | `lib/core/router/app_router.dart` | Auth redirect guard, `onAuthStateChange` listener |
| Supabase provider | `lib/core/providers/supabase_provider.dart` | Client, auth stream, current user providers |
| SM-2 algorithm | `lib/core/utils/sm2.dart` | Complete spaced repetition calculation |

### Auth Feature — 100%
| Component | File | Status |
|-----------|------|--------|
| Auth provider | `lib/features/auth/providers/auth_provider.dart` | Login/signup, error handling, loading state |
| Login screen | `lib/features/auth/screens/login_screen.dart` | Tab toggle, email/password fields, validation, animations |

### Home / Flashcard Feature — 100%
| Component | File | Status |
|-----------|------|--------|
| Home screen | `lib/features/home/screens/home_screen.dart` | Flashcard review + translate input layout |
| Flashcard provider | `lib/features/home/providers/flashcard_provider.dart` | Loads due cards, grades with SM-2, updates Supabase |
| Translate provider | `lib/features/home/providers/translate_provider.dart` | Calls edge function, saves to dictionary + progress |
| Flashcard widget | `lib/features/home/widgets/flashcard_widget.dart` | Flip animation, English front / Chinese+pinyin back |
| Grade buttons | `lib/features/home/widgets/grade_buttons.dart` | Again / Hard / Good / Easy with color coding |
| Empty state | `lib/features/home/widgets/flashcard_empty_state.dart` | "All caught up!" celebration |
| Translate input | `lib/features/home/widgets/translate_input.dart` | Glass-styled input + send button |
| Translation result | `lib/features/home/widgets/translation_result_card.dart` | Pinyin, Chinese, meaning, examples, tags, save button |

### Models — 100%
| Model | File | Status |
|-------|------|--------|
| DictionaryEntry | `lib/models/dictionary_entry.dart` | All fields, fromJson, toInsertJson |
| FlashcardProgress | `lib/models/flashcard_progress.dart` | SM-2 fields, FlashcardWithEntry composite |
| TranslationResult | `lib/models/translation_result.dart` | Matches edge function response shape |
| Segment | `lib/models/segment.dart` | char + pinyin for ruby text |
| ExampleSentence | `lib/models/example_sentence.dart` | zh, pinyin, en |

### Shared Widgets — 100%
| Widget | File | Status |
|--------|------|--------|
| GlassCard | `lib/widgets/glass_card.dart` | BackdropFilter + GlassDecoration, standard/elevated variants |
| RubyText | `lib/widgets/ruby_text.dart` | Pinyin aligned above each Chinese character |
| ShimmerLoader | `lib/widgets/shimmer_loader.dart` | Shimmer animation, dark/light aware |
| AppToast | `lib/widgets/app_toast.dart` | Success/error/info snackbars |

### Platforms — Present
- Android, iOS, macOS, Web, Windows — all have standard Flutter config files

---

## What's NOT Working / Not Built

### Missing Screens — 0% done
| Screen | Route | Status |
|--------|-------|--------|
| Dictionary | `/dictionary` | **Not started** — no files in `lib/features/dictionary/` |
| Quiz Setup | `/quiz` | **Not started** — no files in `lib/features/quiz/` |
| Quiz Play | `/quiz/play` | **Not started** |
| Quiz Results | `/quiz/results` | **Not started** |
| Profile | `/profile` | **Not started** — no files in `lib/features/profile/` |

### Missing Navigation — 0% done
| Component | Status |
|-----------|--------|
| Adaptive nav shell (`AdaptiveNav`) | **Not started** — no bottom tab bar or navigation rail |
| `StatefulShellRoute` for tab state | **Not started** |
| GoRouter routes for missing screens | **Not started** — only `/login` and `/` exist |
| Responsive layout (mobile vs desktop) | **Not started** |

### Missing Features
| Feature | Status |
|---------|--------|
| Theme toggle (dark/light) | **Not started** — hardcoded to dark mode |
| Theme persistence via `shared_preferences` | **Not started** |
| Home screen search bar | **Not started** — spec says search bar below flashcard |
| Dictionary search/filter/sort | **Not started** |
| Dictionary entry editing | **Not started** |
| Dictionary add entry with translate auto-fill | **Not started** |
| Quiz gameplay (multiple choice, fill-blank, pinyin match) | **Not started** |
| Quiz results saving | **Not started** |
| Profile stats dashboard | **Not started** |
| Quiz history display | **Not started** |
| Export dictionary to JSON/CSV | **Not started** |

### Code Generation
- `build_runner` not yet run — models use manual factories instead of `@freezed` annotations
- No `.g.dart` or `.freezed.dart` files exist

### Testing
- Only a placeholder test (`1 + 1 = 2`) exists in `test/widget_test.dart`

---

## Setup Requirements

### To run the app locally
```bash
# 1. Install dependencies
flutter pub get

# 2. Ensure .env exists at repo root with:
#    SUPABASE_URL=...
#    SUPABASE_ANON_KEY=...
#    OPENAI_API_KEY=...

# 3. Run on any platform
flutter run -d chrome     # Web
flutter run -d macos      # macOS
flutter run -d ios        # iOS simulator
```

### To deploy Supabase
```bash
# 1. Link to Supabase project
supabase link --project-ref <your-ref>

# 2. Push database schema
supabase db push

# 3. Set edge function secrets
supabase secrets set OPENAI_API_KEY=sk-...

# 4. Deploy edge function
supabase functions deploy translate
```

---

## Recommended Build Order

1. **Adaptive navigation shell** + all GoRouter routes (unblocks all other screens)
2. **Dictionary screen** — search, filter, CRUD, translate auto-fill
3. **Quiz screens** — setup, gameplay, results (depends on dictionary entries)
4. **Profile screen** — stats, quiz history, settings, sign out
5. **Polish** — theme toggle, home search bar, code generation, tests
