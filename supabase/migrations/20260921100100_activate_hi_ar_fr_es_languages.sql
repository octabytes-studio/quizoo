-- Activate hi/ar/fr/es now that their category/subcategory taxonomies exist
-- (see 20260921100000_expand_multilingual_category_taxonomy.sql).
--
-- NOTE: these languages have zero authored questions in any subcategory at the
-- time of this migration -- activated ahead of content per explicit request,
-- overriding the taxonomy-expansion plan's default recommendation to gate
-- activation on question volume (v_thin_question_pools). Prioritize running
-- /generate-questions per subcategory soon after this lands.

update public.languages
set is_active = true
where code in ('hi', 'ar', 'fr', 'es');
