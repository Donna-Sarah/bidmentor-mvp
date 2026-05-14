-- ============================================================
-- BIDMENTOR — Base schema
-- Run this first on a fresh Supabase project.
-- Then run supabase/schema-patches.sql.
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- Shared updated_at trigger
-- ============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================
-- LESSONS
-- Used by:
-- - getLessonsGroupedByTier()
-- - getLessonBySlug()
-- - getRelatedLessons()
-- - increment_lesson_view_count RPC
-- - lesson list/detail pages
-- ============================================================

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  slug text not null,
  title text not null,
  title_en text,
  tier integer not null check (tier in (0, 1, 2, 3)),
  category text not null check (
    category in (
      'bao-lanh',
      'kinh-nghiem',
      'fatal-errors',
      'deadline',
      'tai-chinh',
      'ky-thuat',
      'nhan-su',
      'quy-trinh',
      'hop-dong'
    )
  ),
  tags text[] not null default '{}',
  objective text not null default '',
  explanation text not null default '',
  content_mdx text not null default '',
  common_mistakes jsonb not null default '[]'::jsonb,
  fatal_errors jsonb not null default '[]'::jsonb,
  related_slugs text[] not null default '{}',
  quiz jsonb,
  is_published boolean not null default false,
  is_priority boolean not null default false,
  view_count integer not null default 0 check (view_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists idx_lessons_slug_unique
  on public.lessons (slug);

create index if not exists idx_lessons_slug
  on public.lessons (slug);

create index if not exists idx_lessons_tier_published
  on public.lessons (tier, is_published);

create index if not exists idx_lessons_priority
  on public.lessons (is_priority)
  where is_priority = true;

drop trigger if exists set_lessons_updated_at on public.lessons;
create trigger set_lessons_updated_at
  before update on public.lessons
  for each row
  execute function public.set_updated_at();

alter table public.lessons enable row level security;

grant select on public.lessons to anon, authenticated;
grant all on public.lessons to service_role;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'lessons'
      and policyname = 'Published lessons are readable'
  ) then
    create policy "Published lessons are readable"
      on public.lessons
      for select
      to anon, authenticated
      using (is_published = true);
  end if;
end;
$$;

-- RPC used by src/lib/supabase/queries/lessons.ts.
create or replace function public.increment_lesson_view_count(lesson_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.lessons
  set view_count = view_count + 1
  where id = lesson_id;
end;
$$;

grant execute on function public.increment_lesson_view_count(uuid) to anon, authenticated;

-- ============================================================
-- GLOSSARY TERMS
-- Used by:
-- - getAllGlossaryTerms()
-- - getGlossaryTermBySlug()
-- - getGlossaryTermMap()
-- - glossary pages and lesson tooltip highlighting
-- ============================================================

create table if not exists public.glossary_terms (
  id uuid primary key default gen_random_uuid(),
  slug text not null,
  term_vn text not null,
  term_en text not null,
  short_definition text not null default '',
  full_explanation text not null default '',
  practical_meaning text not null default '',
  risk_note text,
  eli5 text not null default '',
  law_reference text,
  related_term_slugs text[] not null default '{}',
  related_lesson_slugs text[] not null default '{}',
  category text not null check (
    category in ('financial', 'technical', 'legal', 'process', 'compliance')
  ),
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists idx_glossary_slug_unique
  on public.glossary_terms (slug);

create index if not exists idx_glossary_slug
  on public.glossary_terms (slug);

create index if not exists idx_glossary_category
  on public.glossary_terms (category);

create index if not exists idx_glossary_fts
  on public.glossary_terms
  using gin (
    to_tsvector(
      'simple',
      coalesce(term_vn, '') || ' ' ||
      coalesce(term_en, '') || ' ' ||
      coalesce(short_definition, '')
    )
  );

drop trigger if exists set_glossary_terms_updated_at on public.glossary_terms;
create trigger set_glossary_terms_updated_at
  before update on public.glossary_terms
  for each row
  execute function public.set_updated_at();

alter table public.glossary_terms enable row level security;

grant select on public.glossary_terms to anon, authenticated;
grant all on public.glossary_terms to service_role;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'glossary_terms'
      and policyname = 'Published glossary terms are readable'
  ) then
    create policy "Published glossary terms are readable"
      on public.glossary_terms
      for select
      to anon, authenticated
      using (is_published = true);
  end if;
end;
$$;

-- ============================================================
-- AI USAGE LOG
-- Used by:
-- - src/lib/ai/claude.ts logAIUsage()
-- ============================================================

create table if not exists public.ai_usage_log (
  id uuid primary key default gen_random_uuid(),
  feature text not null,
  ai_model text not null,
  input_tokens integer not null default 0 check (input_tokens >= 0),
  output_tokens integer not null default 0 check (output_tokens >= 0),
  cost_usd numeric(12, 6) not null default 0 check (cost_usd >= 0),
  created_at timestamptz not null default now()
);

create index if not exists idx_ai_usage_log_created_at
  on public.ai_usage_log (created_at desc);

create index if not exists idx_ai_usage_log_feature
  on public.ai_usage_log (feature);

alter table public.ai_usage_log enable row level security;

grant insert on public.ai_usage_log to anon, authenticated;
grant all on public.ai_usage_log to service_role;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'ai_usage_log'
      and policyname = 'AI usage can be logged'
  ) then
    create policy "AI usage can be logged"
      on public.ai_usage_log
      for insert
      to anon, authenticated
      with check (true);
  end if;
end;
$$;

-- ============================================================
-- USER LESSON PROGRESS
-- Used by:
-- - getUserLessonProgress()
-- - upsertLessonProgress()
-- ============================================================

create table if not exists public.user_lesson_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  lesson_id uuid not null references public.lessons (id) on delete cascade,
  status text not null default 'not_started' check (
    status in ('not_started', 'in_progress', 'completed')
  ),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_lesson_progress_user_id_lesson_id_key unique (user_id, lesson_id)
);

create index if not exists idx_user_lesson_progress_user_id
  on public.user_lesson_progress (user_id);

create index if not exists idx_user_lesson_progress_lesson_id
  on public.user_lesson_progress (lesson_id);

drop trigger if exists set_user_lesson_progress_updated_at
  on public.user_lesson_progress;
create trigger set_user_lesson_progress_updated_at
  before update on public.user_lesson_progress
  for each row
  execute function public.set_updated_at();

alter table public.user_lesson_progress enable row level security;

grant select, insert, update, delete on public.user_lesson_progress to authenticated;
grant all on public.user_lesson_progress to service_role;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'user_lesson_progress'
      and policyname = 'Users can read their own lesson progress'
  ) then
    create policy "Users can read their own lesson progress"
      on public.user_lesson_progress
      for select
      to authenticated
      using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'user_lesson_progress'
      and policyname = 'Users can insert their own lesson progress'
  ) then
    create policy "Users can insert their own lesson progress"
      on public.user_lesson_progress
      for insert
      to authenticated
      with check (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'user_lesson_progress'
      and policyname = 'Users can update their own lesson progress'
  ) then
    create policy "Users can update their own lesson progress"
      on public.user_lesson_progress
      for update
      to authenticated
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'user_lesson_progress'
      and policyname = 'Users can delete their own lesson progress'
  ) then
    create policy "Users can delete their own lesson progress"
      on public.user_lesson_progress
      for delete
      to authenticated
      using (auth.uid() = user_id);
  end if;
end;
$$;
