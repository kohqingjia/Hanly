-- ============================================================
-- Migration 004: Full DB Reset for Iteration 3
-- Changes from 003:
--   - profiles.industry (text) → profiles.interests (text[])
-- ============================================================

-- ============================================================
-- 1. DROP EVERYTHING
-- ============================================================

DROP TRIGGER IF EXISTS on_user_word_created ON user_words;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user_word();
DROP FUNCTION IF EXISTS handle_new_user();
DROP FUNCTION IF EXISTS get_due_cards(uuid, text);
DROP FUNCTION IF EXISTS search_user_words(uuid, text, boolean);
DROP TABLE IF EXISTS review_cards CASCADE;
DROP TABLE IF EXISTS user_words CASCADE;
DROP TABLE IF EXISTS global_words CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- ============================================================
-- 2. PROFILES TABLE
-- ============================================================

CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  display_name text,
  age_range text,
  chinese_level text,
  learning_purposes text[] DEFAULT '{}',
  interests text[] DEFAULT '{}',
  additional_context text,
  context_summary text,
  context_tags text[] DEFAULT '{}',
  onboarding_completed boolean NOT NULL DEFAULT false,
  daily_word_goal int DEFAULT 20,
  theme_preference text DEFAULT 'dark',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE INDEX IF NOT EXISTS idx_profiles_context_tags
  ON profiles USING gin (context_tags);
CREATE INDEX IF NOT EXISTS idx_profiles_interests
  ON profiles USING gin (interests);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, onboarding_completed)
  VALUES (new.id, new.raw_user_meta_data->>'display_name', false);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ============================================================
-- 3. GLOBAL_WORDS TABLE
-- ============================================================

CREATE TABLE global_words (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chinese text NOT NULL,
  pinyin text NOT NULL,
  segments jsonb NOT NULL DEFAULT '[]',
  meaning text,
  categories text[] DEFAULT '{}',
  add_count int NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT global_words_chinese_pinyin_unique UNIQUE (chinese, pinyin)
);

ALTER TABLE global_words ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read global words"
  ON global_words FOR SELECT
  TO authenticated
  USING (true);

CREATE INDEX idx_global_words_add_count ON global_words (add_count DESC);
CREATE INDEX idx_global_words_categories ON global_words USING gin (categories);

-- ============================================================
-- 4. USER_WORDS TABLE
-- ============================================================

CREATE TABLE user_words (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  global_word_id uuid REFERENCES global_words ON DELETE SET NULL,
  english text NOT NULL,
  chinese text NOT NULL,
  pinyin text,
  meaning text,
  notes text,
  examples jsonb NOT NULL DEFAULT '[]',
  segments jsonb NOT NULL DEFAULT '[]',
  categories text[] NOT NULL DEFAULT '{}',
  source text NOT NULL DEFAULT 'manual',
  is_archived boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE user_words ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own words"
  ON user_words FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own words"
  ON user_words FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own words"
  ON user_words FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own words"
  ON user_words FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_user_words_user_created
  ON user_words (user_id, created_at DESC);
CREATE INDEX idx_user_words_user_archived
  ON user_words (user_id, is_archived);
CREATE INDEX idx_user_words_categories
  ON user_words USING gin (categories);

CREATE UNIQUE INDEX idx_user_words_user_global_unique
  ON user_words (user_id, global_word_id)
  WHERE global_word_id IS NOT NULL;

-- ============================================================
-- 5. REVIEW_CARDS TABLE (FSRS-based)
-- ============================================================

CREATE TABLE review_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  word_id uuid NOT NULL REFERENCES user_words ON DELETE CASCADE,
  stability float NOT NULL DEFAULT 0.0,
  difficulty float NOT NULL DEFAULT 5.0,
  reps int NOT NULL DEFAULT 0,
  lapses int NOT NULL DEFAULT 0,
  state text NOT NULL DEFAULT 'new',
  last_grade int,
  next_review_at timestamptz NOT NULL DEFAULT now(),
  last_reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT review_cards_user_word_unique UNIQUE (user_id, word_id)
);

ALTER TABLE review_cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own review cards"
  ON review_cards FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own review cards"
  ON review_cards FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own review cards"
  ON review_cards FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own review cards"
  ON review_cards FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_review_cards_user_next_review
  ON review_cards (user_id, next_review_at);
CREATE INDEX idx_review_cards_user_state
  ON review_cards (user_id, state);

-- ============================================================
-- 6. TRIGGER: Auto-create review_card on user_words insert
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user_word()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.review_cards (user_id, word_id, stability, difficulty, reps, lapses, state, next_review_at)
  VALUES (new.user_id, new.id, 0.0, 5.0, 0, 0, 'new', now());
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_user_word_created
  AFTER INSERT ON user_words
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user_word();

-- ============================================================
-- 7. RPC: Get due cards (review_cards + user_words join)
-- ============================================================

CREATE OR REPLACE FUNCTION get_due_cards(p_user_id uuid, p_category text DEFAULT NULL)
RETURNS TABLE (
  card_id uuid,
  card_stability float,
  card_difficulty float,
  card_reps int,
  card_lapses int,
  card_state text,
  card_last_grade int,
  card_next_review_at timestamptz,
  card_last_reviewed_at timestamptz,
  word_id uuid,
  word_english text,
  word_chinese text,
  word_pinyin text,
  word_meaning text,
  word_notes text,
  word_examples jsonb,
  word_segments jsonb,
  word_categories text[],
  word_created_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    rc.id AS card_id,
    rc.stability AS card_stability,
    rc.difficulty AS card_difficulty,
    rc.reps AS card_reps,
    rc.lapses AS card_lapses,
    rc.state AS card_state,
    rc.last_grade AS card_last_grade,
    rc.next_review_at AS card_next_review_at,
    rc.last_reviewed_at AS card_last_reviewed_at,
    uw.id AS word_id,
    uw.english AS word_english,
    uw.chinese AS word_chinese,
    uw.pinyin AS word_pinyin,
    uw.meaning AS word_meaning,
    uw.notes AS word_notes,
    uw.examples AS word_examples,
    uw.segments AS word_segments,
    uw.categories AS word_categories,
    uw.created_at AS word_created_at
  FROM review_cards rc
  JOIN user_words uw ON rc.word_id = uw.id
  WHERE rc.user_id = p_user_id
    AND rc.next_review_at <= now()
    AND uw.is_archived = false
    AND (p_category IS NULL OR uw.categories @> ARRAY[p_category])
  ORDER BY rc.next_review_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 8. RPC: Search user words
-- ============================================================

CREATE OR REPLACE FUNCTION search_user_words(
  p_user_id uuid,
  p_query text,
  p_archived boolean DEFAULT false
)
RETURNS SETOF user_words AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM user_words
  WHERE user_id = p_user_id
    AND is_archived = p_archived
    AND (
      chinese ILIKE '%' || p_query || '%'
      OR pinyin ILIKE '%' || p_query || '%'
      OR english ILIKE '%' || p_query || '%'
      OR meaning ILIKE '%' || p_query || '%'
    )
  ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
