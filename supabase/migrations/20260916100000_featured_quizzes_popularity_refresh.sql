-- ============================================================================
-- Featured quizzes: real, trailing-7-day popularity, refreshed on a schedule.
--
-- `featured_quizzes` (HomeContent.popular) is hand-curated editorial content
-- by design -- which subcategory gets featured, its title, emoji and
-- gradient are marketing decisions a job shouldn't invent (see the [APP]
-- comment on the table's own definition in 20260907120000_initial_schema.sql).
-- What a job CAN own honestly is the numbers: played_count and is_hot are
-- derived here from real `level_attempts` in the trailing week, the same
-- `security definer` + `pg_cron` pattern as `_daily_rollover` /
-- `_refresh_leaderboards` (20260907120200_functions_and_triggers.sql).
--
-- `greatest(played_count, <real count>)` rather than a flat overwrite: a
-- pre-launch row's seeded count is a floor. With near-zero real traffic
-- today this job is a no-op on played_count; once genuine weekly play volume
-- for a subcategory exceeds the seed, the real number takes over and only
-- ever grows from there -- it never regresses a card back toward zero.
-- ============================================================================

create or replace function public._refresh_featured_quizzes_popularity()
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  update public.featured_quizzes fq
  set played_count = greatest(fq.played_count, coalesce(counts.recent, 0))
  from (
    select subcategory_id, count(*) as recent
    from public.level_attempts
    where created_at >= now() - interval '7 days'
    group by subcategory_id
  ) counts
  where counts.subcategory_id = fq.subcategory_id;

  -- Hot badge follows the real ranking, not manual curation: the two
  -- highest played_count rows among active cards wear it.
  update public.featured_quizzes fq
  set is_hot = (ranked.rnk <= 2)
  from (
    select id, rank() over (order by played_count desc) as rnk
    from public.featured_quizzes
    where is_active
  ) ranked
  where ranked.id = fq.id;
end;
$$;

select cron.schedule(
  'refresh-featured-quizzes',
  '0 * * * *', -- hourly; cheap update over a small curated set
  $$select public._refresh_featured_quizzes_popularity();$$
);

-- Run once now so the seeded rows' is_hot already reflects the real ranking
-- instead of waiting for the first scheduled tick.
select public._refresh_featured_quizzes_popularity();
