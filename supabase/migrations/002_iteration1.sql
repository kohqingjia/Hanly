-- ============================================================
-- Migration 002: Iteration 1 — New Architecture
-- Drops old tables, expands profiles, creates global_words,
-- user_words, review_cards with FSRS support.
-- ============================================================

-- ============================================================
-- 1. DROP OLD TABLES (fresh start, no data migration)
-- ============================================================

drop table if exists flashcard_progress cascade;
drop table if exists dictionary_entries cascade;
drop table if exists quiz_results cascade;

-- ============================================================
-- 2. EXPAND PROFILES TABLE
-- ============================================================

-- Drop and recreate the trigger function to include new defaults
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

alter table profiles
  add column if not exists chinese_level text,
  add column if not exists learning_purposes text[] default '{}',
  add column if not exists industry text,
  add column if not exists additional_context text,
  add column if not exists context_summary text,
  add column if not exists context_tags text[] default '{}',
  add column if not exists onboarding_completed boolean not null default false,
  add column if not exists daily_word_goal int default 20,
  add column if not exists theme_preference text default 'dark',
  add column if not exists updated_at timestamptz default now();

-- Recreate trigger function with onboarding_completed default
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name, onboarding_completed)
  values (new.id, new.raw_user_meta_data->>'display_name', false);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Index for similar-user matching
create index if not exists idx_profiles_context_tags
  on profiles using gin (context_tags);

-- ============================================================
-- 3. CREATE GLOBAL_WORDS TABLE
-- ============================================================

create table global_words (
  id uuid primary key default gen_random_uuid(),
  chinese text not null,
  pinyin text not null,
  segments jsonb not null default '[]',
  meaning text,
  categories text[] default '{}',
  add_count int not null default 1,
  avg_rating float,
  rating_count int not null default 0,
  difficulty_estimate float,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint global_words_chinese_pinyin_unique unique (chinese, pinyin)
);

alter table global_words enable row level security;

-- All authenticated users can read the global dictionary
create policy "Authenticated users can read global words"
  on global_words for select
  to authenticated
  using (true);

-- No direct INSERT/UPDATE/DELETE from client
-- All writes go through the save-word edge function using service role

-- Indexes
create index idx_global_words_add_count on global_words (add_count desc);
create index idx_global_words_categories on global_words using gin (categories);

-- ============================================================
-- 4. CREATE USER_WORDS TABLE (replaces dictionary_entries)
-- ============================================================

create table user_words (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  global_word_id uuid references global_words on delete set null,
  english text not null,
  chinese text not null,
  pinyin text,
  meaning text,
  notes text,
  examples jsonb not null default '[]',
  segments jsonb not null default '[]',
  categories text[] not null default '{}',
  source text not null default 'manual',
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table user_words enable row level security;

create policy "Users can read own words"
  on user_words for select using (auth.uid() = user_id);
create policy "Users can insert own words"
  on user_words for insert with check (auth.uid() = user_id);
create policy "Users can update own words"
  on user_words for update using (auth.uid() = user_id);
create policy "Users can delete own words"
  on user_words for delete using (auth.uid() = user_id);

-- Indexes
create index idx_user_words_user_created
  on user_words (user_id, created_at desc);
create index idx_user_words_user_archived
  on user_words (user_id, is_archived);
create index idx_user_words_categories
  on user_words using gin (categories);

-- Prevent same user from adding the same canonical word twice
create unique index idx_user_words_user_global_unique
  on user_words (user_id, global_word_id)
  where global_word_id is not null;

-- ============================================================
-- 5. CREATE REVIEW_CARDS TABLE (replaces flashcard_progress)
-- ============================================================

create table review_cards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  word_id uuid not null references user_words on delete cascade,
  stability float not null default 0.0,
  difficulty float not null default 5.0,
  reps int not null default 0,
  lapses int not null default 0,
  state text not null default 'new',
  last_grade int,
  next_review_at timestamptz not null default now(),
  last_reviewed_at timestamptz,
  created_at timestamptz not null default now(),

  constraint review_cards_user_word_unique unique (user_id, word_id)
);

alter table review_cards enable row level security;

create policy "Users can read own review cards"
  on review_cards for select using (auth.uid() = user_id);
create policy "Users can insert own review cards"
  on review_cards for insert with check (auth.uid() = user_id);
create policy "Users can update own review cards"
  on review_cards for update using (auth.uid() = user_id);
create policy "Users can delete own review cards"
  on review_cards for delete using (auth.uid() = user_id);

-- Indexes
create index idx_review_cards_user_next_review
  on review_cards (user_id, next_review_at);
create index idx_review_cards_user_state
  on review_cards (user_id, state);

-- ============================================================
-- 6. TRIGGER: Auto-create review_card on user_words insert
-- ============================================================

create or replace function public.handle_new_user_word()
returns trigger as $$
begin
  insert into public.review_cards (user_id, word_id, stability, difficulty, reps, lapses, state, next_review_at)
  values (new.user_id, new.id, 0.0, 5.0, 0, 0, 'new', now());
  return new;
end;
$$ language plpgsql security definer;

create trigger on_user_word_created
  after insert on user_words
  for each row execute procedure public.handle_new_user_word();

-- ============================================================
-- 7. RPC: Get due cards (review_cards + user_words join)
-- ============================================================

create or replace function get_due_cards(p_user_id uuid, p_category text default null)
returns table (
  -- review_cards fields
  card_id uuid,
  card_stability float,
  card_difficulty float,
  card_reps int,
  card_lapses int,
  card_state text,
  card_last_grade int,
  card_next_review_at timestamptz,
  card_last_reviewed_at timestamptz,
  -- user_words fields
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
) as $$
begin
  return query
  select
    rc.id as card_id,
    rc.stability as card_stability,
    rc.difficulty as card_difficulty,
    rc.reps as card_reps,
    rc.lapses as card_lapses,
    rc.state as card_state,
    rc.last_grade as card_last_grade,
    rc.next_review_at as card_next_review_at,
    rc.last_reviewed_at as card_last_reviewed_at,
    uw.id as word_id,
    uw.english as word_english,
    uw.chinese as word_chinese,
    uw.pinyin as word_pinyin,
    uw.meaning as word_meaning,
    uw.notes as word_notes,
    uw.examples as word_examples,
    uw.segments as word_segments,
    uw.categories as word_categories,
    uw.created_at as word_created_at
  from review_cards rc
  join user_words uw on rc.word_id = uw.id
  where rc.user_id = p_user_id
    and rc.next_review_at <= now()
    and uw.is_archived = false
    and (p_category is null or uw.categories @> array[p_category])
  order by rc.next_review_at asc;
end;
$$ language plpgsql security definer;

-- ============================================================
-- 8. RPC: Search user words
-- ============================================================

create or replace function search_user_words(
  p_user_id uuid,
  p_query text,
  p_archived boolean default false
)
returns setof user_words as $$
begin
  return query
  select *
  from user_words
  where user_id = p_user_id
    and is_archived = p_archived
    and (
      chinese ilike '%' || p_query || '%'
      or pinyin ilike '%' || p_query || '%'
      or english ilike '%' || p_query || '%'
      or meaning ilike '%' || p_query || '%'
    )
  order by created_at desc;
end;
$$ language plpgsql security definer;
