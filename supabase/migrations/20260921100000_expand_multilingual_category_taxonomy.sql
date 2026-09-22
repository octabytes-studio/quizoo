-- Expand multilingual category/subcategory taxonomy.
--
-- Data-only migration (no DDL). Per plan
-- .claude/plans/016-multilingual-category-taxonomy-expansion.md:
--   - Urdu (ur): expand from 1 category to 8, fix a pre-existing group_name typo.
--   - Hindi (hi), Arabic (ar), French (fr), Spanish (es): new taxonomies from scratch.
--
-- languages.is_active is intentionally left untouched for hi/ar/fr/es (see plan
-- "Risks & rollout notes") -- these rows are inert until a follow-up flips them on
-- once question content exists.
--
-- Every insert is idempotent (on conflict do nothing against the schema's own
-- unique constraints), so re-running this file is safe.

begin;

-- =========================================================================
-- URDU (ur) -- expand from 1 category to 8
-- =========================================================================

-- Phase 1a: corrective updates to the pre-existing ur/science category and its
-- ur/science/solar-system subcategory (idempotent via the group_name guard).
update public.categories
set sort_order = 0
where language_code = 'ur' and slug = 'science';

update public.subcategories s
set group_name = 'فلکیات'
from public.categories c
where s.category_id = c.id and c.language_code = 'ur' and c.slug = 'science'
  and s.slug = 'solar-system' and s.group_name = 'Astronomy';

-- New ur categories
insert into public.categories (slug, emoji, color_from, color_to, sort_order, is_active, language_code)
values
  ('sports', '⚽', '#FF8A24', '#FF3D6E', 1, true, 'ur'),
  ('general', '🌍', '#12C79B', '#7BE495', 2, true, 'ur'),
  ('iq', '🧠', '#7B4DFF', '#2BB3FF', 3, true, 'ur'),
  ('maths', '🔢', '#FFC61A', '#FF8A24', 4, true, 'ur'),
  ('islam', '🕌', '#12C79B', '#2BB3FF', 5, true, 'ur'),
  ('pakistan-south-asia', '🏔️', '#2E5C8A', '#12A594', 6, true, 'ur'),
  ('urdu-literature', '📜', '#5C3A9E', '#B0479E', 7, true, 'ur')
