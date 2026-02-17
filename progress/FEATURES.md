# Hanly — Feature Specification & Data Requirements

> **Purpose:** Detailed feature breakdown with data modelling requirements to facilitate database schema planning.
> **Last updated:** 2026-02-16

---

## Table of Contents

1. [User Profile & Onboarding](#1-user-profile--onboarding)
2. [Word Bank (Core)](#2-word-bank-core)
3. [Flashcard Learning (Spaced Repetition)](#3-flashcard-learning-spaced-repetition)
4. [Quiz Mode](#4-quiz-mode)
5. [Dictionary Page](#5-dictionary-page)
6. [Settings / Profile Page](#6-settings--profile-page)
7. [Progress Dashboard](#7-progress-dashboard)
8. [Global Word Bank & Popularity](#8-global-word-bank--popularity)
9. [Word Recommendations](#9-word-recommendations)
10. [Similar User Recommendations](#10-similar-user-recommendations)
11. [Onboarding Word Suggestions](#11-onboarding-word-suggestions)
12. [Future Features](#12-future-features)
13. [Consolidated Data Model Summary](#13-consolidated-data-model-summary)

---

## 1. User Profile & Onboarding

### Feature Description

New users go through a multi-step onboarding flow after signing up. This collects learning context that personalises the entire app experience — the translation engine uses it to return the most relevant words, flashcard difficulty is calibrated to level, and recommendations are matched against similar profiles.

Returning users skip onboarding and go straight to the home page.

### Onboarding Flow

1. **Chinese Level** — Self-assessed proficiency level.
   - Options: `absolute_beginner` | `beginner` | `elementary` | `intermediate` | `upper_intermediate` | `advanced`
   - Stored as an enum string.

2. **Learning Purpose** — Why are you learning Chinese? (multi-select)
   - Options: `school` | `work` | `career_advancement` | `travel` | `relocation` | `heritage` | `hobby` | `exam_prep` | `general`
   - Stored as a text array.

3. **Industry** — Relevant only if purpose includes `work` or `career_advancement`. (single-select, optional)
   - Options: `technology` | `finance` | `healthcare` | `legal` | `education` | `marketing` | `hospitality` | `manufacturing` | `real_estate` | `media` | `government` | `retail` | `other`
   - Stored as a nullable string.

4. **Additional Context** — Free-text input where the user can describe anything else ("I'm preparing for HSK 4", "I work at a Chinese tech company", etc.)
   - Stored as nullable text, max 500 characters.

5. After submission, the backend (or an LLM call) generates:
   - A **context summary** — one concise sentence summarising the user's profile for LLM prompt injection (e.g., "Intermediate learner studying business Chinese in the finance industry, preparing for HSK 4").
   - **Context tags** — a derived tag array combining level, purposes, and industry into a flat searchable list (e.g., `["intermediate", "work", "finance", "hsk4"]`).

### Data Requirements

**Table: `profiles`**

| Field | Type | Nullable | Default | Notes |
|-------|------|----------|---------|-------|
| `id` | uuid (PK) | no | — | References `auth.users`. Created on signup. |
| `display_name` | text | yes | null | Set during onboarding or editable later. |
| `avatar_url` | text | yes | null | Profile picture URL (future: upload to Supabase Storage). |
| `chinese_level` | text | yes | null | Enum string. Null = onboarding not completed. |
| `learning_purposes` | text[] | yes | `'{}'` | Multi-select array. |
| `industry` | text | yes | null | Single-select, only if work-related purpose. |
| `additional_context` | text | yes | null | Free-text, max 500 chars. |
| `context_summary` | text | yes | null | LLM-generated one-liner for prompt injection. |
| `context_tags` | text[] | yes | `'{}'` | Derived flat tag array for querying/matching. |
| `onboarding_completed` | boolean | no | `false` | Gate for redirect logic. |
| `daily_word_goal` | int | yes | `20` | Configurable: how many flashcards per day. |
| `created_at` | timestamptz | no | `now()` | Account creation time. |
| `updated_at` | timestamptz | no | `now()` | Last profile edit. |

**Considerations:**
- `onboarding_completed` is the routing gate — if `false`, redirect to onboarding after login instead of home.
- `context_summary` is regenerated whenever the user edits their profile (purposes, level, industry, or additional context change).
- `context_tags` enables efficient filtering for the similar-user recommendation system (can use GIN index on the array).
- The `chinese_level` field doubles as a difficulty calibration signal: the flashcard system can adjust initial card difficulty based on it.

---

## 2. Word Bank (Core)

### Feature Description

The word bank is the user's personal vocabulary collection. Users add words by typing in English, pinyin, or Chinese characters. An LLM function translates and enriches the input using the user's profile context (level, industry, purposes) to return the most relevant result.

Example: User with business context types "ye wu" → returns "业务" (business operations) rather than other possible matches. A casual learner typing the same might get a different prioritisation.

Each word bank entry contains the full linguistic data: the word itself, pinyin with tone marks, English meaning, example sentences (with pinyin for the example), usage notes, and category/tags.

### Add Word Flow

1. User types input (English, pinyin, or Chinese characters) into the search/add bar.
2. App **always** calls the LLM edge function with: `{ input, input_type, user_context_summary, user_context_tags, existing_word_ids[] }`.
3. LLM returns a **personalized** result: meaning, notes, and examples tailored to the user's context. The LLM always generates fresh — it does not check the global bank first.
4. User reviews the result card and taps "Add to Word Bank" (or edits before saving).
5. On save:
   - Insert into `user_words` (the user's personal copy, with personalized meaning/notes/examples).
   - Check `global_words` for existing match by `UNIQUE(chinese, pinyin)`:
     - If match → link `user_words.global_word_id`, increment `add_count`, merge new categories.
     - If no match → create new `global_words` entry with neutral data (combined meaning, segments, aggregated categories — no examples).
   - Auto-create a `review_cards` row for this word with initial FSRS state.

**Key principle:** Examples and notes are **always personalized per user** and stored only in `user_words`. The `global_words` table never stores examples — see [Section 8](#8-global-word-bank--popularity).

### Data Requirements

**Table: `user_words`** (the user's personal word bank)

| Field | Type | Nullable | Default | Notes |
|-------|------|----------|---------|-------|
| `id` | uuid (PK) | no | `gen_random_uuid()` | |
| `user_id` | uuid (FK → auth.users) | no | — | Owner. |
| `global_word_id` | uuid (FK → global_words) | yes | null | Link to canonical entry if one exists. Null for purely custom entries. |
| `english` | text | no | — | English word or phrase. |
| `chinese` | text | no | — | Chinese characters. |
| `pinyin` | text | no | — | Pinyin with tone marks (e.g., "jiě ǒu"). |
| `meaning` | text | yes | null | Expanded definition / contextual meaning. |
| `notes` | text | yes | null | User or LLM-generated usage notes. |
| `examples` | jsonb | no | `'[]'` | Array of `{ zh, pinyin, en }` example sentences. |
| `segments` | jsonb | no | `'[]'` | Array of `{ char, pinyin }` — one per character, for ruby text rendering. |
| `categories` | text[] | no | `'{}'` | User-assigned or LLM-suggested categories (e.g., `["business", "formal"]`). |
| `source` | text | no | `'manual'` | How the word was added: `manual` | `onboarding` | `recommendation` | `random_word` | `camera` | `pdf` | `voice`. |
| `is_archived` | boolean | no | `false` | Soft-archive instead of delete, so progress data isn't lost. |
| `created_at` | timestamptz | no | `now()` | When the word was added. |
| `updated_at` | timestamptz | no | `now()` | Last edit. |

**Indexes:**
- `(user_id, created_at DESC)` — word bank feed ordering.
- `(user_id, is_archived)` — filter out archived words.
- GIN index on `categories` — for category filtering.
- GIN trigram on `english`, `chinese`, `pinyin` — for search-as-you-type.
- `(user_id, global_word_id)` UNIQUE (where `global_word_id IS NOT NULL`) — prevent duplicate canonical words per user.

**Considerations:**
- `segments` is critical for the `RubyText` widget — pinyin must align per-character. This is generated by the LLM during translation.
- `categories` replaces the previous "tags" concept with a more structured purpose. Categories are a mix of LLM-suggested and user-chosen values.
- `source` tracks acquisition channel for analytics ("What % of words came from recommendations vs manual input?").
- `is_archived` is preferred over hard delete because the word may have flashcard progress, quiz history, and global word references. Archiving removes it from active views while preserving data integrity.
- The `global_word_id` foreign key connects personal entries to the shared dictionary, enabling popularity tracking and deduplication.

---

## 3. Flashcard Learning (Spaced Repetition)

### Feature Description

The flashcard system is the primary learning mechanism. It uses the **FSRS (Free Spaced Repetition Scheduler)** algorithm — the modern successor to SM-2 — which uses a three-component memory model (Difficulty, Stability, Retrievability) to predict the optimal review time for each card. FSRS achieves ~20-30% fewer reviews than SM-2 for the same retention level.

**Why FSRS over SM-2:**
- SM-2 (1987) uses fixed formulas with a single "ease" factor. It treats every user the same.
- FSRS (2023) models memory with three variables and a power-law forgetting curve, producing more accurate scheduling. Its parameters can be optimised per-user over time.
- FSRS is now the default in Anki (since v23.10) and is open-source.

### FSRS Memory Model

Each card tracks three state variables:

1. **Stability (S)**: The number of days for retrievability to drop from 100% to 90%. Higher = stronger memory.
2. **Difficulty (D)**: How inherently hard the card is, range [1, 10]. Lower = easier.
3. **Retrievability (R)**: The current probability the user can recall the card, calculated as: `R(t, S) = (1 + t / (9 * S)) ^ -1` where `t` = days since last review.

### Grade Options (4 buttons)

| Grade | Value | Meaning | Effect |
|-------|-------|---------|--------|
| Again | 1 | Forgot / couldn't recall | Stability drops significantly (lapse formula). Card rescheduled very soon. |
| Hard | 2 | Recalled but with difficulty | Stability increases slightly, less than Good. Difficulty increases. |
| Good | 3 | Normal recall | Standard stability increase. Difficulty unchanged. |
| Easy | 4 | Effortless recall | Large stability increase. Difficulty decreases. |

### Daily Review Deck

- Each day, the user has a **review deck** = all cards where `next_review_at <= now()`.
- The app shows the count on the home screen: "X cards to review today".
- Users can configure their daily review goal (default: 20 cards/day from profile settings).
- If due cards exceed the daily goal, they are prioritised by: overdue cards first (sorted by how overdue), then by lowest stability (weakest memories first).
- New words added today also appear in the review deck immediately (initial review).

### Streak System

- A **streak** increments by 1 when the user completes their full daily review deck (all due cards reviewed, not just the daily goal cap).
- Streak resets to 0 if a day is missed (no reviews completed on a calendar day in the user's timezone).
- Streaks are stored per-user with a history for analytics.

### Data Requirements

**Table: `review_cards`** (FSRS state per word per user)

| Field | Type | Nullable | Default | Notes |
|-------|------|----------|---------|-------|
| `id` | uuid (PK) | no | `gen_random_uuid()` | |
| `user_id` | uuid (FK → auth.users) | no | — | |
| `word_id` | uuid (FK → user_words) | no | — | The word this card tracks. |
| `stability` | float | no | `0.0` | FSRS S — days until R drops to 90%. 0 = never reviewed. |
| `difficulty` | float | no | `5.0` | FSRS D — range [1, 10]. 5 = neutral starting point. |
| `reps` | int | no | `0` | Total number of successful reviews (non-lapse). |
| `lapses` | int | no | `0` | Number of times the user forgot (graded "Again"). |
| `state` | text | no | `'new'` | Card state: `new` | `learning` | `review` | `relearning`. |
| `last_grade` | int | yes | null | Last grade given: 1-4. |
| `next_review_at` | timestamptz | no | `now()` | When the card is next due. |
| `last_reviewed_at` | timestamptz | yes | null | Timestamp of last review. |
| `created_at` | timestamptz | no | `now()` | When the card was created. |

**Unique constraint:** `(user_id, word_id)` — one card per word per user.

**Indexes:**
- `(user_id, next_review_at)` — the primary query: fetch due cards for a user.
- `(user_id, state)` — filter by card state for analytics.

**Table: `review_logs`** (every individual review event — for FSRS parameter optimisation and analytics)

| Field | Type | Nullable | Default | Notes |
|-------|------|----------|---------|-------|
| `id` | uuid (PK) | no | `gen_random_uuid()` | |
| `user_id` | uuid (FK → auth.users) | no | — | |
| `card_id` | uuid (FK → review_cards) | no | — | |
| `word_id` | uuid (FK → user_words) | no | — | Denormalised for query efficiency. |
| `grade` | int | no | — | 1 (Again), 2 (Hard), 3 (Good), 4 (Easy). |
| `stability_before` | float | no | — | S before this review. |
| `stability_after` | float | no | — | S after this review. |
| `difficulty_before` | float | no | — | D before this review. |
| `difficulty_after` | float | no | — | D after this review. |
| `retrievability` | float | no | — | R at the moment of review (how likely they were to remember). |
| `interval_days` | float | no | — | Scheduled interval until next review (in days). |
| `duration_ms` | int | yes | null | How long the user spent on this card (time from card shown to grade button tap). |
| `reviewed_at` | timestamptz | no | `now()` | When the review happened. |

**Indexes:**
- `(user_id, reviewed_at DESC)` — for review history / progress dashboard.
- `(card_id, reviewed_at DESC)` — for per-card review history.

**Table: `streaks`**

| Field | Type | Nullable | Default | Notes |
|-------|------|----------|---------|-------|
| `id` | uuid (PK) | no | `gen_random_uuid()` | |
| `user_id` | uuid (FK → auth.users) | no | — | |
| `current_streak` | int | no | `0` | Current consecutive days. |
| `longest_streak` | int | no | `0` | All-time longest. |
| `last_completed_date` | date | yes | null | The last calendar date (user timezone) the user completed their deck. |
| `total_days_studied` | int | no | `0` | Lifetime count of days with at least one review. |
| `updated_at` | timestamptz | no | `now()` | |

**Unique constraint:** `(user_id)` — one streak record per user.

**Considerations:**
- `review_logs` is an append-only table — never updated, only inserted. This is critical for future FSRS parameter optimisation (training the model on the user's review history to personalise the 17 FSRS weights).
- `duration_ms` on review logs enables "time spent learning" analytics on the progress dashboard.
- `state` on `review_cards` follows Anki's model: `new` (never reviewed), `learning` (in initial learning steps), `review` (graduated to regular reviews), `relearning` (lapsed and re-learning).
- The streak system uses `last_completed_date` (a date, not timestamp) to handle timezone-correct day boundaries. The app sends the user's local date when completing a deck.
- `review_cards` is auto-created when a word is added to `user_words`. This can be a database trigger or application-level logic.

### Category Filtering for Flashcards

Users can filter their review deck by categories before starting a review session. This allows focused study on specific vocabulary groups (e.g., "business only", "food only").

**UI:**
- Filter chips displayed above the flashcard area on the home screen.
- Chips are pulled from the distinct `user_words.categories` values for the current user.
- Default: "All" (no filter applied).
- Selecting a category filters the due cards query to only include words with that category.
- Filter is in-memory only — resets on app restart.

**Query modification:**
- When a category filter is active, the `get_due_cards` RPC (or query) adds a filter: `user_words.categories @> ARRAY[:selected_category]`.
- Multiple category selection is not supported in this iteration (single-select only).

**Data Requirements:**
- No new tables or columns needed. Uses existing `user_words.categories` text[] field.

---

## 4. Quiz Mode

### Feature Description

A word-matching game where users match Chinese words/phrases to their English meanings. Words are pulled from the user's word bank.

### Quiz Flow

1. **Setup**: User optionally configures quiz settings (or uses defaults):
   - Number of rounds: 5 | 10 | 15 | 20 (each round = 4 word pairs)
   - Word source: `all` | `weak_only` | `specific_categories`
   - Direction: `zh_to_en` | `en_to_zh` | `mixed`

2. **Gameplay (per round)**:
   - 4 Chinese words/phrases displayed on one side.
   - 4 English meanings displayed on the other side (shuffled).
   - User taps to match pairs.
   - Correct match: green highlight, pair fades out.
   - Wrong match: red flash, both items shake, no removal.
   - Round ends when all 4 are matched.

3. **Results**: Score summary, per-round breakdown, option to review mistakes.

### Word Selection Strategy

Words should NOT be pulled purely randomly. Use a **weighted priority queue**:

1. **Weak words first** (weight: 3x) — words where the user's last flashcard grade was "Again" or "Hard", or where `review_cards.stability < 10`.
2. **Due/overdue words** (weight: 2x) — words where `next_review_at <= now()`.
3. **Recently added words** (weight: 1.5x) — words added in the last 7 days (reinforcing new vocabulary).
4. **All other words** (weight: 1x) — general pool.

This ensures the quiz reinforces learning where it's most needed, rather than letting users repeatedly quiz on words they already know.

### Data Requirements

**Table: `quiz_sessions`**

| Field | Type | Nullable | Default | Notes |
|-------|------|----------|---------|-------|
| `id` | uuid (PK) | no | `gen_random_uuid()` | |
| `user_id` | uuid (FK → auth.users) | no | — | |
| `direction` | text | no | `'zh_to_en'` | `zh_to_en` | `en_to_zh` | `mixed`. |
| `word_source` | text | no | `'all'` | `all` | `weak_only` | `categories`. |
| `source_categories` | text[] | yes | null | If word_source = categories, which ones. |
| `total_rounds` | int | no | — | How many rounds (each round = 4 pairs). |
| `total_pairs` | int | no | — | Total word pairs across all rounds (`total_rounds * 4`). |
| `correct_first_try` | int | no | `0` | Pairs matched correctly on first attempt. |
| `total_mistakes` | int | no | `0` | Total wrong taps across the session. |
| `score_percent` | float | no | `0.0` | `correct_first_try / total_pairs * 100`. |
| `duration_ms` | int | yes | null | Total time from quiz start to finish. |
| `completed` | boolean | no | `false` | Whether the user finished or abandoned. |
| `started_at` | timestamptz | no | `now()` | |
| `completed_at` | timestamptz | yes | null | |

**Table: `quiz_round_details`**

| Field | Type | Nullable | Default | Notes |
|-------|------|----------|---------|-------|
| `id` | uuid (PK) | no | `gen_random_uuid()` | |
| `session_id` | uuid (FK → quiz_sessions) | no | — | |
| `round_number` | int | no | — | 1-indexed round within the session. |
| `word_ids` | uuid[] | no | — | The 4 `user_words.id` values in this round. |
| `mistakes` | int | no | `0` | Wrong taps in this round. |
| `duration_ms` | int | yes | null | Time spent on this round. |
| `mistake_details` | jsonb | yes | null | Array of `{ tapped_word_id, tapped_meaning_word_id }` for wrong matches. |

**Indexes:**
- `quiz_sessions (user_id, completed_at DESC)` — quiz history feed.
- `quiz_round_details (session_id, round_number)` — fetch rounds for a session.

**Considerations:**
- The `quiz_round_details` table enables detailed mistake analysis ("You frequently confuse 业务 with 事务").
- `completed` flag distinguishes finished quizzes from abandoned ones — important for accurate score averages on the dashboard.
- Quiz results should optionally feed back into the flashcard system: words with mistakes could get a slight stability penalty or be flagged for sooner review. This is an optional enhancement but the data model supports it.
- `duration_ms` per round and per session enables "time spent" analytics.

---

## 5. Dictionary Page

### Feature Description

The dictionary page is the user's personal vocabulary browser. It shows all words the user has added to their word bank, with search, filtering, and management capabilities.

### Layout

1. **Header**: "Dictionary" title with total word count badge.

2. **Active / Archived toggle**: `SegmentedButton` or `ChoiceChip` pair at the top. Default: Active.
   - **Active**: shows `user_words` where `is_archived = false`.
   - **Archived**: shows `user_words` where `is_archived = true`.

3. **Search bar**: Glass-styled `TextField` below the toggle.
   - Debounced (300ms).
   - Searches across: `chinese`, `pinyin`, `english`, `meaning` fields.
   - Uses the `search_user_words` RPC function (server-side `ilike` across all fields).
   - Placeholder: "Search by word, pinyin, or meaning..."

4. **Word list**: `ListView.builder` of word cards, sorted by `created_at DESC` (newest first).
   - Pull-to-refresh support.
   - Empty state with illustration when no words match.

### Word Card

Each word is displayed as a `GlassCard` containing:
- **Chinese characters** (large, bold, 24sp) with **pinyin above** via `RubyText` widget (if `segments` available).
- **English** word/phrase (16sp, below the Chinese).
- **Meaning** (14sp, muted color, max 2 lines with ellipsis).
- **Category pills** (small rounded containers with semi-transparent accent backgrounds).
- **Creation date** (12sp, muted, bottom-right).
- **3-dot menu** (`PopupMenuButton`) in the top-right corner:
  - **Archive** / **Unarchive** (toggles `is_archived`).
  - **Delete permanently** (hard delete with confirmation dialog: "This will permanently delete this word and its review progress. This action cannot be undone.").

### Actions

- **Archive**: Sets `user_words.is_archived = true`. The word disappears from the active list and moves to the archived list. Review cards for archived words are excluded from the flashcard deck (the `get_due_cards` RPC filters on `is_archived = false`).
- **Unarchive**: Sets `user_words.is_archived = false`. The word returns to the active list and its review card becomes eligible for the flashcard deck again.
- **Delete permanently**: Hard deletes the `user_words` row. The associated `review_cards` row is deleted via CASCADE. The `global_words` entry is NOT affected (other users may reference it). A confirmation dialog is required before deletion.

### Data Requirements

No new tables needed. Reads from `user_words` with the existing schema. Uses the `search_user_words` RPC for search queries.

**Considerations:**
- Search is server-side via RPC for efficiency. Client-side filtering is acceptable for small word banks (< 200 words) but the RPC approach scales better.
- The 3-dot menu should be accessible but not visually dominant — it's a secondary action.
- When a word is deleted, if the user has an active flashcard review session, the deleted card should be removed from the in-memory deck.

---

## 6. Settings / Profile Page

### Feature Description

The settings page allows users to view and edit their profile, learning context, and app preferences. It also provides basic statistics and a sign-out option.

### Layout

1. **Profile header**: Avatar circle (initials if no image) + display name (editable) + email (read-only).

2. **Learning Context section** (`GlassCard`):
   - **Chinese level**: current selection displayed, tap to edit (shows level picker).
   - **Learning purposes**: current selections as pills, tap to edit (opens multi-select).
   - **Industry**: current selection (if applicable), tap to edit.
   - **Additional context**: current text, tap to edit (opens text field).
   - **"Save Changes" button**: visible when any field has changed. On save:
     1. Update the changed fields in `profiles` table.
     2. Call `generate-context` edge function to regenerate `context_summary` and `context_tags`.
     3. Update `profiles.context_summary` and `profiles.context_tags` with the new values.

3. **Preferences section** (`GlassCard`):
   - **Theme**: Dark / Light toggle (`Switch` widget). Persisted to `profiles.theme_preference` and `shared_preferences` (for offline/instant feedback).
   - **Daily word goal**: Slider or number input (5-50 range, default 20). Persisted to `profiles.daily_word_goal`.

4. **Stats section** (`GlassCard` with grid of stat items):
   - **Total words**: count of `user_words` where `is_archived = false`.
   - **Archived words**: count of `user_words` where `is_archived = true`.
   - **Words reviewed today**: count of `review_cards` where `last_reviewed_at >= start_of_today`.
   - These are simple count queries, no `daily_stats` table needed yet.

5. **Sign out button**: Danger-styled (red text on glass). Shows confirmation dialog: "Are you sure you want to sign out?" On confirm: `supabase.auth.signOut()`.

### Data Requirements

No new tables needed. Reads/writes to `profiles` table (already expanded with onboarding fields). Uses `generate-context` edge function for context regeneration.

**Considerations:**
- Context regeneration is an async operation (LLM call). Show a loading indicator while generating.
- Theme toggle should feel instant — update `shared_preferences` + local state immediately, then persist to DB in background.
- The stats section is intentionally simple for this iteration. The full progress dashboard (Section 7) with charts and trends comes in a later iteration.

---

## 7. Progress Dashboard

### Feature Description

A statistics overview showing the user's learning progress over time.

### Metrics Displayed

1. **Words added** — total count + daily/weekly trend graph.
2. **Current streak** — consecutive days of completing the review deck.
3. **Longest streak** — all-time record.
4. **Time spent learning** — per day, calculated from `review_logs.duration_ms` + `quiz_round_details.duration_ms`.
5. **Quiz scores** — average score over time, trend line.
6. **Review accuracy** — percentage of reviews graded Good or Easy vs Again or Hard.
7. **Words mastered** — count of words where `review_cards.stability >= X` threshold (e.g., 30 days = considered "mastered").
8. **AI-generated summary report** — periodic LLM-generated insight ("You're strongest in business vocabulary but struggling with measure words. Focus on...").

### Data Requirements

**Table: `daily_stats`** (pre-aggregated daily metrics for fast dashboard loading)

| Field | Type | Nullable | Default | Notes |
|-------|------|----------|---------|-------|
| `id` | uuid (PK) | no | `gen_random_uuid()` | |
| `user_id` | uuid (FK → auth.users) | no | — | |
| `date` | date | no | — | Calendar date (user's timezone). |
| `words_added` | int | no | `0` | Words added to word bank on this date. |
| `reviews_completed` | int | no | `0` | Total flashcard reviews done. |
| `reviews_correct` | int | no | `0` | Reviews graded Good (3) or Easy (4). |
| `reviews_lapsed` | int | no | `0` | Reviews graded Again (1). |
| `review_time_ms` | bigint | no | `0` | Total ms spent on flashcard reviews. |
| `quiz_sessions_completed` | int | no | `0` | Quizzes completed (not abandoned). |
| `quiz_time_ms` | bigint | no | `0` | Total ms spent on quizzes. |
| `quiz_avg_score` | float | yes | null | Average quiz score for the day. |
| `new_words_mastered` | int | no | `0` | Words that crossed the "mastered" stability threshold today. |

**Unique constraint:** `(user_id, date)` — one row per user per day.

**Table: `ai_reports`** (LLM-generated progress summaries)

| Field | Type | Nullable | Default | Notes |
|-------|------|----------|---------|-------|
| `id` | uuid (PK) | no | `gen_random_uuid()` | |
| `user_id` | uuid (FK → auth.users) | no | — | |
| `report_type` | text | no | — | `weekly` | `monthly` | `milestone`. |
| `summary` | text | no | — | LLM-generated natural language summary. |
| `insights` | jsonb | yes | null | Structured insights: `{ strengths: [...], weaknesses: [...], recommendations: [...] }`. |
| `data_snapshot` | jsonb | no | — | The raw stats used to generate this report (for reproducibility). |
| `generated_at` | timestamptz | no | `now()` | |

**Considerations:**
- `daily_stats` is a **materialised/pre-aggregated** table. It should be updated incrementally — either via database triggers on `review_logs` / `quiz_sessions` inserts, or via an application-level "end of review session" update. This avoids expensive aggregation queries on every dashboard load.
- The alternative is computing everything from `review_logs` and `quiz_sessions` on the fly, but this becomes slow as data grows. The hybrid approach: use `daily_stats` for chart data, and compute "today's" numbers live.
- AI reports are generated on-demand or on a schedule (e.g., weekly on Sunday). The `data_snapshot` field stores the input data so the report can be regenerated if the LLM prompt is improved.
- "Time spent learning" = `review_time_ms + quiz_time_ms` from `daily_stats`.

---

## 8. Global Word Bank & Popularity

### Feature Description

A shared, canonical dictionary of all words ever added by any user. The global bank stores **minimal, neutral word identity data** — no examples, no personalized notes. Its purpose is deduplication, popularity tracking, and powering recommendations.

This enables:
- **Popularity/heat scores** — frequently-added words are "hot", filtered by user context.
- **Context-filtered recommendations** — recommend popular words matching the user's `context_tags`, level, and categories.
- **Level-appropriate suggestions** — `difficulty_estimate` matches words to user proficiency.
- **Rating system** — users can rate the quality of translations.

### Translation Flow: LLM-First Always

The LLM is **always** called when a user adds a word, regardless of whether the word already exists in the global bank. This ensures every user gets a personalized translation (meaning, notes, examples) tailored to their `context_summary` and `context_tags`.

**Flow:**
1. User types input → call LLM edge function with user context → get personalized result.
2. **After** LLM returns, check `global_words` for existing match by `UNIQUE(chinese, pinyin)`.
3. If match found → link `user_words.global_word_id` to existing entry, increment `add_count`, merge any new categories.
4. If no match → create new `global_words` entry with neutral/general data (combined meaning, no examples).
5. Store the personalized version (meaning, notes, examples) in `user_words`.

### Deduplication Strategy: `chinese + pinyin`

The global bank deduplicates on **`UNIQUE(chinese, pinyin)`**:

- **Heteronyms** (same characters, different pronunciation) get **separate entries**: 行 (háng, "row/profession") vs 行 (xíng, "to walk/okay").
- **Polysemy** (same characters, same pronunciation, different senses) gets **one entry with combined meaning**: 加油 (jiā yóu) → meaning: "to add fuel; (fig.) expression of encouragement, 'go for it!'"
- This matches how real dictionaries work — different pronunciation = genuinely different word; same pronunciation = polysemy within one lexical item.

**Why not `chinese + english`?** LLM wording varies ("spend" vs "to spend" vs "spend money"), making English unreliable as a dedup key. Pinyin is linguistically deterministic for a given word.

### Data Requirements

**Table: `global_words`**

| Field | Type | Nullable | Default | Notes |
|-------|------|----------|---------|-------|
| `id` | uuid (PK) | no | `gen_random_uuid()` | |
| `chinese` | text | no | — | Canonical Chinese form. |
| `pinyin` | text | no | — | Pinyin with tone marks. Part of dedup key. |
| `segments` | jsonb | no | `'[]'` | Character-level pinyin breakdown. Linguistic, not context-dependent. |
| `meaning` | text | yes | null | Combined/general meaning across all senses (e.g., "to add fuel; encouragement"). Not user-specific. |
| `categories` | text[] | no | `'{}'` | Aggregated categories from all users who added this word. |
| `add_count` | int | no | `1` | How many users have added this word (popularity). |
| `avg_rating` | float | yes | null | Average user rating (1-5). |
| `rating_count` | int | no | `0` | Number of ratings. |
| `difficulty_estimate` | float | yes | null | Derived from average FSRS difficulty across all users who study this word. Useful for level-matching recommendations. |
| `created_at` | timestamptz | no | `now()` | When first added to global bank. |
| `updated_at` | timestamptz | no | `now()` | Last metadata update. |

**Not stored in `global_words`:** `examples` (always personalized per-user), `notes` (always personalized per-user), `english` (varies by user context and LLM wording — lives in `user_words`).

**Indexes:**
- `UNIQUE(chinese, pinyin)` — the dedup constraint.
- `(add_count DESC)` — for popularity-sorted queries.
- GIN on `categories` — for context-filtered recommendations (array overlap with user's `context_tags`).
- GIN trigram on `chinese`, `pinyin` — for search.

**Table: `word_ratings`**

| Field | Type | Nullable | Default | Notes |
|-------|------|----------|---------|-------|
| `id` | uuid (PK) | no | `gen_random_uuid()` | |
| `user_id` | uuid (FK → auth.users) | no | — | |
| `global_word_id` | uuid (FK → global_words) | no | — | |
| `rating` | int | no | — | 1-5 stars. |
| `created_at` | timestamptz | no | `now()` | |

**Unique constraint:** `(user_id, global_word_id)` — one rating per user per word.

### How Global Bank Powers Recommendations

All recommendations are **context-filtered** — they match the user's `context_tags`, `chinese_level`, and categories. A business learner gets popular business words, not popular travel words.

- **Contextual popularity**: recommend high `add_count` words where `global_words.categories` overlaps with the user's `context_tags`. Not raw global popularity — filtered to the user's domain/interests.
  ```sql
  SELECT gw.* FROM global_words gw
  WHERE gw.categories && :user_context_tags  -- array overlap
    AND NOT EXISTS (SELECT 1 FROM user_words uw WHERE uw.global_word_id = gw.id AND uw.user_id = :uid)
  ORDER BY gw.add_count DESC
  LIMIT 20;
  ```
- **Level-matching**: `difficulty_estimate` filters words appropriate to user's `chinese_level` (beginner < 4, intermediate 4-7, advanced > 7).
- **Similar-user**: find users with overlapping `profiles.context_tags` → get their recently-added words → rank by frequency among similar users → exclude words current user already has.
- **Onboarding**: LLM generates starter pack based on user profile → cross-reference with global bank → link existing entries.
- **At recommendation acceptance**: call LLM to generate personalized meaning/examples for the user's context.

### Considerations
- `add_count` is incremented via a trigger or application logic when a `user_words` row references a `global_word_id`.
- `difficulty_estimate` is periodically recomputed from `review_cards.difficulty` across all users who have this word.
- `avg_rating` and `rating_count` are denormalised from `word_ratings` for fast reads. Update via trigger on rating insert/update.
- RLS on `global_words`: all authenticated users can **read**. Only the system (service role) should **write/update** to prevent tampering. User actions (add, rate) go through controlled application logic.
- `word_ratings` uses standard user-owns-own-rows RLS.
- Fuzzy matching (e.g., simplified vs traditional Chinese) is a future consideration.

---

## 9. Word Recommendations

### Feature Description

When a user adds a word to their word bank, the system suggests related words. There is also a "Random New Word" button that generates contextually relevant words.

### Recommendation Sources

1. **LLM contextual suggestions** — When a word is added, the LLM response includes a `related_words` array of 3-5 suggestions. These are words commonly used in the same context.
2. **Context-filtered popularity** — Recommend popular words from `global_words` where `categories` overlap with the user's `context_tags`, excluding words the user has already added.
3. **Random new word** — User taps a button → LLM generates a word based on: user profile context, existing word bank categories, and words the user does NOT already have.

### Filtering Logic

All recommendation paths must exclude:
- Words already in the user's `user_words` (not archived).
- Words the user has explicitly dismissed (optional: track dismissals).

### Data Requirements

**Table: `word_suggestions`** (cached suggestions, not shown to user until they request)

| Field | Type | Nullable | Default | Notes |
|-------|------|----------|---------|-------|
| `id` | uuid (PK) | no | `gen_random_uuid()` | |
| `user_id` | uuid (FK → auth.users) | no | — | |
| `trigger_word_id` | uuid (FK → user_words) | yes | null | The word that triggered this suggestion (null for random/onboarding). |
| `suggestion_type` | text | no | — | `contextual` | `popular` | `random` | `onboarding`. |
| `global_word_id` | uuid (FK → global_words) | yes | null | If the suggestion maps to an existing global word. |
| `english` | text | no | — | Suggested word English form. |
| `chinese` | text | no | — | Suggested word Chinese form. |
| `pinyin` | text | no | — | |
| `meaning` | text | yes | null | |
| `reason` | text | yes | null | Why this was suggested (e.g., "Commonly used with 业务 in business contexts"). |
| `status` | text | no | `'pending'` | `pending` | `accepted` | `dismissed`. |
| `created_at` | timestamptz | no | `now()` | |

**Indexes:**
- `(user_id, status, created_at DESC)` — fetch pending suggestions.
- `(user_id, trigger_word_id)` — fetch suggestions related to a specific word.

**Considerations:**
- Suggestions are **pre-generated** and cached in this table, not computed on every page load. They are generated:
  - When a word is added (contextual suggestions from the LLM response).
  - Periodically in batch (popular words the user hasn't added).
  - On-demand when the user taps "Random New Word".
- `status` tracking enables analytics on suggestion acceptance rate and helps avoid re-suggesting dismissed words.
- `reason` provides transparency to the user about why a word was suggested — important for trust.
- When a suggestion is `accepted`, it triggers the standard word-add flow (create `user_words` + `review_cards` + update `global_words`).

---

## 10. Similar User Recommendations

### Feature Description

Recommend words that users with similar profiles are learning. "Users like you also added these words."

### Matching Logic

Users are "similar" if they share:
- Same `chinese_level` (or ±1 level).
- Overlapping `learning_purposes` (at least 1 shared value).
- Same `industry` (if applicable).

### Implementation Approach

This does NOT require a separate table. It can be computed as a query:

```
1. Find users with similar context_tags (array overlap).
2. Get their most popular recently-added words (from user_words).
3. Exclude words the current user already has.
4. Rank by frequency (how many similar users added it).
```

### Data Requirements

No new table needed. The query relies on:
- `profiles.context_tags` — for user similarity matching (GIN index).
- `user_words` — for finding what similar users added.
- `global_words.add_count` — as a secondary ranking signal.

**Considerations:**
- This is a potentially expensive query. Consider **caching** results in `word_suggestions` with `suggestion_type = 'similar_users'` and refreshing periodically (e.g., daily).
- Privacy: the query should never expose which specific users added which words. It only surfaces aggregate popularity.
- Minimum threshold: only suggest words added by at least N similar users (e.g., 3) to avoid noise.
- This feature becomes more valuable as the user base grows. For early-stage (few users), lean more on LLM-based and popularity-based recommendations.

---

## 11. Onboarding Word Suggestions

### Feature Description

During onboarding, after the user completes their profile, the app suggests a starter pack of words based on their context. The user can select which words to add to their word bank.

### Flow

1. User completes onboarding profile questions.
2. App calls an LLM edge function with the user's profile context.
3. LLM returns 20-30 suggested starter words appropriate to the user's level and purpose.
4. Words are displayed as selectable cards (pre-checked, user can deselect).
5. User taps "Add Selected" → all selected words are bulk-inserted into `user_words` + `review_cards`.

### Data Requirements

Uses the existing `word_suggestions` table with `suggestion_type = 'onboarding'`.

The LLM edge function response shape for onboarding suggestions:
```json
{
  "suggestions": [
    {
      "english": "meeting",
      "chinese": "会议",
      "pinyin": "huì yì",
      "meaning": "a formal gathering for discussion",
      "segments": [{ "char": "会", "pinyin": "huì" }, { "char": "议", "pinyin": "yì" }],
      "categories": ["business", "formal"],
      "reason": "Essential business vocabulary for your level"
    }
  ]
}
```

**Considerations:**
- Onboarding suggestions should be cached in `word_suggestions` so the user can revisit them later (e.g., "See onboarding suggestions you skipped").
- The LLM prompt should be level-aware: absolute beginners get basic words (你好, 谢谢), intermediate learners get domain-specific vocabulary.
- Cross-reference with `global_words` to link suggestions to existing canonical entries and benefit from cached translations.
- Bulk insert performance: inserting 20+ words at once needs to be efficient. Use a single batch insert for `user_words` and `review_cards`.

---

## 12. Future Features

These are documented for data model awareness but are **not part of the current iteration**.

### 12a. Sentence Practice Mode *(future)*
Users construct sentences using words from their word bank. The LLM evaluates grammar, word choice, and naturalness.

**Data implications:**
- New table: `sentence_attempts` — stores the user's sentence, the target words used, LLM feedback, correctness score.
- Links to `user_words` via a junction table or uuid array.

### 12b. Camera / Photo Word Capture *(future)*
User takes a photo or selects from camera roll, highlights Chinese text, and adds words to the word bank.

**Data implications:**
- OCR processing (on-device or via edge function).
- `user_words.source = 'camera'` to track acquisition channel.
- Optional: store the source image URL in a `source_metadata` jsonb field on `user_words`.

### 12c. PDF Upload & Highlight *(future)*
Upload a PDF, highlight words, and add them to the word bank.

**Data implications:**
- PDF storage in Supabase Storage.
- New table or `source_metadata` on `user_words` to track: PDF file reference, page number, highlight position.
- `user_words.source = 'pdf'`.

### 12d. Voice Input *(future)*
Speak a word (in English or Chinese) to add it to the word bank.

**Data implications:**
- Speech-to-text processing (on-device or via edge function).
- `user_words.source = 'voice'`.
- Optional: store the audio clip URL for review/playback.

### 12e. Level Progress Suggestions *(future)*
After reaching certain milestones, the system suggests that the user update their profile to better reflect their current level and learning context.

**Trigger conditions (any of):**
- 50+ words with `review_cards.stability >= 30` (considered "mastered").
- Average `review_cards.difficulty` across active cards drops below 3.0 (most cards feel "easy").
- Quiz accuracy consistently > 80% over the last 10 quiz sessions.
- User has been at the same `chinese_level` for 60+ days with active daily reviews.

**UX:**
- A non-intrusive banner or card appears on the home screen: "Your performance suggests you might be ready for the next level. Would you like to update your profile?"
- On accept: navigate to profile editing screen, pre-suggest the next level up.
- On dismiss: don't show again for 30 days.
- After profile update: regenerate `context_summary` and `context_tags` via the `generate-context` edge function. Future translations and recommendations will reflect the new level.

**Data implications:**
- No new tables needed. Uses existing `review_cards.difficulty`, `review_cards.stability`, and `profiles.chinese_level`.
- Could store last dismissed date in `shared_preferences` or a `user_settings` jsonb field.

### Future-Proofing in Current Schema
The `user_words.source` field and a nullable `source_metadata jsonb` column on `user_words` are sufficient to accommodate all future input methods without schema changes. Adding `source_metadata` now is low-cost and avoids a future migration:

| Field | Type | Notes |
|-------|------|-------|
| `source_metadata` | jsonb | Nullable. Stores source-specific data: `{ image_url, pdf_url, page, audio_url, ... }` |

---

## 13. Consolidated Data Model Summary

### All Tables

| # | Table | Purpose | Estimated Row Growth |
|---|-------|---------|---------------------|
| 1 | `profiles` | User identity + learning context | 1 per user |
| 2 | `user_words` | Personal word bank entries | ~50-500 per user |
| 3 | `review_cards` | FSRS flashcard state per word | 1:1 with `user_words` |
| 4 | `review_logs` | Append-only review event history | ~10-50 per card over lifetime |
| 5 | `streaks` | Streak tracking per user | 1 per user |
| 6 | `quiz_sessions` | Quiz attempt metadata | ~2-5 per user per week |
| 7 | `quiz_round_details` | Per-round quiz breakdown | 4-20 per quiz session |
| 8 | `daily_stats` | Pre-aggregated daily metrics | 1 per user per active day |
| 9 | `ai_reports` | LLM-generated progress summaries | ~1-4 per user per month |
| 10 | `global_words` | Shared canonical word dictionary | Grows with unique words across all users |
| 11 | `word_ratings` | User ratings on global words | Sparse — only if user rates |
| 12 | `word_suggestions` | Cached recommendations | ~5-30 per word addition event |

### Key Relationships

```
auth.users
  ├── profiles (1:1)
  ├── user_words (1:many)
  │     ├── review_cards (1:1)
  │     │     └── review_logs (1:many)
  │     └── global_words (many:1, optional)
  ├── streaks (1:1)
  ├── quiz_sessions (1:many)
  │     └── quiz_round_details (1:many)
  ├── daily_stats (1:many, partitioned by date)
  ├── ai_reports (1:many)
  ├── word_ratings (1:many)
  └── word_suggestions (1:many)
```

### RLS Policy Summary

| Table | Select | Insert | Update | Delete |
|-------|--------|--------|--------|--------|
| `profiles` | Own row | Own row | Own row | No |
| `user_words` | Own rows | Own rows | Own rows | Own rows |
| `review_cards` | Own rows | Own rows | Own rows | Own rows |
| `review_logs` | Own rows | Own rows | No (append-only) | No |
| `streaks` | Own row | Own row | Own row | No |
| `quiz_sessions` | Own rows | Own rows | Own rows | No |
| `quiz_round_details` | Via session ownership | Via session ownership | No | No |
| `daily_stats` | Own rows | Own rows | Own rows | No |
| `ai_reports` | Own rows | System insert | No | No |
| `global_words` | All authenticated | System only | System only | System only |
| `word_ratings` | Own rows | Own rows | Own rows | Own rows |
| `word_suggestions` | Own rows | System + own | Own rows | Own rows |

### Indexes Summary

| Table | Index | Purpose |
|-------|-------|---------|
| `profiles` | GIN on `context_tags` | Similar-user matching |
| `user_words` | `(user_id, created_at DESC)` | Word bank feed |
| `user_words` | `(user_id, is_archived)` | Active word filtering |
| `user_words` | GIN on `categories` | Category filtering |
| `user_words` | GIN trigram on `english, chinese, pinyin` | Search-as-you-type |
| `user_words` | `(user_id, global_word_id)` UNIQUE partial | Dedup canonical words |
| `review_cards` | `(user_id, next_review_at)` | Due card queries |
| `review_cards` | `(user_id, state)` | State-based analytics |
| `review_logs` | `(user_id, reviewed_at DESC)` | Review history |
| `review_logs` | `(card_id, reviewed_at DESC)` | Per-card history |
| `streaks` | `(user_id)` UNIQUE | One per user |
| `quiz_sessions` | `(user_id, completed_at DESC)` | Quiz history |
| `daily_stats` | `(user_id, date)` UNIQUE | One per user per day |
| `global_words` | `UNIQUE(chinese, pinyin)` | Dedup constraint |
| `global_words` | `(add_count DESC)` | Popularity queries |
| `global_words` | GIN on `categories` | Category recommendations |
| `word_suggestions` | `(user_id, status, created_at DESC)` | Pending suggestions |

### Critical Design Decisions

1. **FSRS over SM-2**: FSRS achieves 20-30% fewer reviews for the same retention. Its three-component model (Difficulty, Stability, Retrievability) is more accurate than SM-2's single ease factor. The `review_logs` table enables future per-user parameter optimisation.

2. **Separate `user_words` and `global_words`**: Users own their personal copies (with personalized meaning, notes, examples). The global table stores minimal neutral data (word identity, combined meaning, segments, aggregated categories — no examples). This separation enables personal customisation while building a shared knowledge base.

3. **LLM-first always**: The LLM is always called for personalized translations, even if the word exists in `global_words`. Deduplication happens after the LLM returns, by matching `UNIQUE(chinese, pinyin)`. This maximises personalization at the cost of LLM calls.

4. **Dedup on `chinese + pinyin`**: Heteronyms (same characters, different pronunciation like 行 háng/xíng) get separate global entries. Polysemy (same characters, same pronunciation like 加油) gets one entry with combined meaning. Matches real dictionary conventions.

5. **Context-filtered recommendations**: Global popularity is always filtered by `categories && user_context_tags` overlap. A business learner sees popular business words, not popular travel words.

6. **`review_logs` as append-only**: Never update or delete. This is the training data for FSRS parameter tuning and the source of truth for all time-based analytics.

7. **`daily_stats` as pre-aggregated cache**: Computing stats from `review_logs` on every dashboard load is expensive at scale. Pre-aggregate daily and query the summary table instead.

8. **`word_suggestions` as a cached queue**: Recommendations are computed asynchronously and stored, not generated on every page load. This decouples the recommendation engine from the UI response time.

9. **Soft-archive over hard delete for words**: `user_words.is_archived = true` instead of `DELETE`. Preserves review history, quiz references, and global word counts.

10. **`source` + `source_metadata` on `user_words`**: Future-proofs for camera, PDF, voice input methods without schema migrations.
