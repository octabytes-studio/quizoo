-- ============================================================================
-- 20260910090100_multilingual_content_model.sql
-- (renamed from 0004_multilingual_content_model.sql — see plan
-- .claude/plans/007-difficulty-ladder-language-question-bank.md, Phase 0)
--
-- Change Request: fully independent per-language categories / subcategories /
-- questions -- NOT a shared taxonomy translated via join tables. Each
-- language maintains its own categories, subcategories and questions; nothing
-- here auto-translates content.
--
-- Depends on: 20260910090000_difficulty_ladder_v2.sql (difficulty_tiers must
-- exist).
--
-- Fixes applied on top of the original draft (plan 007, Research findings):
--   - Filename reordered so it sorts after the base schema (finding #1).
--   - Added `questions.prompt` (finding #2), and — beyond what the prompt
--     column alone needs — a full backfill of prompt/options/correct_index/
--     explanation from question_i18n, since a question row with only a
--     prompt and no options/correct_index still cannot be served by the
--     rewritten start_level_attempt.
--   - The questions_status_check `do $$` block is left as originally
--     drafted, deliberately inert (finding #4) — see the comment at that
--     block below.
--   - NEW finding, not in the original plan research: `categories.slug` and
--     `subcategories.slug` each already carry an inline `unique` constraint
--     from the base schema (`categories_slug_key`, `subcategories_slug_key`)
--     that this migration's new compound constraints do not supersede —
--     confirmed live via `select conname, pg_get_constraintdef(oid) from
--     pg_constraint where conrelid in ('categories'::regclass,
--     'subcategories'::regclass) and contype = 'u'`. Left in place, the very
--     first non-English category/subcategory sharing an English slug (e.g.
--     a `ur` "science" next to the `en` "science" — exactly what this
--     migration's own multi-locale split below needs to create) would fail
--     with a duplicate-key error. Dropped below, in favour of the
--     language-scoped compound constraints this migration already adds for
--     categories, and a new `(category_id, slug)` constraint for
--     subcategories (subcategories have no language_code of their own —
--     language is inherited via category_id, so scoping uniqueness to the
--     parent category is the correct equivalent).
--   - Assumption #3's pre-check (`select question_id, count(*) from
--     question_i18n group by question_id having count(*) > 1`) was run
--     against the live project: it found exactly one row — question
--     00000000-0000-4000-8000-0000000a0001, the seeded Urdu solar-system
--     demo question (matching Flutter's `MockQuestions.urduSample`) — not
--     zero. Per the plan's hard gate, this is handled explicitly below
--     rather than skipped: the question's `en` row is covered by the normal
--     single-language backfill (it matches the row's own backfilled
--     language_code), and its `ur` row is split into a NEW questions row
--     under a new `ur`-owned twin of the Science category / Solar System
--     subcategory, since the new per-language model has no other way to let
--     one row serve two languages. Written as a loop over ANY question with
--     a secondary-locale row (not a hardcoded id), so this stays correct if
--     a future reseed adds more such rows — but every row it finds today is
--     this one.
-- ============================================================================

begin;

create table if not exists languages (
  code        text primary key,        -- ISO 639-1: 'en', 'ur', 'hi', 'ar', 'fr', 'es'
  name        text not null,           -- English name, e.g. 'Urdu'
  native_name text not null,           -- e.g. 'اردو'
  is_rtl      boolean not null default false,
  is_active   boolean not null default false,
  sort_order  int not null default 0
);

insert into languages (code, name, native_name, is_rtl, is_active, sort_order) values
  ('en', 'English', 'English',  false, true,  1),
  ('ur', 'Urdu',    'اردو',     true,  true,  2),
  ('hi', 'Hindi',   'हिन्दी',    false, false, 3),
  ('ar', 'Arabic',  'العربية',  true,  false, 4),
  ('fr', 'French',  'Français', false, false, 5),
  ('es', 'Spanish', 'Español',  false, false, 6)
on conflict (code) do nothing;

-- ---------------------------------------------------------------------------
-- categories: scoped to a single language (not translated -- OWNED by it)
-- ---------------------------------------------------------------------------
alter table categories add column if not exists language_code text;
update categories set language_code = 'en' where language_code is null;
alter table categories alter column language_code set not null;

do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'categories_language_fk') then
    alter table categories add constraint categories_language_fk
      foreign key (language_code) references languages(code);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'categories_language_slug_unique') then
    alter table categories add constraint categories_language_slug_unique unique (language_code, slug);
  end if;
end $$;

-- New finding (see header): the base schema's own single-column `unique` on
-- `slug` still applies even after the compound constraint above is added,
-- and blocks any second language from ever using an English category's
-- slug. Superseded by categories_language_slug_unique.
alter table categories drop constraint if exists categories_slug_key;

-- ---------------------------------------------------------------------------
-- subcategories: language is inherited via category_id -> categories.language_code
-- (no separate language_code column here -- one join keeps it impossible for
-- a subcategory to disagree with its own category about which language it's in)
-- ---------------------------------------------------------------------------
alter table subcategories add column if not exists ai_generation_allowed boolean not null default true;

-- Same finding as categories, applied to subcategories: the base schema's
-- global `unique (slug)` is superseded by a `(category_id, slug)` scoping —
-- the correct equivalent here, since a subcategory's language comes from its
-- category_id rather than a column of its own.
alter table subcategories drop constraint if exists subcategories_slug_key;
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'subcategories_category_slug_unique') then
    alter table subcategories add constraint subcategories_category_slug_unique unique (category_id, slug);
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- questions: each row IS the content for exactly one language -- not a
-- translation of a shared row. Replaces the old questions + question_i18n
-- pairing for all NEW content going forward.
-- ---------------------------------------------------------------------------
alter table questions add column if not exists language_code       text;
alter table questions add column if not exists difficulty_tier_id  uuid references difficulty_tiers(id);
alter table questions add column if not exists status              text not null default 'live';
alter table questions add column if not exists source              text not null default 'manual';
alter table questions add column if not exists kind                text not null default 'text';
alter table questions add column if not exists options             jsonb;
alter table questions add column if not exists correct_index       smallint;
alter table questions add column if not exists explanation         text;
-- Finding #2: get_level_questions()/start_level_attempt need the prompt text
-- itself on `questions`, not just the columns above.
alter table questions add column if not exists prompt              text;

do $$ begin
  -- Finding #4: this table's base-schema inline check already auto-named
  -- itself `questions_status_check` (Postgres's default single-column
  -- check-constraint name), so this guard finds it and skips — deliberately
  -- left as a no-op. The vocabulary stays ('draft','live','suspended');
  -- 'retired' is never introduced, since nothing downstream needs it and the
  -- smaller diff is preferred. Do not "fix" this into actually running —
  -- doing so would drop the existing 'suspended' value out from under any
  -- row already using it.
  if not exists (select 1 from pg_constraint where conname = 'questions_status_check') then
    alter table questions add constraint questions_status_check
      check (status in ('draft','live','retired'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'questions_source_check') then
    alter table questions add constraint questions_source_check
      check (source in ('manual','ai_batch','legacy_migrated'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'questions_correct_index_check') then
    alter table questions add constraint questions_correct_index_check
      check (correct_index between 0 and 3);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'questions_options_check') then
    -- Four options, or three for an image question -- the media plate takes
    -- the room the fourth would need (Question.options' own doc comment,
    -- question.dart). A flat "= 4" rejects every real image question live
    -- today (confirmed against this project's actual seed data).
    alter table questions add constraint questions_options_check
      check (
        options is null
        or jsonb_array_length(options) = case when kind = 'image' then 3 else 4 end
      );
  end if;
end $$;

-- Backfill language_code from the question's subcategory -> category chain
update questions q
set language_code = c.language_code
from subcategories sc join categories c on c.id = sc.category_id
where q.subcategory_id = sc.id and q.language_code is null;

-- Finding #2, extended: a question row also needs its actual content.
-- Backfilled from question_i18n for the row's OWN (just-backfilled) language
-- — a question with a second question_i18n row in a different locale is
-- deliberately excluded here (its own language's row still matches, so this
-- update only ever pulls in-language content) and handled by the dedicated
-- multi-locale block below instead.
update questions q
set prompt = qi.prompt,
    options = qi.options,
    correct_index = qi.correct_index,
    explanation = qi.explanation
from question_i18n qi
where qi.question_id = q.id
  and qi.locale = q.language_code
  and q.prompt is null;

-- Backfill difficulty_tier_id from the existing 1-5 integer `difficulty`
-- column (this schema's actual difficulty scale, not a hypothetical legacy
-- one -- the `if exists` guard is defensive against a schema where it was
-- since renamed/removed, not evidence it might not be there today).
do $$ begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'questions' and column_name = 'difficulty'
  ) then
    update questions q
    set difficulty_tier_id = dt.id
    from difficulty_tiers dt
    where q.difficulty_tier_id is null
      and dt.sort_order = least(greatest(q.difficulty::int, 1), 5);
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Assumption #3's multi-locale split (see header comment for the pre-check
-- result this responds to). For every question with a question_i18n row in a
-- locale other than its own (backfilled) language_code, create that
-- locale's twin category/subcategory (find-or-create, so re-running this
-- migration — or a second question needing the same twin — is idempotent)
-- and a brand-new questions row carrying that locale's content.
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
  v_orig_category record;
  v_orig_subcategory record;
  v_new_category_id uuid;
  v_new_subcategory_id uuid;
  v_new_question_id uuid;
begin
  for r in
    select qi.question_id, qi.locale, qi.prompt, qi.options, qi.correct_index,
           qi.explanation, q.subcategory_id, q.difficulty, q.kind, q.media_url,
           q.figure_svg, q.status
    from question_i18n qi
    join questions q on q.id = qi.question_id
    where qi.locale <> q.language_code
  loop
    select c.* into v_orig_category
      from subcategories sc join categories c on c.id = sc.category_id
      where sc.id = r.subcategory_id;
    select sc.* into v_orig_subcategory from subcategories sc where sc.id = r.subcategory_id;

    select id into v_new_category_id from categories
      where language_code = r.locale and slug = v_orig_category.slug;
    if v_new_category_id is null then
      insert into categories (slug, emoji, color_from, color_to, sort_order, is_active, language_code)
      values (v_orig_category.slug, v_orig_category.emoji, v_orig_category.color_from,
              v_orig_category.color_to, v_orig_category.sort_order, v_orig_category.is_active, r.locale)
      returning id into v_new_category_id;
    end if;

    select id into v_new_subcategory_id from subcategories
      where category_id = v_new_category_id and slug = v_orig_subcategory.slug;
    if v_new_subcategory_id is null then
      insert into subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
      values (v_new_category_id, v_orig_subcategory.slug, v_orig_subcategory.emoji,
              v_orig_subcategory.plate_color, v_orig_subcategory.group_name,
              v_orig_subcategory.sort_order, v_orig_subcategory.is_active)
      returning id into v_new_subcategory_id;
    end if;

    insert into questions (subcategory_id, kind, difficulty, media_url, figure_svg, status,
                            language_code, difficulty_tier_id, source, prompt, options,
                            correct_index, explanation)
    values (v_new_subcategory_id, r.kind, r.difficulty, r.media_url, r.figure_svg, r.status,
            r.locale,
            (select id from difficulty_tiers where sort_order = least(greatest(r.difficulty, 1), 5)),
            'legacy_migrated', r.prompt, r.options, r.correct_index, r.explanation)
    returning id into v_new_question_id;

    raise notice 'multi-locale split: question % locale % -> new question % under subcategory % (%.%)',
      r.question_id, r.locale, v_new_question_id, v_new_subcategory_id, v_orig_category.slug, v_orig_subcategory.slug;
  end loop;
end $$;

-- Known-good translations for the specific twin entities the loop above
-- creates from the seeded Urdu solar-system demo question — not a generic
-- auto-translation mechanism, just naming the one real case found live so it
-- doesn't fall back to an English slug in the picker/category screens.
insert into taxonomy_i18n (entity_type, entity_id, locale, name)
select 'category', c.id, 'ur', 'سائنس'
from categories c
where c.language_code = 'ur' and c.slug = 'science'
on conflict do nothing;

insert into taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', sc.id, 'ur', 'نظامِ شمسی'
from subcategories sc join categories c on c.id = sc.category_id
where c.language_code = 'ur' and sc.slug = 'solar-system'
on conflict do nothing;

-- Only enforce NOT NULL once backfilled -- if some questions still have no
-- resolvable subcategory/category chain, this will fail loudly rather than
-- silently leaving orphaned rows. Fix those rows manually first if it does.
alter table questions alter column language_code set not null;

do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'questions_language_fk') then
    alter table questions add constraint questions_language_fk
      foreign key (language_code) references languages(code);
  end if;
end $$;

-- Integrity guard: a question's language_code must always match the language
-- of its own subcategory's category (prevents an authoring mistake from ever
-- putting, say, a French question under an English subcategory).
create or replace function public.enforce_question_language_match()
returns trigger language plpgsql as $$
declare v_cat_lang text;
begin
  select c.language_code into v_cat_lang
  from subcategories sc join categories c on c.id = sc.category_id
  where sc.id = new.subcategory_id;

  if v_cat_lang is not null and v_cat_lang <> new.language_code then
    raise exception 'question language_code (%) does not match its subcategory''s language (%)',
      new.language_code, v_cat_lang;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_enforce_question_language_match on questions;
create trigger trg_enforce_question_language_match
  before insert or update of language_code, subcategory_id on questions
  for each row execute function public.enforce_question_language_match();

create index if not exists idx_questions_pool_lookup
  on questions (subcategory_id, difficulty_tier_id, language_code, status);

commit;

-- ============================================================================
-- OPTIONAL: materializing existing translated content out of taxonomy_i18n /
-- question_i18n (the OLD shared-taxonomy model), if your live project already
-- has real Urdu content sitting there from before this change.
--
-- This is deliberately NOT done automatically above, beyond the one
-- multi-locale question already handled by the block earlier in this file.
-- If a future reseed introduces more translated rows in these tables, re-run
-- the Assumption #3 pre-check query and extend that block rather than
-- guessing a bulk migration here.
-- ============================================================================
do $$
begin
  if to_regclass('public.taxonomy_i18n') is not null then
    raise notice 'taxonomy_i18n exists in this database -- see the OPTIONAL block at the bottom of this file before deciding whether to materialize additional per-language rows from it.';
  end if;
  if to_regclass('public.question_i18n') is not null then
    raise notice 'question_i18n exists in this database -- same note as above, for question content.';
  end if;
end $$;