on conflict (language_code, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'category', c.id, 'ur', v.name
from public.categories c
join (values
  ('sports', 'کھیل'),
  ('general', 'عمومی معلومات'),
  ('iq', 'ذہانت'),
  ('maths', 'ریاضی'),
  ('islam', 'اسلام'),
  ('pakistan-south-asia', 'پاکستان اور جنوبی ایشیا'),
  ('urdu-literature', 'اردو ادب و شاعری')
) as v(slug, name) on v.slug = c.slug
where c.language_code = 'ur'
on conflict (entity_type, entity_id, locale) do nothing;

-- ur / science (existing category) -- add 4 new subcategories
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, v.group_name, v.sort_order, true
from public.categories c
cross join (values
  ('chemistry', '🧪', '#FFE4EC', 'طبیعی علوم', 1),
  ('biology', '🧬', '#E4F7F1', 'حیاتیاتی علوم', 2),
  ('stars-galaxies', '☀️', '#FFF4D6', 'فلکیات', 3),
  ('space-exploration', '🔭', '#EDE8FA', 'فلکیات', 4)
) as v(slug, emoji, plate_color, group_name, sort_order)
where c.language_code = 'ur' and c.slug = 'science'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ur', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('chemistry', 'کیمیا'),
  ('biology', 'حیاتیات'),
  ('stars-galaxies', 'ستارے اور کہکشائیں'),
  ('space-exploration', 'خلائی تحقیق')
) as v(slug, name)
where c.language_code = 'ur' and c.slug = 'science' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- ur / sports
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('cricket', '🏏', '#DDF1FF', 0),
  ('hockey', '🏒', '#E4F7F1', 1),
  ('squash', '🎾', '#FFF4D6', 2),
  ('kabaddi', '🤼', '#FFE9D6', 3),
  ('football', '⚽', '#FFE4EC', 4),
  ('olympics', '🏅', '#EDE8FA', 5)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'ur' and c.slug = 'sports'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ur', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('cricket', 'کرکٹ'),
  ('hockey', 'ہاکی'),
  ('squash', 'اسکواش'),
  ('kabaddi', 'کبڈی'),
  ('football', 'فٹبال'),
  ('olympics', 'اولمپکس')
) as v(slug, name)
where c.language_code = 'ur' and c.slug = 'sports' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- ur / general
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('capitals', '🏙️', '#EDE8FA', 0),
  ('movies', '🎬', '#FFE4EC', 1),
  ('flags', '🚩', '#DDF1FF', 2),
  ('world-facts', '🌍', '#FFE9D6', 3)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'ur' and c.slug = 'general'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ur', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('capitals', 'دارالحکومت'),
  ('movies', 'فلمیں'),
  ('flags', 'پرچم'),
  ('world-facts', 'عالمی حقائق')
) as v(slug, name)
where c.language_code = 'ur' and c.slug = 'general' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- ur / iq
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('creative-thinking', '💡', '#EDE8FA', 0),
  ('memory', '🧠', '#DDF1FF', 1),
  ('pattern-logic', '🧩', '#FFF4D6', 2)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'ur' and c.slug = 'iq'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ur', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('creative-thinking', 'تخلیقی سوچ'),
  ('memory', 'یادداشت'),
  ('pattern-logic', 'ترتیب اور منطق')
) as v(slug, name)
where c.language_code = 'ur' and c.slug = 'iq' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- ur / maths
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('number-theory', '➗', '#FFE9D6', 0),
  ('mental-maths', '🔢', '#FFF4D6', 1),
  ('geometry', '📐', '#E4F7F1', 2)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'ur' and c.slug = 'maths'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ur', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('number-theory', 'نظریہ اعداد'),
  ('mental-maths', 'ذہنی حساب'),
  ('geometry', 'ہندسہ')
) as v(slug, name)
where c.language_code = 'ur' and c.slug = 'maths' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- ur / islam
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('seerah', '🕌', '#E4F7F1', 0),
  ('islamic-history', '🏛️', '#FFF4D6', 1),
  ('quran-studies', '📖', '#EDE8FA', 2),
  ('rightly-guided-caliphs', '⭐', '#DDF1FF', 3)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'ur' and c.slug = 'islam'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ur', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('seerah', 'سیرت النبی ﷺ'),
  ('islamic-history', 'اسلامی تاریخ'),
  ('quran-studies', 'علومِ قرآن'),
  ('rightly-guided-caliphs', 'خلفائے راشدین')
) as v(slug, name)
where c.language_code = 'ur' and c.slug = 'islam' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- ur / pakistan-south-asia
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('history', '🏛️', '#FFE9D6', 0),
  ('geography', '🏔️', '#E4F7F1', 1),
  ('landmarks-tourism', '🕌', '#DDF1FF', 2),
  ('culture-traditions', '🎨', '#FFE4EC', 3),
  ('founders-leaders', '⭐', '#EDE8FA', 4)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'ur' and c.slug = 'pakistan-south-asia'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ur', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('history', 'تاریخِ پاکستان'),
  ('geography', 'جغرافیہ'),
  ('landmarks-tourism', 'یادگاریں اور سیاحت'),
  ('culture-traditions', 'ثقافت و روایات'),
  ('founders-leaders', 'بانیانِ پاکستان')
) as v(slug, name)
where c.language_code = 'ur' and c.slug = 'pakistan-south-asia' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- ur / urdu-literature
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('urdu-poets', '✒️', '#FFF4D6', 0),
  ('ghazal-nazm', '📜', '#EDE8FA', 1),
  ('classical-literature', '📚', '#E4F7F1', 2),
  ('idioms-proverbs', '💬', '#FFE9D6', 3),
  ('novel-short-story', '📖', '#DDF1FF', 4)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'ur' and c.slug = 'urdu-literature'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ur', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('urdu-poets', 'شعرائے اردو'),
  ('ghazal-nazm', 'غزل اور نظم'),
  ('classical-literature', 'کلاسیکی ادب'),
  ('idioms-proverbs', 'محاورے اور ضرب الامثال'),
  ('novel-short-story', 'ناول و افسانہ')
) as v(slug, name)
where c.language_code = 'ur' and c.slug = 'urdu-literature' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- =========================================================================
-- HINDI (hi) -- new, 8 categories
-- =========================================================================

insert into public.categories (slug, emoji, color_from, color_to, sort_order, is_active, language_code)
values
  ('sports', '⚽', '#FF8A24', '#FF3D6E', 0, true, 'hi'),
  ('science', '🔬', '#2BB3FF', '#7B4DFF', 1, true, 'hi'),
  ('general', '🌍', '#12C79B', '#7BE495', 2, true, 'hi'),
  ('iq', '🧠', '#7B4DFF', '#2BB3FF', 3, true, 'hi'),
  ('maths', '🔢', '#FFC61A', '#FF8A24', 4, true, 'hi'),
  ('hinduism', '🕉️', '#FF9A3C', '#FFD166', 5, true, 'hi'),
  ('india-history-geography', '🏛️', '#D64550', '#F2A65A', 6, true, 'hi'),
  ('bollywood', '🎬', '#E0218A', '#FFB86B', 7, true, 'hi')
