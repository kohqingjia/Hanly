-- Migration 005: Narrow scope to tech/business Chinese vocabulary
-- Target audience: professionals fluent-ish in Chinese, needing business/technical vocab

-- ============================================================
-- 1. Global words: wipe all data (fresh start for new scope)
--    FK on user_words.global_word_id is ON DELETE SET NULL,
--    so this nullifies references without deleting user data.
--    But since we're doing a full scope change, truncate cascade
--    to also clear user_words and review_cards.
-- ============================================================
TRUNCATE TABLE global_words CASCADE;

-- 2. Global words: drop columns no longer needed
ALTER TABLE global_words DROP COLUMN IF EXISTS segments;
ALTER TABLE global_words DROP COLUMN IF EXISTS categories;

-- Drop the categories GIN index (column no longer exists)
DROP INDEX IF EXISTS idx_global_words_categories;

-- ============================================================
-- 3. Profiles: remove general-purpose language learning fields
-- ============================================================
ALTER TABLE profiles DROP COLUMN IF EXISTS chinese_level;
ALTER TABLE profiles DROP COLUMN IF EXISTS learning_purposes;
ALTER TABLE profiles DROP COLUMN IF EXISTS age_range;

-- 4. Profiles: rename interests -> focus_areas
ALTER TABLE profiles RENAME COLUMN interests TO focus_areas;

-- Update the GIN index
DROP INDEX IF EXISTS idx_profiles_interests;
CREATE INDEX idx_profiles_focus_areas ON profiles USING gin (focus_areas);

-- ============================================================
-- 5. Reset onboarding for existing users (scope changed)
-- ============================================================
UPDATE profiles SET onboarding_completed = false, focus_areas = '{}', context_summary = NULL, context_tags = '{}';
