-- Profiles
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz default now()
);

alter table profiles enable row level security;

create policy "Users can read own profile"
  on profiles for select using (auth.uid() = id);
create policy "Users can update own profile"
  on profiles for update using (auth.uid() = id);
create policy "Users can insert own profile"
  on profiles for insert with check (auth.uid() = id);

-- Dictionary entries
create table dictionary_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  english text not null,
  chinese text not null,
  pinyin text,
  meaning text,
  notes text,
  examples jsonb default '[]',
  tags text[] default '{}',
  is_mastered boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_dictionary_user_created on dictionary_entries (user_id, created_at desc);

alter table dictionary_entries enable row level security;

create policy "Users can read own entries"
  on dictionary_entries for select using (auth.uid() = user_id);
create policy "Users can insert own entries"
  on dictionary_entries for insert with check (auth.uid() = user_id);
create policy "Users can update own entries"
  on dictionary_entries for update using (auth.uid() = user_id);
create policy "Users can delete own entries"
  on dictionary_entries for delete using (auth.uid() = user_id);

-- Flashcard progress
create table flashcard_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  entry_id uuid not null references dictionary_entries on delete cascade,
  ease float default 2.5,
  interval_days int default 0,
  repetitions int default 0,
  next_review_at timestamptz default now(),
  last_reviewed_at timestamptz,
  unique(user_id, entry_id)
);

alter table flashcard_progress enable row level security;

create policy "Users can read own progress"
  on flashcard_progress for select using (auth.uid() = user_id);
create policy "Users can insert own progress"
  on flashcard_progress for insert with check (auth.uid() = user_id);
create policy "Users can update own progress"
  on flashcard_progress for update using (auth.uid() = user_id);
create policy "Users can delete own progress"
  on flashcard_progress for delete using (auth.uid() = user_id);

-- Quiz results
create table quiz_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  quiz_type text not null,
  total_questions int not null,
  correct_answers int not null,
  score_percent float not null,
  entries_tested uuid[] not null,
  details jsonb default '[]',
  completed_at timestamptz default now()
);

create index idx_quiz_user_completed on quiz_results (user_id, completed_at desc);

alter table quiz_results enable row level security;

create policy "Users can read own results"
  on quiz_results for select using (auth.uid() = user_id);
create policy "Users can insert own results"
  on quiz_results for insert with check (auth.uid() = user_id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data->>'display_name');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