on conflict (language_code, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'category', c.id, 'hi', v.name
from public.categories c
join (values
  ('sports', 'खेल'),
  ('science', 'विज्ञान'),
  ('general', 'सामान्य ज्ञान'),
  ('iq', 'आईक्यू'),
  ('maths', 'गणित'),
  ('hinduism', 'हिंदू धर्म'),
  ('india-history-geography', 'भारत: इतिहास और भूगोल'),
  ('bollywood', 'बॉलीवुड')
) as v(slug, name) on v.slug = c.slug
where c.language_code = 'hi'
on conflict (entity_type, entity_id, locale) do nothing;

-- hi / sports
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('cricket', '🏏', '#DDF1FF', 0),
  ('football', '⚽', '#FFE9D6', 1),
  ('hockey', '🏑', '#E4F7F1', 2),
  ('kabaddi', '🤼', '#FFE4EC', 3),
  ('badminton', '🏸', '#FFF4D6', 4),
  ('olympics', '🏅', '#EDE8FA', 5)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'hi' and c.slug = 'sports'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'hi', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('cricket', 'क्रिकेट'),
  ('football', 'फुटबॉल'),
  ('hockey', 'हॉकी'),
  ('kabaddi', 'कबड्डी'),
  ('badminton', 'बैडमिंटन'),
  ('olympics', 'ओलंपिक')
) as v(slug, name)
where c.language_code = 'hi' and c.slug = 'sports' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- hi / science
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, v.group_name, v.sort_order, true
from public.categories c
cross join (values
  ('chemistry', '🧪', '#FFE4EC', 'भौतिक विज्ञान', 0),
  ('physics', '⚛️', '#FFE9D6', 'भौतिक विज्ञान', 1),
  ('biology', '🧬', '#E4F7F1', 'जीवन विज्ञान', 2),
  ('stars-galaxies', '☀️', '#FFF4D6', 'खगोल विज्ञान', 3),
  ('solar-system', '🪐', '#DDF1FF', 'खगोल विज्ञान', 4),
  ('space-exploration', '🔭', '#EDE8FA', 'खगोल विज्ञान', 5)
) as v(slug, emoji, plate_color, group_name, sort_order)
where c.language_code = 'hi' and c.slug = 'science'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'hi', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('chemistry', 'रसायन विज्ञान'),
  ('physics', 'भौतिक विज्ञान'),
  ('biology', 'जीव विज्ञान'),
  ('stars-galaxies', 'तारे और आकाशगंगाएँ'),
  ('solar-system', 'सौर मंडल'),
  ('space-exploration', 'अंतरिक्ष अन्वेषण')
) as v(slug, name)
where c.language_code = 'hi' and c.slug = 'science' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- hi / general
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('capitals', '🏙️', '#EDE8FA', 0),
  ('flags', '🚩', '#DDF1FF', 1),
  ('world-facts', '🌍', '#FFE9D6', 2),
  ('awards', '🏆', '#FFF4D6', 3)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'hi' and c.slug = 'general'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'hi', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('capitals', 'राजधानियाँ'),
  ('flags', 'झंडे'),
  ('world-facts', 'विश्व तथ्य'),
  ('awards', 'पुरस्कार और सम्मान')
) as v(slug, name)
where c.language_code = 'hi' and c.slug = 'general' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- hi / iq
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('lateral-thinking', '💡', '#EDE8FA', 0),
  ('memory', '🧠', '#DDF1FF', 1),
  ('pattern-logic', '🧩', '#FFF4D6', 2)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'hi' and c.slug = 'iq'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'hi', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('lateral-thinking', 'तार्किक चिंतन'),
  ('memory', 'स्मृति'),
  ('pattern-logic', 'पैटर्न तर्क')
) as v(slug, name)
where c.language_code = 'hi' and c.slug = 'iq' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- hi / maths
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('number-theory', '➗', '#FFE9D6', 0),
  ('mental-maths', '🔢', '#FFF4D6', 1),
  ('geometry', '📐', '#E4F7F1', 2)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'hi' and c.slug = 'maths'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'hi', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('number-theory', 'संख्या सिद्धांत'),
  ('mental-maths', 'मानसिक गणित'),
  ('geometry', 'ज्यामिति')
) as v(slug, name)
where c.language_code = 'hi' and c.slug = 'maths' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- hi / hinduism
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, v.group_name, v.sort_order, true
from public.categories c
cross join (values
  ('ramayana', '📜', '#FFE9D6', 'महाकाव्य', 0),
  ('mahabharata', '📜', '#EDE8FA', 'महाकाव्य', 1),
  ('festivals', '🪔', '#FFE4EC', '', 2),
  ('temples-architecture', '🛕', '#E4F7F1', '', 3),
  ('deities', '🙏', '#FFF4D6', '', 4),
  ('mythology', '📚', '#DDF1FF', '', 5)
) as v(slug, emoji, plate_color, group_name, sort_order)
where c.language_code = 'hi' and c.slug = 'hinduism'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'hi', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('ramayana', 'रामायण'),
  ('mahabharata', 'महाभारत'),
  ('festivals', 'हिंदू त्योहार'),
  ('temples-architecture', 'मंदिर और वास्तुकला'),
  ('deities', 'देवी-देवता'),
  ('mythology', 'पौराणिक कथाएँ')
) as v(slug, name)
where c.language_code = 'hi' and c.slug = 'hinduism' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- hi / india-history-geography
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, v.group_name, v.sort_order, true
from public.categories c
cross join (values
  ('ancient-india', '🏺', '#FFE9D6', 'इतिहास', 0),
  ('medieval-india', '🏰', '#EDE8FA', 'इतिहास', 1),
  ('freedom-struggle', '🇮🇳', '#FFE4EC', 'इतिहास', 2),
  ('indian-states-capitals', '🗺️', '#DDF1FF', 'भूगोल', 3),
  ('rivers-mountains', '🏔️', '#E4F7F1', 'भूगोल', 4),
  ('wildlife-national-parks', '🐯', '#FFF4D6', 'भूगोल', 5)
) as v(slug, emoji, plate_color, group_name, sort_order)
where c.language_code = 'hi' and c.slug = 'india-history-geography'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'hi', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('ancient-india', 'प्राचीन भारत'),
  ('medieval-india', 'मध्यकालीन भारत'),
  ('freedom-struggle', 'आधुनिक भारत और स्वतंत्रता संग्राम'),
  ('indian-states-capitals', 'भारतीय राज्य और राजधानियाँ'),
  ('rivers-mountains', 'नदियाँ और पर्वत'),
  ('wildlife-national-parks', 'वन्यजीव और राष्ट्रीय उद्यान')
) as v(slug, name)
where c.language_code = 'hi' and c.slug = 'india-history-geography' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- hi / bollywood
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('bollywood-films', '🎬', '#FFE4EC', 0),
  ('bollywood-songs', '🎵', '#FFF4D6', 1),
  ('actors-actresses', '🌟', '#EDE8FA', 2),
  ('classic-cinema', '🎞️', '#E4F7F1', 3),
  ('film-awards', '🏆', '#DDF1FF', 4)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'hi' and c.slug = 'bollywood'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'hi', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('bollywood-films', 'बॉलीवुड फ़िल्में'),
  ('bollywood-songs', 'बॉलीवुड गाने'),
  ('actors-actresses', 'अभिनेता और अभिनेत्रियाँ'),
  ('classic-cinema', 'क्लासिक हिंदी सिनेमा'),
  ('film-awards', 'फ़िल्म पुरस्कार')
) as v(slug, name)
where c.language_code = 'hi' and c.slug = 'bollywood' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- =========================================================================
-- ARABIC (ar) -- new, 7 categories
-- =========================================================================

