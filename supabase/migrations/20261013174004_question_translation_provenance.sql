-- ============================================================================
-- 20261013223938_question_translation_provenance.sql
--
-- Plan: .claude/plans/024-ar-fr-question-translation.md (Phase 0)
--
-- Arabic (`ar`) and French (`fr`) are active languages with full taxonomies
-- but zero questions. Rather than authoring ~10k+ brand-new rows per language,
-- plan 024 translates existing live questions from `en`/`es`/`hi`/`ur` into
-- them. This additive migration gives those translated rows provenance:
--
--   * questions.translated_from -> questions.id (nullable, on delete set null):
--     the source row a translated row was re-expressed from.
--   * uq_questions_translation_target: a partial unique index on
--     (translated_from, language_code) so one source row is translated at most
--     once per target language (idempotent re-runs; the same source row may
--     still be translated into both `ar` and `fr`).
--   * idx_questions_translated_from: cheap progress/audit lookups.
--   * widen questions_source_check to accept the new 'translated' value.
--
-- Additive and safe: existing rows keep translated_from = null and their
-- current source value. Nothing in the app reads this column (questions are
-- served through start_level_attempt / daily / duel RPCs that select named
-- columns), so no Flutter or Edge Function change is needed.
--
-- Rollback: drop the two indexes, drop the column, and restore the 3-value
-- questions_source_check. Not required for correctness (additive).
--
-- Never `supabase db push` -- apply via MCP apply_migration or
-- `supabase db query --linked -f`, matching plans 007/017/020/023.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- A. Provenance column.
-- ----------------------------------------------------------------------------
alter table public.questions
  add column if not exists translated_from uuid
    references public.questions(id) on delete set null;

comment on column public.questions.translated_from is
  'Source question this row was translated from (null for non-translations).';

-- ----------------------------------------------------------------------------
-- B. Idempotency guard: one source row -> at most one translation per target
--    language. (The same source row may be translated into both ar and fr.)
-- ----------------------------------------------------------------------------
create unique index if not exists uq_questions_translation_target
  on public.questions (translated_from, language_code)
  where translated_from is not null;

create index if not exists idx_questions_translated_from
  on public.questions (translated_from)
  where translated_from is not null;

-- ----------------------------------------------------------------------------
-- C. Widen the source vocabulary so translations are queryable as such.
-- ----------------------------------------------------------------------------
do $$ begin
  if exists (select 1 from pg_constraint where conname = 'questions_source_check') then
    alter table public.questions drop constraint questions_source_check;
  end if;
  alter table public.questions add constraint questions_source_check
    check (source in ('manual','ai_batch','legacy_migrated','translated'));
end $$;

commit;