insert into public.categories (slug, emoji, color_from, color_to, sort_order, is_active, language_code)
values
  ('sports', '⚽', '#FF8A24', '#FF3D6E', 0, true, 'ar'),
  ('science', '🔬', '#2BB3FF', '#7B4DFF', 1, true, 'ar'),
  ('general', '🌍', '#12C79B', '#7BE495', 2, true, 'ar'),
  ('iq', '🧠', '#7B4DFF', '#2BB3FF', 3, true, 'ar'),
  ('maths', '🔢', '#FFC61A', '#FF8A24', 4, true, 'ar'),
  ('islam', '🕌', '#12C79B', '#2BB3FF', 5, true, 'ar'),
  ('arab-heritage', '🏛️', '#8C5A2B', '#E8B94E', 6, true, 'ar')
on conflict (language_code, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'category', c.id, 'ar', v.name
from public.categories c
join (values
  ('sports', 'رياضة'),
  ('science', 'العلوم'),
  ('general', 'معلومات عامة'),
  ('iq', 'الذكاء'),
  ('maths', 'الرياضيات'),
  ('islam', 'الإسلام'),
  ('arab-heritage', 'التاريخ والحضارة العربية')
) as v(slug, name) on v.slug = c.slug
where c.language_code = 'ar'
on conflict (entity_type, entity_id, locale) do nothing;

-- ar / sports
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('football', '⚽', '#FFE9D6', 0),
  ('handball', '🤾', '#E4F7F1', 1),
  ('basketball', '🏀', '#FFE4EC', 2),
  ('volleyball', '🏐', '#FFF4D6', 3),
  ('tennis', '🎾', '#EDE8FA', 4),
  ('boxing-mma', '🥊', '#DDF1FF', 5),
  ('formula1', '🏎️', '#FFE9D6', 6),
  ('olympics', '🏅', '#E4F7F1', 7)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'ar' and c.slug = 'sports'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ar', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('football', 'كرة القدم'),
  ('handball', 'كرة اليد'),
  ('basketball', 'كرة السلة'),
  ('volleyball', 'الكرة الطائرة'),
  ('tennis', 'التنس'),
  ('boxing-mma', 'الملاكمة والفنون القتالية'),
  ('formula1', 'سباقات الفورمولا 1'),
  ('olympics', 'الألعاب الأولمبية')
) as v(slug, name)
where c.language_code = 'ar' and c.slug = 'sports' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- ar / science
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, v.group_name, v.sort_order, true
from public.categories c
cross join (values
  ('chemistry', '🧪', '#FFE4EC', 'العلوم الطبيعية', 0),
  ('biology', '🧬', '#E4F7F1', 'العلوم الحيوية', 1),
  ('stars-galaxies', '☀️', '#FFF4D6', 'علم الفلك', 2),
  ('solar-system', '🪐', '#DDF1FF', 'علم الفلك', 3),
  ('space-exploration', '🔭', '#EDE8FA', 'علم الفلك', 4)
) as v(slug, emoji, plate_color, group_name, sort_order)
where c.language_code = 'ar' and c.slug = 'science'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ar', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('chemistry', 'الكيمياء'),
  ('biology', 'علم الأحياء'),
  ('stars-galaxies', 'النجوم والمجرات'),
  ('solar-system', 'النظام الشمسي'),
  ('space-exploration', 'استكشاف الفضاء')
) as v(slug, name)
where c.language_code = 'ar' and c.slug = 'science' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- ar / general
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('capitals', '🏙️', '#EDE8FA', 0),
  ('movies', '🎬', '#FFE4EC', 1),
  ('flags', '🚩', '#DDF1FF', 2),
  ('world-facts', '🌍', '#FFE9D6', 3),
  ('inventions-discoveries', '💡', '#FFF4D6', 4)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'ar' and c.slug = 'general'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ar', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('capitals', 'العواصم'),
  ('movies', 'الأفلام'),
  ('flags', 'الأعلام'),
  ('world-facts', 'حقائق عالمية'),
  ('inventions-discoveries', 'الاختراعات والاكتشافات')
) as v(slug, name)
where c.language_code = 'ar' and c.slug = 'general' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- ar / iq
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('lateral-thinking', '💡', '#EDE8FA', 0),
  ('memory', '🧠', '#DDF1FF', 1),
  ('pattern-logic', '🧩', '#FFF4D6', 2)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'ar' and c.slug = 'iq'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ar', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('lateral-thinking', 'التفكير الجانبي'),
  ('memory', 'الذاكرة'),
  ('pattern-logic', 'الألغاز المنطقية')
) as v(slug, name)
where c.language_code = 'ar' and c.slug = 'iq' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- ar / maths
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('number-theory', '➗', '#FFE9D6', 0),
  ('mental-maths', '🔢', '#FFF4D6', 1),
  ('geometry', '📐', '#E4F7F1', 2)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'ar' and c.slug = 'maths'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ar', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('number-theory', 'نظرية الأعداد'),
  ('mental-maths', 'الحساب الذهني'),
  ('geometry', 'الهندسة')
) as v(slug, name)
where c.language_code = 'ar' and c.slug = 'maths' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- ar / islam
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('seerah', '🕌', '#E4F7F1', 0),
  ('islamic-history', '🏛️', '#FFF4D6', 1),
  ('quran', '📖', '#EDE8FA', 2),
  ('hadith', '📜', '#DDF1FF', 3),
  ('fiqh-worship', '🕋', '#FFE9D6', 4),
  ('names-of-allah', '✨', '#FFE4EC', 5)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'ar' and c.slug = 'islam'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ar', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('seerah', 'السيرة النبوية'),
  ('islamic-history', 'التاريخ الإسلامي'),
  ('quran', 'القرآن الكريم'),
  ('hadith', 'الحديث الشريف'),
  ('fiqh-worship', 'الفقه والعبادات'),
  ('names-of-allah', 'أسماء الله الحسنى')
) as v(slug, name)
where c.language_code = 'ar' and c.slug = 'islam' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- ar / arab-heritage
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, v.group_name, v.sort_order, true
from public.categories c
cross join (values
  ('islamic-golden-age', '📜', '#FFF4D6', 'الحضارة', 0),
  ('house-of-wisdom', '📚', '#DDF1FF', 'الحضارة', 1),
  ('abbasid-caliphate', '👑', '#EDE8FA', 'الحضارة', 2),
  ('andalusia', '🕌', '#FFE9D6', 'الحضارة', 3),
  ('middle-east-geography', '🗺️', '#E4F7F1', 'الجغرافيا', 4),
  ('arabic-poetry', '📖', '#FFE4EC', 'الأدب', 5),
  ('one-thousand-and-one-nights', '🏮', '#FFF4D6', 'الأدب', 6)
) as v(slug, emoji, plate_color, group_name, sort_order)
where c.language_code = 'ar' and c.slug = 'arab-heritage'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'ar', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('islamic-golden-age', 'العصر الذهبي الإسلامي'),
  ('house-of-wisdom', 'بيت الحكمة والعلماء'),
  ('abbasid-caliphate', 'الخلافة العباسية'),
  ('andalusia', 'الأندلس'),
  ('middle-east-geography', 'جغرافيا الشرق الأوسط'),
  ('arabic-poetry', 'الشعر العربي'),
  ('one-thousand-and-one-nights', 'ألف ليلة وليلة')
) as v(slug, name)
where c.language_code = 'ar' and c.slug = 'arab-heritage' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- =========================================================================
-- FRENCH (fr) -- new, 7 categories
-- =========================================================================

insert into public.categories (slug, emoji, color_from, color_to, sort_order, is_active, language_code)
values
  ('sports', '⚽', '#2E86FF', '#00C2A8', 0, true, 'fr'),
  ('science', '🔬', '#5B3DF6', '#22D3EE', 1, true, 'fr'),
  ('general', '🌍', '#16A34A', '#86EFAC', 2, true, 'fr'),
  ('iq', '🧠', '#7C3AED', '#38BDF8', 3, true, 'fr'),
  ('maths', '🔢', '#F59E0B', '#FB7185', 4, true, 'fr'),
  ('history-geography', '🏰', '#92400E', '#D97706', 5, true, 'fr'),
  ('christianity', '✝️', '#A16207', '#FDE68A', 6, true, 'fr')
on conflict (language_code, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'category', c.id, 'fr', v.name
from public.categories c
join (values
  ('sports', 'Sport'),
  ('science', 'Sciences'),
  ('general', 'Culture Générale'),
  ('iq', 'QI'),
  ('maths', 'Mathématiques'),
  ('history-geography', 'Histoire & Géographie'),
  ('christianity', 'Christianisme')
) as v(slug, name) on v.slug = c.slug
where c.language_code = 'fr'
on conflict (entity_type, entity_id, locale) do nothing;

-- fr / sports
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('football', '⚽', '#FFE9D6', 0),
  ('rugby', '🏉', '#E4F7F1', 1),
  ('cycling', '🚴', '#FFE4EC', 2),
  ('tennis', '🎾', '#FFF4D6', 3),
  ('olympics', '🏅', '#EDE8FA', 4),
  ('winter-sports', '⛷️', '#DDF1FF', 5),
  ('formula1', '🏎️', '#FFE9D6', 6),
  ('boxing-martial-arts', '🥊', '#E4F7F1', 7)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'fr' and c.slug = 'sports'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'fr', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('football', 'Football'),
  ('rugby', 'Rugby'),
  ('cycling', 'Cyclisme (Tour de France)'),
  ('tennis', 'Tennis'),
  ('olympics', 'Jeux Olympiques'),
  ('winter-sports', 'Ski & Sports d''Hiver'),
  ('formula1', 'Formule 1'),
  ('boxing-martial-arts', 'Boxe & Arts Martiaux')
) as v(slug, name)
where c.language_code = 'fr' and c.slug = 'sports' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- fr / science
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, v.group_name, v.sort_order, true
from public.categories c
cross join (values
  ('chemistry', '🧪', '#FFE4EC', 'Sciences physiques', 0),
  ('stars-galaxies', '☀️', '#FFF4D6', 'Astronomie', 1),
  ('biology', '🧬', '#E4F7F1', 'Sciences de la vie', 2),
  ('solar-system', '🪐', '#DDF1FF', 'Astronomie', 3),
  ('space-exploration', '🔭', '#EDE8FA', 'Astronomie', 4)
) as v(slug, emoji, plate_color, group_name, sort_order)
where c.language_code = 'fr' and c.slug = 'science'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'fr', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('chemistry', 'Chimie'),
  ('stars-galaxies', 'Étoiles & Galaxies'),
  ('biology', 'Biologie'),
  ('solar-system', 'Système Solaire'),
  ('space-exploration', 'Exploration Spatiale')
) as v(slug, name)
where c.language_code = 'fr' and c.slug = 'science' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- fr / general
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('movies', '🎬', '#FFE4EC', 0),
  ('capitals', '🏙️', '#EDE8FA', 1),
  ('flags', '🚩', '#DDF1FF', 2),
  ('world-facts', '🌍', '#FFE9D6', 3),
  ('gastronomy', '🍷', '#FFF4D6', 4),
  ('french-language', '📚', '#E4F7F1', 5)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'fr' and c.slug = 'general'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'fr', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('movies', 'Cinéma'),
  ('capitals', 'Capitales du Monde'),
  ('flags', 'Drapeaux'),
  ('world-facts', 'Faits Insolites'),
  ('gastronomy', 'Gastronomie Française'),
  ('french-language', 'Langue Française')
) as v(slug, name)
where c.language_code = 'fr' and c.slug = 'general' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- fr / iq
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('lateral-thinking', '💡', '#EDE8FA', 0),
  ('memory', '🧠', '#DDF1FF', 1),
  ('pattern-logic', '🧩', '#FFF4D6', 2)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'fr' and c.slug = 'iq'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'fr', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('lateral-thinking', 'Réflexion Latérale'),
  ('memory', 'Mémoire'),
  ('pattern-logic', 'Logique & Schémas')
) as v(slug, name)
where c.language_code = 'fr' and c.slug = 'iq' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- fr / maths
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('number-theory', '➗', '#FFE9D6', 0),
  ('mental-maths', '🔢', '#FFF4D6', 1),
  ('geometry', '📐', '#E4F7F1', 2)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'fr' and c.slug = 'maths'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'fr', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('number-theory', 'Théorie des Nombres'),
  ('mental-maths', 'Calcul Mental'),
  ('geometry', 'Géométrie')
) as v(slug, name)
where c.language_code = 'fr' and c.slug = 'maths' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- fr / history-geography
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('french-revolution', '⚔️', '#FFE9D6', 0),
  ('kings-and-queens', '👑', '#EDE8FA', 1),
  ('napoleon-empire', '🎖️', '#FFE4EC', 2),
  ('french-regions', '🏞️', '#E4F7F1', 3),
  ('paris-monuments', '🗼', '#DDF1FF', 4),
  ('european-geography', '🌍', '#FFF4D6', 5),
  ('francophonie', '🌐', '#EDE8FA', 6)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'fr' and c.slug = 'history-geography'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'fr', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('french-revolution', 'Révolution Française'),
  ('kings-and-queens', 'Rois & Reines de France'),
  ('napoleon-empire', 'Napoléon & l''Empire'),
  ('french-regions', 'Régions de France'),
  ('paris-monuments', 'Paris & ses Monuments'),
  ('european-geography', 'Géographie Européenne'),
  ('francophonie', 'La Francophonie')
) as v(slug, name)
where c.language_code = 'fr' and c.slug = 'history-geography' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- fr / christianity
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('biblical-literature', '📖', '#FFF4D6', 0),
  ('cathedrals-sacred-art', '⛪', '#E4F7F1', 1),
  ('christian-history-france', '✝️', '#EDE8FA', 2),
  ('saints-figures', '👤', '#FFE4EC', 3),
  ('christian-holidays', '🎄', '#DDF1FF', 4)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'fr' and c.slug = 'christianity'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'fr', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('biblical-literature', 'Bible & Littérature Biblique'),
  ('cathedrals-sacred-art', 'Cathédrales & Art Sacré'),
  ('christian-history-france', 'Histoire du Christianisme en France'),
  ('saints-figures', 'Grandes Figures Chrétiennes'),
  ('christian-holidays', 'Fêtes & Traditions Chrétiennes')
) as v(slug, name)
where c.language_code = 'fr' and c.slug = 'christianity' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- =========================================================================
-- SPANISH (es) -- new, 7 categories
-- =========================================================================

insert into public.categories (slug, emoji, color_from, color_to, sort_order, is_active, language_code)
values
  ('sports', '⚽', '#FF8A24', '#FF3D6E', 0, true, 'es'),
  ('science', '🔬', '#2BB3FF', '#7B4DFF', 1, true, 'es'),
  ('general', '🌍', '#12C79B', '#7BE495', 2, true, 'es'),
  ('iq', '🧠', '#7B4DFF', '#2BB3FF', 3, true, 'es'),
  ('maths', '🔢', '#FFC61A', '#FF8A24', 4, true, 'es'),
  ('christianity', '✝️', '#6D4AFF', '#FFB84D', 5, true, 'es'),
  ('hispanic-heritage', '🌎', '#E85D4C', '#F2C14E', 6, true, 'es')
on conflict (language_code, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'category', c.id, 'es', v.name
from public.categories c
join (values
  ('sports', 'Deportes'),
  ('science', 'Ciencia'),
  ('general', 'Cultura General'),
  ('iq', 'Ingenio'),
  ('maths', 'Matemáticas'),
  ('christianity', 'Cristianismo'),
  ('hispanic-heritage', 'Historia y Geografía Hispana')
) as v(slug, name) on v.slug = c.slug
where c.language_code = 'es'
on conflict (entity_type, entity_id, locale) do nothing;

-- es / sports
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('football', '⚽', '#FFE9D6', 0),
  ('baseball', '⚾', '#E4F7F1', 1),
  ('basketball', '🏀', '#FFE4EC', 2),
  ('tennis', '🎾', '#FFF4D6', 3),
  ('boxing-mma', '🥊', '#EDE8FA', 4),
  ('cycling', '🚴', '#DDF1FF', 5),
  ('olympics', '🏅', '#FFE9D6', 6)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'es' and c.slug = 'sports'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'es', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('football', 'Fútbol'),
  ('baseball', 'Béisbol'),
  ('basketball', 'Baloncesto'),
  ('tennis', 'Tenis'),
  ('boxing-mma', 'Boxeo y MMA'),
  ('cycling', 'Ciclismo'),
  ('olympics', 'Juegos Olímpicos')
) as v(slug, name)
where c.language_code = 'es' and c.slug = 'sports' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- es / science
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, v.group_name, v.sort_order, true
from public.categories c
cross join (values
  ('chemistry', '🧪', '#FFE4EC', 'Ciencias físicas', 0),
  ('stars-galaxies', '☀️', '#FFF4D6', 'Astronomía', 1),
  ('biology', '🧬', '#E4F7F1', 'Ciencias de la vida', 2),
  ('solar-system', '🪐', '#DDF1FF', 'Astronomía', 3),
  ('space-exploration', '🔭', '#EDE8FA', 'Astronomía', 4)
) as v(slug, emoji, plate_color, group_name, sort_order)
where c.language_code = 'es' and c.slug = 'science'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'es', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('chemistry', 'Química'),
  ('stars-galaxies', 'Estrellas y Galaxias'),
  ('biology', 'Biología'),
  ('solar-system', 'Sistema Solar'),
  ('space-exploration', 'Exploración Espacial')
) as v(slug, name)
where c.language_code = 'es' and c.slug = 'science' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- es / general
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('capitals', '🏙️', '#EDE8FA', 0),
  ('movies', '🎬', '#FFE4EC', 1),
  ('flags', '🚩', '#DDF1FF', 2),
  ('world-facts', '🌍', '#FFE9D6', 3),
  ('music', '🎵', '#FFF4D6', 4)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'es' and c.slug = 'general'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'es', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('capitals', 'Capitales'),
  ('movies', 'Cine'),
  ('flags', 'Banderas'),
  ('world-facts', 'Datos del Mundo'),
  ('music', 'Música')
) as v(slug, name)
where c.language_code = 'es' and c.slug = 'general' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- es / iq
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('lateral-thinking', '💡', '#EDE8FA', 0),
  ('memory', '🧠', '#DDF1FF', 1),
  ('pattern-logic', '🧩', '#FFF4D6', 2)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'es' and c.slug = 'iq'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'es', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('lateral-thinking', 'Pensamiento Lateral'),
  ('memory', 'Memoria'),
  ('pattern-logic', 'Lógica y Patrones')
) as v(slug, name)
where c.language_code = 'es' and c.slug = 'iq' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- es / maths
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('number-theory', '➗', '#FFE9D6', 0),
  ('mental-maths', '🔢', '#FFF4D6', 1),
  ('geometry', '📐', '#E4F7F1', 2)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'es' and c.slug = 'maths'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'es', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('number-theory', 'Teoría de Números'),
  ('mental-maths', 'Cálculo Mental'),
  ('geometry', 'Geometría')
) as v(slug, name)
where c.language_code = 'es' and c.slug = 'maths' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- es / christianity
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('christian-history', '📜', '#FFE9D6', 0),
  ('biblical-figures', '📖', '#EDE8FA', 1),
  ('cathedrals-sacred-art', '⛪', '#FFE4EC', 2),
  ('popes-and-church', '🏛️', '#FFF4D6', 3),
  ('holy-week-traditions', '🕯️', '#E4F7F1', 4)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'es' and c.slug = 'christianity'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'es', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('christian-history', 'Historia del Cristianismo'),
  ('biblical-figures', 'Figuras Bíblicas'),
  ('cathedrals-sacred-art', 'Arte y Catedrales'),
  ('popes-and-church', 'Papas y la Iglesia'),
  ('holy-week-traditions', 'Semana Santa y Tradiciones')
) as v(slug, name)
where c.language_code = 'es' and c.slug = 'christianity' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

-- es / hispanic-heritage
insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
select c.id, v.slug, v.emoji, v.plate_color, '', v.sort_order, true
from public.categories c
cross join (values
  ('ancient-civilizations', '🏺', '#DDF1FF', 0),
  ('independence-liberators', '🗽', '#FFE9D6', 1),
  ('spain-history-monuments', '🏰', '#EDE8FA', 2),
  ('latin-america-countries', '🗺️', '#FFE4EC', 3),
  ('nature-landscapes', '🏔️', '#E4F7F1', 4)
) as v(slug, emoji, plate_color, sort_order)
where c.language_code = 'es' and c.slug = 'hispanic-heritage'
on conflict (category_id, slug) do nothing;

insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
select 'subcategory', s.id, 'es', v.name
from public.subcategories s
join public.categories c on c.id = s.category_id
cross join (values
  ('ancient-civilizations', 'Civilizaciones Antiguas'),
  ('independence-liberators', 'Independencia y Libertadores'),
  ('spain-history-monuments', 'España: Historia y Monumentos'),
  ('latin-america-countries', 'Países y Capitales de Hispanoamérica'),
  ('nature-landscapes', 'Naturaleza y Paisajes')
) as v(slug, name)
where c.language_code = 'es' and c.slug = 'hispanic-heritage' and s.slug = v.slug
on conflict (entity_type, entity_id, locale) do nothing;

commit;
