# Multilingual Category & Subcategory Taxonomy Expansion

> Source spec: provided inline in conversation ("add more categories and subcategories [for] Urdu... [and] other languages which are not active yet... search the web for the interests of people living in the regions where those languages are spoken... introduce general categories... in each language which are globally general... each category and sub-category name must be written in the exact language").
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation history. Start
by reading it in full. Code may have moved on since it was written, so spot-check the
referenced files/schema still match before you begin — in particular, re-run the
"before you begin" queries in Implementation Steps, Phase 0, to confirm the live
`categories`/`subcategories` tables still look like the snapshot recorded below.

This plan produces **one SQL migration** (data only, no DDL) — no Flutter/Dart code
changes are required. `CatalogApi`, `LanguagesApi`, and `ContentLanguageApi` already
read `categories`/`subcategories`/`taxonomy_i18n`/`languages` dynamically and filter
by `language_code`/`is_active`, so newly inserted rows surface automatically once a
language is flipped active (see "Risks & rollout notes" — that flip is deliberately
**not** part of this plan).

## Objective

Quizoo's content model (migration `20260910090100_multilingual_content_model.sql`)
gives every language its own, independently-owned set of categories and
subcategories — never a shared taxonomy translated via a join table. Today:

- **English (`en`)**: 6 categories, 27 subcategories — the full, mature taxonomy.
- **Urdu (`ur`)**: 1 category (`science`), 1 subcategory (`solar-system`) — active,
  but极 thin.
- **Hindi (`hi`), Arabic (`ar`), French (`fr`), Spanish (`es`)**: rows exist in
  `languages` (seeded, `is_active = false`), but **zero** categories or
  subcategories — nothing for a player to see even if switched on.

This plan authors a full, research-grounded category/subcategory taxonomy for all
five of these languages: filling out Urdu to parity with English, and building
Hindi/Arabic/French/Spanish from scratch. Each language's taxonomy blends (a) the
same "globally general" categories English already has (Sports, Science, General
Knowledge, IQ, Maths — translated, not transliterated) with (b) categories genuinely
popular with that language's speaking region, identified via web research rather than
assumption (e.g. Hinduism/Indian Geography/Bollywood for Hindi; Islamic
history/Arab heritage for Arabic; Christianity/French history for French;
Christianity/pan-Hispanic history for Spanish; Pakistan & South Asia/Urdu literature
for Urdu).

## Scope

**In scope:**
- New `categories` rows for `ur` (additional categories), `hi`, `ar`, `fr`, `es`.
- New `subcategories` rows under every new/expanded category.
- New `taxonomy_i18n` rows giving every new category and subcategory its native-script
  display name (and native `group_name` values where used).
- Fixing one existing data inconsistency found during research: the live `ur`
  `solar-system` subcategory's `group_name` column literally stores the English word
  `"Astronomy"` (a leftover of the migration script that split it out of a shared
  `question_i18n` row) — corrected to `فلکیات` in the same migration, since this
  migration is already touching that row's siblings.
- Re-sequencing `ur`'s existing `science` category's `sort_order` (`1` → `0`) so it
  leads the newly-expanded Urdu category list — cosmetic only, doesn't change its
  identity/FKs.

**Out of scope (explicitly, see "Risks & rollout notes"):**
- **Actually writing quiz questions.** This plan creates the taxonomy (the "shelves"),
  not question content (the "books"). Authoring questions for each new subcategory is
  a separate, already-established workflow — the `/generate-questions` skill — run
  per subcategory afterward. `/generate-questions` itself explicitly refuses to run
  against a subcategory that doesn't exist yet, which is exactly the gap this plan
  closes.
- **Flipping `languages.is_active` to `true`** for `hi`/`ar`/`fr`/`es`. The original
  multilingual-content-model spec (`.claude/specs/quizoo-difficulty-language-questionbank-spec.md`,
  §11) is explicit that these should stay inactive "until real authored
  categories/subcategories/**questions** exist" — this plan only gets as far as
  categories/subcategories. Activation is a follow-up decision once enough question
  volume exists per new subcategory (the existing `v_thin_question_pools` view, from
  migration `20260910090200_question_bank_and_anti_repeat.sql`, is exactly the tool
  for judging "enough").
- Any Flutter/Dart code change. None is needed — see Objective.
- Any new database table, column, or constraint (pure data migration, no DDL beyond
  the two corrective `update` statements above).

## Research findings

Five parallel research passes (one per language) were run, each grounding its
category choices in actual web search results about that language's speaking
region — not just translated guesses. Full source citations are preserved in each
language's section below. Two cross-cutting findings came out of reconciling the five
passes against each other and against the live schema:

1. **Slug convention confirmed and enforced.** The live schema already establishes
   that `categories.slug`/`subcategories.slug` stay **ASCII, English-word
   identifiers** even for non-English rows — confirmed directly: the live Urdu
   `science` category has `slug = 'science'`, not a transliterated or Urdu-script
   slug; only its `taxonomy_i18n` row carries the Urdu display name (`سائنس`). The
   Spanish research pass drafted native-Spanish slugs (`quimica`, `sistema-solar`,
   `deportes`, ...) and the French pass used singular `sport` instead of `sports` —
   both **normalized to English-ASCII slugs** in the data tables below (e.g.
   `quimica` → `chemistry`, `deportes` → `sports`, `sport` → `sports`) to match the
   established convention and so the same underlying concept (e.g. "the Sports
   category") shares an identical slug across every language, which matters if any
   future tooling ever needs to look up "this concept, in every language" by slug.
   Native-script text lives **only** in `taxonomy_i18n.name` and (where used)
   `subcategories.group_name` — never in a `slug`.
2. **`group_name` must already be in the target language.** Unlike category/subcategory
   *names* (which come from `taxonomy_i18n`), `group_name` is a literal column on
   `subcategories` with no translation layer — confirmed by reading
   `lib/features/catalog/data/catalog_api.dart`, which renders it directly
   (`groupName: row['group_name']`). Every `group_name` value below is already
   supplied in the target language for this reason (and this is exactly the bug being
   fixed in the existing `ur` row — see Scope).

Religion categories appear in four of the five languages (`islam` for `ur`/`ar`,
`hinduism` for `hi`, `christianity` for `fr`/`es`) — mirroring the tone the project
already established for English's own `islam` category (Seerah/Islamic
History/Quran): every subcategory below is framed as neutral, historical/cultural/
textual general knowledge, never devotional instruction or sect-specific doctrine.
Each language's section flags its own specific sensitivity notes from that research
pass — these are notes for whoever reviews `/generate-questions` output against these
subcategories later, not something this plan (which writes no question content)
needs to act on itself.

---

### Urdu (`ur`) — expand from 1 category to 8

**Research grounding:** Pakistan-focused trivia sources (Water Cooler Trivia,
GKToday, PakMcqs) converge on history, geography (Indus River, K2, Karakoram
Highway, Mohenjo-daro), and Pakistan Studies exam topics — supporting a dedicated
Pakistan & South Asia category. Literature research confirms Ghalib, Iqbal, and Faiz
as the three pillars of Urdu literary culture, each with distinct enough form
(ghazal, philosophical/nationalist poetry, socialist verse) to support a standalone
Urdu Literature & Poetry category. Cricket, hockey, and squash (the Jahangir/Jansher
Khan era) carry the deepest regional sports cultural footprint, so Sports leads with
those rather than a flat EN mirror.

**Categories** (`language_code = 'ur'`):

| sort_order | slug | native name | emoji | color_from | color_to | note |
|---|---|---|---|---|---|---|
| 0 | `science` | سائنس | 🔬 | `#2BB3FF` | `#7B4DFF` | existing row — `sort_order` changes `1`→`0`; colors/emoji unchanged |
| 1 | `sports` | کھیل | ⚽ | `#FF8A24` | `#FF3D6E` | new |
| 2 | `general` | عمومی معلومات | 🌍 | `#12C79B` | `#7BE495` | new |
| 3 | `iq` | ذہانت | 🧠 | `#7B4DFF` | `#2BB3FF` | new |
| 4 | `maths` | ریاضی | 🔢 | `#FFC61A` | `#FF8A24` | new |
| 5 | `islam` | اسلام | 🕌 | `#12C79B` | `#2BB3FF` | new |
| 6 | `pakistan-south-asia` | پاکستان اور جنوبی ایشیا | 🏔️ | `#2E5C8A` | `#12A594` | new |
| 7 | `urdu-literature` | اردو ادب و شاعری | 📜 | `#5C3A9E` | `#B0479E` | new |

**Subcategories:**

`science` (existing category — add 4, plus fix the existing row's `group_name`):

| slug | native name | emoji | plate_color | group_name | sort_order | note |
|---|---|---|---|---|---|---|
| `solar-system` | نظامِ شمسی | 🪐 | `#DDF1FF` | `فلکیات` | 0 | **existing row — `update` its `group_name` from `"Astronomy"` to `فلکیات`, don't insert** |
| `chemistry` | کیمیا | 🧪 | `#FFE4EC` | `طبیعی علوم` | 1 | new |
| `biology` | حیاتیات | 🧬 | `#E4F7F1` | `حیاتیاتی علوم` | 2 | new |
| `stars-galaxies` | ستارے اور کہکشائیں | ☀️ | `#FFF4D6` | `فلکیات` | 3 | new |
| `space-exploration` | خلائی تحقیق | 🔭 | `#EDE8FA` | `فلکیات` | 4 | new |

`sports`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `cricket` | کرکٹ | 🏏 | `#DDF1FF` | 0 |
| `hockey` | ہاکی | 🏒 | `#E4F7F1` | 1 |
| `squash` | اسکواش | 🎾 | `#FFF4D6` | 2 |
| `kabaddi` | کبڈی | 🤼 | `#FFE9D6` | 3 |
| `football` | فٹبال | ⚽ | `#FFE4EC` | 4 |
| `olympics` | اولمپکس | 🏅 | `#EDE8FA` | 5 |

`general`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `capitals` | دارالحکومت | 🏙️ | `#EDE8FA` | 0 |
| `movies` | فلمیں | 🎬 | `#FFE4EC` | 1 |
| `flags` | پرچم | 🚩 | `#DDF1FF` | 2 |
| `world-facts` | عالمی حقائق | 🌍 | `#FFE9D6` | 3 |

`iq`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `creative-thinking` | تخلیقی سوچ | 💡 | `#EDE8FA` | 0 |
| `memory` | یادداشت | 🧠 | `#DDF1FF` | 1 |
| `pattern-logic` | ترتیب اور منطق | 🧩 | `#FFF4D6` | 2 |

`maths`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `number-theory` | نظریہ اعداد | ➗ | `#FFE9D6` | 0 |
| `mental-maths` | ذہنی حساب | 🔢 | `#FFF4D6` | 1 |
| `geometry` | ہندسہ | 📐 | `#E4F7F1` | 2 |

`islam` (⚠️ sensitivity — see note below):

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `seerah` | سیرت النبی ﷺ | 🕌 | `#E4F7F1` | 0 |
| `islamic-history` | اسلامی تاریخ | 🏛️ | `#FFF4D6` | 1 |
| `quran-studies` | علومِ قرآن | 📖 | `#EDE8FA` | 2 |
| `rightly-guided-caliphs` | خلفائے راشدین | ⭐ | `#DDF1FF` | 3 |

`pakistan-south-asia` (⚠️ sensitivity — see note below):

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `history` | تاریخِ پاکستان | 🏛️ | `#FFE9D6` | 0 |
| `geography` | جغرافیہ | 🏔️ | `#E4F7F1` | 1 |
| `landmarks-tourism` | یادگاریں اور سیاحت | 🕌 | `#DDF1FF` | 2 |
| `culture-traditions` | ثقافت و روایات | 🎨 | `#FFE4EC` | 3 |
| `founders-leaders` | بانیانِ پاکستان | ⭐ | `#EDE8FA` | 4 |

`urdu-literature`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `urdu-poets` | شعرائے اردو | ✒️ | `#FFF4D6` | 0 |
| `ghazal-nazm` | غزل اور نظم | 📜 | `#EDE8FA` | 1 |
| `classical-literature` | کلاسیکی ادب | 📚 | `#E4F7F1` | 2 |
| `idioms-proverbs` | محاورے اور ضرب الامثال | 💬 | `#FFE9D6` | 3 |
| `novel-short-story` | ناول و افسانہ | 📖 | `#DDF1FF` | 4 |

**Sensitivity notes for whoever authors questions here later:** `islam` — keep every
question historical/textual (dates, names, events, compilation history), never fiqh
rulings or sect-specific claims. `pakistan-south-asia`'s `founders-leaders` — restrict
to widely-uncontested pre-1971 founding-era facts, never contemporary politics or
active political parties.

---

### Hindi (`hi`) — new, 8 categories

**Research grounding:** Indian competitive-exam GK prep (UPSC/SSC/Railways/Bank PO)
consistently tests Science, History (Ancient/Medieval/Modern), Geography, Polity, and
Sports. Separately, Indian trivia sites converge on Indian History, Indian Geography,
Indian Mythology, Bollywood, and Cricket as standalone high-engagement categories, not
subcategories of something else — Bollywood in particular is treated as a full
category on dedicated trivia apps, not folded into "Movies." History and Geography
are kept as one paired category (`india-history-geography`) — see the note below —
rather than the two full separate categories they could arguably be, to keep the
total category count near English's 6.

| sort_order | slug | native name | emoji | color_from | color_to |
|---|---|---|---|---|---|
| 0 | `sports` | खेल | ⚽ | `#FF8A24` | `#FF3D6E` |
| 1 | `science` | विज्ञान | 🔬 | `#2BB3FF` | `#7B4DFF` |
| 2 | `general` | सामान्य ज्ञान | 🌍 | `#12C79B` | `#7BE495` |
| 3 | `iq` | आईक्यू | 🧠 | `#7B4DFF` | `#2BB3FF` |
| 4 | `maths` | गणित | 🔢 | `#FFC61A` | `#FF8A24` |
| 5 | `hinduism` | हिंदू धर्म | 🕉️ | `#FF9A3C` | `#FFD166` |
| 6 | `india-history-geography` | भारत: इतिहास और भूगोल | 🏛️ | `#D64550` | `#F2A65A` |
| 7 | `bollywood` | बॉलीवुड | 🎬 | `#E0218A` | `#FFB86B` |

`sports`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `cricket` | क्रिकेट | 🏏 | `#DDF1FF` | 0 |
| `football` | फुटबॉल | ⚽ | `#FFE9D6` | 1 |
| `hockey` | हॉकी | 🏑 | `#E4F7F1` | 2 |
| `kabaddi` | कबड्डी | 🤼 | `#FFE4EC` | 3 |
| `badminton` | बैडमिंटन | 🏸 | `#FFF4D6` | 4 |
| `olympics` | ओलंपिक | 🏅 | `#EDE8FA` | 5 |

`science`:

| slug | native name | emoji | plate_color | group_name | sort_order |
|---|---|---|---|---|---|
| `chemistry` | रसायन विज्ञान | 🧪 | `#FFE4EC` | भौतिक विज्ञान | 0 |
| `physics` | भौतिक विज्ञान | ⚛️ | `#FFE9D6` | भौतिक विज्ञान | 1 |
| `biology` | जीव विज्ञान | 🧬 | `#E4F7F1` | जीवन विज्ञान | 2 |
| `stars-galaxies` | तारे और आकाशगंगाएँ | ☀️ | `#FFF4D6` | खगोल विज्ञान | 3 |
| `solar-system` | सौर मंडल | 🪐 | `#DDF1FF` | खगोल विज्ञान | 4 |
| `space-exploration` | अंतरिक्ष अन्वेषण | 🔭 | `#EDE8FA` | खगोल विज्ञान | 5 |

`general`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `capitals` | राजधानियाँ | 🏙️ | `#EDE8FA` | 0 |
| `flags` | झंडे | 🚩 | `#DDF1FF` | 1 |
| `world-facts` | विश्व तथ्य | 🌍 | `#FFE9D6` | 2 |
| `awards` | पुरस्कार और सम्मान | 🏆 | `#FFF4D6` | 3 |

`iq`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `lateral-thinking` | तार्किक चिंतन | 💡 | `#EDE8FA` | 0 |
| `memory` | स्मृति | 🧠 | `#DDF1FF` | 1 |
| `pattern-logic` | पैटर्न तर्क | 🧩 | `#FFF4D6` | 2 |

`maths`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `number-theory` | संख्या सिद्धांत | ➗ | `#FFE9D6` | 0 |
| `mental-maths` | मानसिक गणित | 🔢 | `#FFF4D6` | 1 |
| `geometry` | ज्यामिति | 📐 | `#E4F7F1` | 2 |

`hinduism` (⚠️ sensitivity — see note below):

| slug | native name | emoji | plate_color | group_name | sort_order |
|---|---|---|---|---|---|
| `ramayana` | रामायण | 📜 | `#FFE9D6` | महाकाव्य | 0 |
| `mahabharata` | महाभारत | 📜 | `#EDE8FA` | महाकाव्य | 1 |
| `festivals` | हिंदू त्योहार | 🪔 | `#FFE4EC` | | 2 |
| `temples-architecture` | मंदिर और वास्तुकला | 🛕 | `#E4F7F1` | | 3 |
| `deities` | देवी-देवता | 🙏 | `#FFF4D6` | | 4 |
| `mythology` | पौराणिक कथाएँ | 📚 | `#DDF1FF` | | 5 |

`india-history-geography` (⚠️ sensitivity — see note below):

| slug | native name | emoji | plate_color | group_name | sort_order |
|---|---|---|---|---|---|
| `ancient-india` | प्राचीन भारत | 🏺 | `#FFE9D6` | इतिहास | 0 |
| `medieval-india` | मध्यकालीन भारत | 🏰 | `#EDE8FA` | इतिहास | 1 |
| `freedom-struggle` | आधुनिक भारत और स्वतंत्रता संग्राम | 🇮🇳 | `#FFE4EC` | इतिहास | 2 |
| `indian-states-capitals` | भारतीय राज्य और राजधानियाँ | 🗺️ | `#DDF1FF` | भूगोल | 3 |
| `rivers-mountains` | नदियाँ और पर्वत | 🏔️ | `#E4F7F1` | भूगोल | 4 |
| `wildlife-national-parks` | वन्यजीव और राष्ट्रीय उद्यान | 🐯 | `#FFF4D6` | भूगोल | 5 |

`bollywood`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `bollywood-films` | बॉलीवुड फ़िल्में | 🎬 | `#FFE4EC` | 0 |
| `bollywood-songs` | बॉलीवुड गाने | 🎵 | `#FFF4D6` | 1 |
| `actors-actresses` | अभिनेता और अभिनेत्रियाँ | 🌟 | `#EDE8FA` | 2 |
| `classic-cinema` | क्लासिक हिंदी सिनेमा | 🎞️ | `#E4F7F1` | 3 |
| `film-awards` | फ़िल्म पुरस्कार | 🏆 | `#DDF1FF` | 4 |

**Sensitivity notes for whoever authors questions here later:** `hinduism` — every
subcategory is scoped to neutral cultural/historical/literary framing (epics as
literature, festivals as culture, temples as architecture, `deities` as
identification/iconography trivia only — never comparative or hierarchical claims
between deities or traditions). `india-history-geography`'s `freedom-struggle` —
colonial-era/independence-movement figures can carry live political sensitivity;
stay factual (dates, events, named figures), avoid framing that takes a side on any
figure whose legacy is still contested today.

---

### Arabic (`ar`) — new, 7 categories

**Research grounding:** Arabic-language trivia apps/sites list دين (religion) and
تاريخ (history) as top-tier standalone categories, not niche add-ons, supporting a
deep Islam category plus a separate Arab History & Civilization category rather than
folding either into "General." Regional sport coverage (football's dominance,
handball/volleyball's popularity in Egypt and the Gulf, cricket's near-absence)
justified swapping Cricket/Hockey for Handball/Volleyball versus the EN sports list.
Research into the Islamic Golden Age (Abbasid Baghdad's House of Wisdom, Andalusia,
scholars like al-Khwarizmi/Ibn al-Haytham/Ibn Sina) confirmed it as a rich,
well-documented trivia subject in its own right — split across two categories: the
*religious* framing (Seerah, Quran, Hadith) stays under `islam`, the
*civilizational/scientific* framing (House of Wisdom, Abbasid Caliphate, Andalusia)
plus Middle East geography and Arabic literature (poetry, One Thousand and One
Nights) sits under the new `arab-heritage`.

| sort_order | slug | native name | emoji | color_from | color_to |
|---|---|---|---|---|---|
| 0 | `sports` | رياضة | ⚽ | `#FF8A24` | `#FF3D6E` |
| 1 | `science` | العلوم | 🔬 | `#2BB3FF` | `#7B4DFF` |
| 2 | `general` | معلومات عامة | 🌍 | `#12C79B` | `#7BE495` |
| 3 | `iq` | الذكاء | 🧠 | `#7B4DFF` | `#2BB3FF` |
| 4 | `maths` | الرياضيات | 🔢 | `#FFC61A` | `#FF8A24` |
| 5 | `islam` | الإسلام | 🕌 | `#12C79B` | `#2BB3FF` |
| 6 | `arab-heritage` | التاريخ والحضارة العربية | 🏛️ | `#8C5A2B` | `#E8B94E` |

`sports`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `football` | كرة القدم | ⚽ | `#FFE9D6` | 0 |
| `handball` | كرة اليد | 🤾 | `#E4F7F1` | 1 |
| `basketball` | كرة السلة | 🏀 | `#FFE4EC` | 2 |
| `volleyball` | الكرة الطائرة | 🏐 | `#FFF4D6` | 3 |
| `tennis` | التنس | 🎾 | `#EDE8FA` | 4 |
| `boxing-mma` | الملاكمة والفنون القتالية | 🥊 | `#DDF1FF` | 5 |
| `formula1` | سباقات الفورمولا 1 | 🏎️ | `#FFE9D6` | 6 |
| `olympics` | الألعاب الأولمبية | 🏅 | `#E4F7F1` | 7 |

`science`:

| slug | native name | emoji | plate_color | group_name | sort_order |
|---|---|---|---|---|---|
| `chemistry` | الكيمياء | 🧪 | `#FFE4EC` | العلوم الطبيعية | 0 |
| `biology` | علم الأحياء | 🧬 | `#E4F7F1` | العلوم الحيوية | 1 |
| `stars-galaxies` | النجوم والمجرات | ☀️ | `#FFF4D6` | علم الفلك | 2 |
| `solar-system` | النظام الشمسي | 🪐 | `#DDF1FF` | علم الفلك | 3 |
| `space-exploration` | استكشاف الفضاء | 🔭 | `#EDE8FA` | علم الفلك | 4 |

`general`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `capitals` | العواصم | 🏙️ | `#EDE8FA` | 0 |
| `movies` | الأفلام | 🎬 | `#FFE4EC` | 1 |
| `flags` | الأعلام | 🚩 | `#DDF1FF` | 2 |
| `world-facts` | حقائق عالمية | 🌍 | `#FFE9D6` | 3 |
| `inventions-discoveries` | الاختراعات والاكتشافات | 💡 | `#FFF4D6` | 4 |

`iq`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `lateral-thinking` | التفكير الجانبي | 💡 | `#EDE8FA` | 0 |
| `memory` | الذاكرة | 🧠 | `#DDF1FF` | 1 |
| `pattern-logic` | الألغاز المنطقية | 🧩 | `#FFF4D6` | 2 |

`maths`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `number-theory` | نظرية الأعداد | ➗ | `#FFE9D6` | 0 |
| `mental-maths` | الحساب الذهني | 🔢 | `#FFF4D6` | 1 |
| `geometry` | الهندسة | 📐 | `#E4F7F1` | 2 |

`islam` (⚠️ sensitivity — see note below):

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `seerah` | السيرة النبوية | 🕌 | `#E4F7F1` | 0 |
| `islamic-history` | التاريخ الإسلامي | 🏛️ | `#FFF4D6` | 1 |
| `quran` | القرآن الكريم | 📖 | `#EDE8FA` | 2 |
| `hadith` | الحديث الشريف | 📜 | `#DDF1FF` | 3 |
| `fiqh-worship` | الفقه والعبادات | 🕋 | `#FFE9D6` | 4 |
| `names-of-allah` | أسماء الله الحسنى | ✨ | `#FFE4EC` | 5 |

`arab-heritage`:

| slug | native name | emoji | plate_color | group_name | sort_order |
|---|---|---|---|---|---|
| `islamic-golden-age` | العصر الذهبي الإسلامي | 📜 | `#FFF4D6` | الحضارة | 0 |
| `house-of-wisdom` | بيت الحكمة والعلماء | 📚 | `#DDF1FF` | الحضارة | 1 |
| `abbasid-caliphate` | الخلافة العباسية | 👑 | `#EDE8FA` | الحضارة | 2 |
| `andalusia` | الأندلس | 🕌 | `#FFE9D6` | الحضارة | 3 |
| `middle-east-geography` | جغرافيا الشرق الأوسط | 🗺️ | `#E4F7F1` | الجغرافيا | 4 |
| `arabic-poetry` | الشعر العربي | 📖 | `#FFE4EC` | الأدب | 5 |
| `one-thousand-and-one-nights` | ألف ليلة وليلة | 🏮 | `#FFF4D6` | الأدب | 6 |

**Sensitivity notes for whoever authors questions here later:** `islam`'s
`fiqh-worship` — keep to universally-agreed basics (five daily prayers, Ramadan
fasting, Hajj pillars), avoid school-specific (madhhab) or Sunni/Shia-divergent
rulings. `hadith` — stick to widely-agreed, frequently-cited hadith, avoid
authenticity-grading disputes. `islamic-history`/`abbasid-caliphate`/`andalusia` —
frame around uncontested facts (dates, dynasties, rulers, achievements), avoid
succession-dispute framing (e.g. nothing touching Rashidun-succession
controversies). `arab-heritage`'s `middle-east-geography` — keep to uncontested
physical/cultural geography (capitals, rivers, deserts, landmarks), avoid
border/sovereignty-adjacent framing or contested naming disputes. General note: the
Arab world spans ~22 countries with real cultural/dialectal variation; this taxonomy
uses Modern Standard Arabic and pan-regional framing deliberately, but a
native-speaker reviewer should sanity-check tone/dialect-neutrality before
large-scale question authoring.

---

### French (`fr`) — new, 7 categories

**Research grounding:** French quiz-culture sites (L'Étudiant, CultureQuizz,
JetPunk) converge on histoire-géographie (treated as one paired theme), sport,
cinéma, sciences, langue française/orthographe (a France-specific genre with no EN
equivalent), gastronomie, and general culture générale. France-focused sources
repeatedly surface the Revolution, monarchy, Napoleon, Paris landmarks, regions, and
France's role in the wider Francophonie (Belgium, Switzerland, Québec, francophone
Africa) — this taxonomy serves all French speakers, not only metropolitan France, so
`history-geography` includes a dedicated `francophonie` subcategory and
`french-regions` is scoped to include overseas France (DOM-TOM), not just the
hexagon. Research into *laïcité* (the 1905 law separating church and state) directly
shaped the `christianity` category's framing — see the sensitivity note below.

| sort_order | slug | native name | emoji | color_from | color_to |
|---|---|---|---|---|---|
| 0 | `sports` | Sport | ⚽ | `#2E86FF` | `#00C2A8` |
| 1 | `science` | Sciences | 🔬 | `#5B3DF6` | `#22D3EE` |
| 2 | `general` | Culture Générale | 🌍 | `#16A34A` | `#86EFAC` |
| 3 | `iq` | QI | 🧠 | `#7C3AED` | `#38BDF8` |
| 4 | `maths` | Mathématiques | 🔢 | `#F59E0B` | `#FB7185` |
| 5 | `history-geography` | Histoire & Géographie | 🏰 | `#92400E` | `#D97706` |
| 6 | `christianity` | Christianisme | ✝️ | `#A16207` | `#FDE68A` |

*(`slug` for category 0 normalized from the research draft's `sport` → `sports`, to
match the identical concept's slug in every other language — see Research findings,
finding 1.)*

`sports`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `football` | Football | ⚽ | `#FFE9D6` | 0 |
| `rugby` | Rugby | 🏉 | `#E4F7F1` | 1 |
| `cycling` | Cyclisme (Tour de France) | 🚴 | `#FFE4EC` | 2 |
| `tennis` | Tennis | 🎾 | `#FFF4D6` | 3 |
| `olympics` | Jeux Olympiques | 🏅 | `#EDE8FA` | 4 |
| `winter-sports` | Ski & Sports d'Hiver | ⛷️ | `#DDF1FF` | 5 |
| `formula1` | Formule 1 | 🏎️ | `#FFE9D6` | 6 |
| `boxing-martial-arts` | Boxe & Arts Martiaux | 🥊 | `#E4F7F1` | 7 |

`science`:

| slug | native name | emoji | plate_color | group_name | sort_order |
|---|---|---|---|---|---|
| `chemistry` | Chimie | 🧪 | `#FFE4EC` | Sciences physiques | 0 |
| `stars-galaxies` | Étoiles & Galaxies | ☀️ | `#FFF4D6` | Astronomie | 1 |
| `biology` | Biologie | 🧬 | `#E4F7F1` | Sciences de la vie | 2 |
| `solar-system` | Système Solaire | 🪐 | `#DDF1FF` | Astronomie | 3 |
| `space-exploration` | Exploration Spatiale | 🔭 | `#EDE8FA` | Astronomie | 4 |

`general`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `movies` | Cinéma | 🎬 | `#FFE4EC` | 0 |
| `capitals` | Capitales du Monde | 🏙️ | `#EDE8FA` | 1 |
| `flags` | Drapeaux | 🚩 | `#DDF1FF` | 2 |
| `world-facts` | Faits Insolites | 🌍 | `#FFE9D6` | 3 |
| `gastronomy` | Gastronomie Française | 🍷 | `#FFF4D6` | 4 |
| `french-language` | Langue Française | 📚 | `#E4F7F1` | 5 |

`iq`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `lateral-thinking` | Réflexion Latérale | 💡 | `#EDE8FA` | 0 |
| `memory` | Mémoire | 🧠 | `#DDF1FF` | 1 |
| `pattern-logic` | Logique & Schémas | 🧩 | `#FFF4D6` | 2 |

`maths`:

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `number-theory` | Théorie des Nombres | ➗ | `#FFE9D6` | 0 |
| `mental-maths` | Calcul Mental | 🔢 | `#FFF4D6` | 1 |
| `geometry` | Géométrie | 📐 | `#E4F7F1` | 2 |

`history-geography` (⚠️ sensitivity — see note below):

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `french-revolution` | Révolution Française | ⚔️ | `#FFE9D6` | 0 |
| `kings-and-queens` | Rois & Reines de France | 👑 | `#EDE8FA` | 1 |
| `napoleon-empire` | Napoléon & l'Empire | 🎖️ | `#FFE4EC` | 2 |
| `french-regions` | Régions de France | 🏞️ | `#E4F7F1` | 3 |
| `paris-monuments` | Paris & ses Monuments | 🗼 | `#DDF1FF` | 4 |
| `european-geography` | Géographie Européenne | 🌍 | `#FFF4D6` | 5 |
| `francophonie` | La Francophonie | 🌐 | `#EDE8FA` | 6 |

`christianity` (⚠️ sensitivity — see note below):

| slug | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `biblical-literature` | Bible & Littérature Biblique | 📖 | `#FFF4D6` | 0 |
| `cathedrals-sacred-art` | Cathédrales & Art Sacré | ⛪ | `#E4F7F1` | 1 |
| `christian-history-france` | Histoire du Christianisme en France | ✝️ | `#EDE8FA` | 2 |
| `saints-figures` | Grandes Figures Chrétiennes | 👤 | `#FFE4EC` | 3 |
| `christian-holidays` | Fêtes & Traditions Chrétiennes | 🎄 | `#DDF1FF` | 4 |

**Sensitivity notes for whoever authors questions here later:** `christianity` —
frame strictly as history/literature/art, never devotional or comparative-in-a-loaded
way; avoid any phrasing implying Christianity is "official" or represents modern
French national identity (France is constitutionally secular since 1905 and
religiously diverse today) — keep tone descriptive ("Notre-Dame was built
starting in...") not identity-prescriptive. `christian-holidays` specifically risks
reading as devotional if not careful — keep to historical/cultural origins, not
liturgical practice. `history-geography`'s `french-revolution`/`napoleon-empire` —
politically charged periods; stay purely factual (dates, figures, events), avoid
glorifying or condemning framing.

---

### Spanish (`es`) — new, 7 categories

**Research grounding:** Spanish-language trivia sources (Sporcle, FunTrivia,
JetPunk, psicologiaymente) converge on the same culture-general set as English —
validating a near-mirror for the globally-general categories. Regionally: fútbol
dominates Hispanic sports culture far more than cricket/hockey (swapped for béisbol,
huge in Mexico/Caribbean/Venezuela, and ciclismo, huge in Spain via the Vuelta a
España and in Colombia via multiple Tour de France winners). History content
clusters around pre-Columbian civilizations (Maya/Aztec/Inca), the 1810–1825
independence wars (Bolívar, San Martín), and Spain's own history. Catholicism was
confirmed as a deep enough cultural/political/artistic force across the whole
Spanish-speaking world (post-1492) to warrant its own category, framed the same
neutral way the project's existing English Islam category is framed.

**Design decision carried over from research:** Spain (one country) and Latin
America (~19 culturally distinct nations) are blended into **one** pan-Hispanic
history/geography category (`hispanic-heritage`) rather than split into a
"Spain" category and a "Latin America" category — a literal split would force an
artificial framing that either flattens Latin America into a single bucket or
requires ~19 more categories; instead, individual subcategories each draw from
pre-Columbian, Spain-specific, or Latin-America-specific material. Only one
subcategory (`spain-history-monuments`) is deliberately Spain-only.

| sort_order | slug | native name | emoji | color_from | color_to |
|---|---|---|---|---|---|
| 0 | `sports` | Deportes | ⚽ | `#FF8A24` | `#FF3D6E` |
| 1 | `science` | Ciencia | 🔬 | `#2BB3FF` | `#7B4DFF` |
| 2 | `general` | Cultura General | 🌍 | `#12C79B` | `#7BE495` |
| 3 | `iq` | Ingenio | 🧠 | `#7B4DFF` | `#2BB3FF` |
| 4 | `maths` | Matemáticas | 🔢 | `#FFC61A` | `#FF8A24` |
| 5 | `christianity` | Cristianismo | ✝️ | `#6D4AFF` | `#FFB84D` |
| 6 | `hispanic-heritage` | Historia y Geografía Hispana | 🌎 | `#E85D4C` | `#F2C14E` |

*(All 7 slugs normalized from the research draft's native-Spanish slugs — e.g.
`deportes`→`sports`, `ciencia`→`science`, `ingenio`→`iq`,
`historia-y-geografia-hispana`→`hispanic-heritage` — to match the ASCII-slug
convention; see Research findings, finding 1. Native names are unaffected.)*

`sports`:

| slug (normalized) | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `football` | Fútbol | ⚽ | `#FFE9D6` | 0 |
| `baseball` | Béisbol | ⚾ | `#E4F7F1` | 1 |
| `basketball` | Baloncesto | 🏀 | `#FFE4EC` | 2 |
| `tennis` | Tenis | 🎾 | `#FFF4D6` | 3 |
| `boxing-mma` | Boxeo y MMA | 🥊 | `#EDE8FA` | 4 |
| `cycling` | Ciclismo | 🚴 | `#DDF1FF` | 5 |
| `olympics` | Juegos Olímpicos | 🏅 | `#FFE9D6` | 6 |

`science`:

| slug (normalized) | native name | emoji | plate_color | group_name | sort_order |
|---|---|---|---|---|---|
| `chemistry` | Química | 🧪 | `#FFE4EC` | Ciencias físicas | 0 |
| `stars-galaxies` | Estrellas y Galaxias | ☀️ | `#FFF4D6` | Astronomía | 1 |
| `biology` | Biología | 🧬 | `#E4F7F1` | Ciencias de la vida | 2 |
| `solar-system` | Sistema Solar | 🪐 | `#DDF1FF` | Astronomía | 3 |
| `space-exploration` | Exploración Espacial | 🔭 | `#EDE8FA` | Astronomía | 4 |

`general`:

| slug (normalized) | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `capitals` | Capitales | 🏙️ | `#EDE8FA` | 0 |
| `movies` | Cine | 🎬 | `#FFE4EC` | 1 |
| `flags` | Banderas | 🚩 | `#DDF1FF` | 2 |
| `world-facts` | Datos del Mundo | 🌍 | `#FFE9D6` | 3 |
| `music` | Música | 🎵 | `#FFF4D6` | 4 |

`iq`:

| slug (normalized) | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `lateral-thinking` | Pensamiento Lateral | 💡 | `#EDE8FA` | 0 |
| `memory` | Memoria | 🧠 | `#DDF1FF` | 1 |
| `pattern-logic` | Lógica y Patrones | 🧩 | `#FFF4D6` | 2 |

`maths`:

| slug (normalized) | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `number-theory` | Teoría de Números | ➗ | `#FFE9D6` | 0 |
| `mental-maths` | Cálculo Mental | 🔢 | `#FFF4D6` | 1 |
| `geometry` | Geometría | 📐 | `#E4F7F1` | 2 |

`christianity` (⚠️ sensitivity — see note below):

| slug (normalized) | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `christian-history` | Historia del Cristianismo | 📜 | `#FFE9D6` | 0 |
| `biblical-figures` | Figuras Bíblicas | 📖 | `#EDE8FA` | 1 |
| `cathedrals-sacred-art` | Arte y Catedrales | ⛪ | `#FFE4EC` | 2 |
| `popes-and-church` | Papas y la Iglesia | 🏛️ | `#FFF4D6` | 3 |
| `holy-week-traditions` | Semana Santa y Tradiciones | 🕯️ | `#E4F7F1` | 4 |

`hispanic-heritage` (⚠️ sensitivity — see note below):

| slug (normalized) | native name | emoji | plate_color | sort_order |
|---|---|---|---|---|
| `ancient-civilizations` | Civilizaciones Antiguas | 🏺 | `#DDF1FF` | 0 |
| `independence-liberators` | Independencia y Libertadores | 🗽 | `#FFE9D6` | 1 |
| `spain-history-monuments` | España: Historia y Monumentos | 🏰 | `#EDE8FA` | 2 |
| `latin-america-countries` | Países y Capitales de Hispanoamérica | 🗺️ | `#FFE4EC` | 3 |
| `nature-landscapes` | Naturaleza y Paisajes | 🏔️ | `#E4F7F1` | 4 |

**Sensitivity notes for whoever authors questions here later:** `christianity` —
same neutral cultural/historical/textual framing as every other language's religion
category, human-reviewed before publishing. `hispanic-heritage`'s
`independence-liberators` and `nature-landscapes` — draw examples from multiple
Latin American countries, not just Mexico/Argentina/Colombia by default; a reviewer
should spot-check the eventually-authored batch for this. `spain-history-monuments`
is the one deliberately Spain-only subcategory in an otherwise pan-Hispanic
category — confirm the roughly 1-of-5 weighting still feels fair once real question
volume exists. Bullfighting (tauromaquia) was deliberately excluded as a topic —
divisive even within Spain itself.

## Assumptions & open questions

- **Question authoring is a separate follow-up, not part of this plan.** This plan
  creates zero `questions` rows. Once merged, run `/generate-questions` once per new
  subcategory (it already supports arbitrary sub-categories/languages once they
  exist in the DB — see its Step 1/Step 4 language-mismatch guard). Flagged, not
  resolved here, because the spec's ask was specifically "add more categories and
  subcategories," and content authoring is already its own established, separately
  human-reviewed workflow.
- **`languages.is_active` stays `false`** for `hi`/`ar`/`fr`/`es` after this plan —
  see Scope. If the human reviewing this plan wants activation bundled into the same
  rollout instead of gated on content volume, that's a one-line follow-up
  (`update languages set is_active = true where code in (...)`), but doing it
  automatically here would expose near-empty content trees per the original spec's
  own explicit warning against that.
- **Emoji/color choices are original design proposals**, not pulled from any
  existing design-system token file — consistent with how the *existing* `en`/`ur`
  category rows already work (literal hex values on the `categories`/`subcategories`
  rows themselves, not `AppColors` tokens; CLAUDE.md §5's "no hardcoded colors" rule
  governs Flutter widget code in `lib/`, not database seed content). A designer
  should still eyeball the new gradients/pastels before shipping, same as they would
  for any new seed content.
- **Category/subcategory counts vary per language by design**, not oversight — e.g.
  Hindi lands at 8 categories (slightly over the ~6-7 "globally general + regional"
  target) because the research signal for keeping India's History and Geography
  under one paired category rather than splitting further was judged strong enough
  to keep, while still not ballooning past 8. A reviewer who wants tighter parity
  across languages can trim per-language without touching the others.
- **`ai_generation_allowed`** (existing `subcategories` column, defaults `true`) is
  left at its default for every new row in this plan, including the
  religion-category subcategories — the existing project convention already gates
  sensitive content via human review of `/generate-questions`' `review.md` output
  *before* its SQL is ever run, not via this flag. A reviewer could choose to set
  `ai_generation_allowed = false` on specific sensitive subcategories (e.g.
  `fiqh-worship`, `hadith`, `names-of-allah`) to force fully human-authored content
  instead — left as an explicit open question rather than decided here, since it
  wasn't part of the original ask.

## Design overview

No schema change. This plan authors data into three already-existing tables per the
model `migration 20260910090100_multilingual_content_model.sql` established:

- `categories` — one row per (language, category), scoped by
  `unique(language_code, slug)`.
- `subcategories` — one row per (category, subcategory), scoped by
  `unique(category_id, slug)`; language is inherited via `category_id`.
- `taxonomy_i18n` — one row per `(entity_type, entity_id, locale)`, carrying the
  actual display name shown in the app (`CatalogApi._taxonomyNames`,
  `lib/features/catalog/data/catalog_api.dart:194-209`, falls back to `slug` if a
  `taxonomy_i18n` row is missing — so every category/subcategory below **must** get
  a matching `taxonomy_i18n` row, or the app would silently show the English-ish
  slug instead of the native name).

`categories.subcategory_count`/`question_count` and their parent totals are
denormalized counters maintained automatically by the
`_refresh_category_counts()` trigger (`supabase/migrations/20260907120200_functions_and_triggers.sql:359-402`),
fired on `subcategories`/`questions` insert/update/delete — **no manual counter
maintenance needed** in this migration; inserting a `subcategories` row is enough to
make the trigger recompute its parent `categories` row.

## Implementation steps

- [ ] **Phase 0 — reconfirm live state.** Before writing the migration, re-run the
      snapshot queries this plan was drafted from, to confirm nothing has changed:
      ```sql
      select language_code, slug, sort_order from categories order by language_code, sort_order;
      select c.language_code, c.slug as cat_slug, s.slug as sub_slug, s.group_name
      from subcategories s join categories c on c.id = s.category_id
      order by c.language_code, c.slug, s.sort_order;
      ```
      If `ur`'s `science`/`solar-system` rows, or any `hi`/`ar`/`fr`/`es` category
      rows, already exist beyond what's described in this plan's Objective, stop and
      reconcile before proceeding — the `on conflict do nothing` inserts below are
      safe against exact duplicates but won't merge conflicting edits.

- [ ] **Phase 1 — write one new migration file**,
      `supabase/migrations/<YYYYMMDDHHMMSS>_expand_multilingual_category_taxonomy.sql`
      (timestamp = actual run time, following this project's existing naming
      convention — see the files already in `supabase/migrations/`), wrapped in a
      single `begin; ... commit;` transaction, structured in five clearly-commented
      sections (one per language, in the order presented in this plan: Urdu, Hindi,
      Arabic, French, Spanish). Use this canonical insert pattern for every
      category/subcategory/name — repeated mechanically once per row in the data
      tables above, no invention required:

      ```sql
      -- One category
      insert into public.categories (slug, emoji, color_from, color_to, sort_order, is_active, language_code)
      values ('<slug>', '<emoji>', '<color_from>', '<color_to>', <sort_order>, true, '<lang>')
      on conflict (language_code, slug) do nothing;

      -- That category's subcategories, in one statement via a VALUES join
      insert into public.subcategories (category_id, slug, emoji, plate_color, group_name, sort_order, is_active)
      select c.id, v.slug, v.emoji, v.plate_color, v.group_name, v.sort_order, true
      from public.categories c
      cross join (values
        ('<sub_slug_1>', '<emoji>', '<plate_color>', '<group_name_or_empty>', 0),
        ('<sub_slug_2>', '<emoji>', '<plate_color>', '<group_name_or_empty>', 1)
        -- ... one tuple per subcategory row in this category's table above
      ) as v(slug, emoji, plate_color, group_name, sort_order)
      where c.language_code = '<lang>' and c.slug = '<category_slug>'
      on conflict (category_id, slug) do nothing;

      -- The category's own display name
      insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
      select 'category', c.id, '<lang>', '<native category name>'
      from public.categories c
      where c.language_code = '<lang>' and c.slug = '<category_slug>'
      on conflict (entity_type, entity_id, locale) do nothing;

      -- All its subcategories' display names, in one statement
      insert into public.taxonomy_i18n (entity_type, entity_id, locale, name)
      select 'subcategory', s.id, '<lang>', v.name
      from public.subcategories s
      join public.categories c on c.id = s.category_id
      cross join (values
        ('<sub_slug_1>', '<native name 1>'),
        ('<sub_slug_2>', '<native name 2>')
        -- ... one tuple per subcategory row in this category's table above
      ) as v(slug, name)
      where c.language_code = '<lang>' and c.slug = '<category_slug>' and s.slug = v.slug
      on conflict (entity_type, entity_id, locale) do nothing;
      ```

- [ ] **Phase 1a — Urdu's two corrective statements**, run once, before the new-row
      inserts for `ur` (they touch the *existing* `science`/`solar-system` rows, not
      new ones):
      ```sql
      update public.categories
      set sort_order = 0
      where language_code = 'ur' and slug = 'science';

      update public.subcategories s
      set group_name = 'فلکیات'
      from public.categories c
      where s.category_id = c.id and c.language_code = 'ur' and c.slug = 'science'
        and s.slug = 'solar-system' and s.group_name = 'Astronomy';
      ```
      (The `and s.group_name = 'Astronomy'` guard makes this idempotent — re-running
      the migration after the fix has already landed is a no-op, not an error.)

- [ ] **Phase 1b — worked example (Urdu `science`, fully filled in)**, to
      disambiguate the pattern above before mechanically repeating it for every
      other category/subcategory table in this plan:
      ```sql
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
      ```
      Apply the exact same two-statement shape (subcategories insert, then
      taxonomy_i18n insert), plus the category-level `categories` and
      `taxonomy_i18n` inserts from the canonical pattern, for **every** category
      table in the Research findings section above — Urdu's remaining 7 categories,
      then all of Hindi (8), Arabic (7), French (7), Spanish (7).

- [ ] **Phase 2 — run the migration** against a staging project/branch first (per
      this project's own established convention — see the header comment of
      `20260910090100_multilingual_content_model.sql`, "run against a staging
      project or a Supabase branch first, not production directly"), then apply to
      the live project once verified.

- [ ] **Phase 3 — verify** with the queries in "Testing strategy" below.

## Data model / API changes

N/A — no table, column, or constraint changes. Pure data insert into existing
`categories`/`subcategories`/`taxonomy_i18n` tables. No RLS policy changes needed
(existing `select`-for-everyone policies on these tables already cover the new rows;
the migration itself runs with elevated/migration privileges, not through RLS).

## Dependencies

N/A — no new packages, no Flutter code changes.

## Testing strategy

This is a pure data migration with no application code path change (`CatalogApi`,
`LanguagesApi` already handle arbitrary `language_code`/category data dynamically),
so no new Dart/`bloc_test`/widget tests are needed per CLAUDE.md §11's scope (those
requirements are for new Cubits/Blocs/repositories, none of which this plan touches).
Verification is SQL-based, run after applying the migration:

```sql
-- 1. Every new category has exactly one taxonomy_i18n name (no silent slug-fallback)
select c.language_code, c.slug
from categories c
left join taxonomy_i18n t on t.entity_type = 'category' and t.entity_id = c.id and t.locale = c.language_code
where c.language_code in ('ur','hi','ar','fr','es') and t.name is null;
-- expect: 0 rows

-- 2. Every new subcategory has exactly one taxonomy_i18n name
select c.language_code, c.slug as category_slug, s.slug as sub_slug
from subcategories s
join categories c on c.id = s.category_id
left join taxonomy_i18n t on t.entity_type = 'subcategory' and t.entity_id = s.id and t.locale = c.language_code
where c.language_code in ('ur','hi','ar','fr','es') and t.name is null;
-- expect: 0 rows

-- 3. Category/subcategory counts per language, sanity-check against this plan's tables
select language_code, count(*) as category_count from categories
where language_code in ('ur','hi','ar','fr','es') group by language_code;

select c.language_code, count(*) as subcategory_count
from subcategories s join categories c on c.id = s.category_id
where c.language_code in ('ur','hi','ar','fr','es') group by c.language_code;

-- 4. The two Urdu corrective updates landed
select sort_order from categories where language_code = 'ur' and slug = 'science'; -- expect 0
select group_name from subcategories s join categories c on c.id = s.category_id
where c.language_code = 'ur' and c.slug = 'science' and s.slug = 'solar-system'; -- expect 'فلکیات'

-- 5. The auto-maintained counters actually updated (spot check one new category)
select slug, subcategory_count, question_count from categories
where language_code = 'hi' and slug = 'sports'; -- expect subcategory_count = 6, question_count = 0
```

**To verify (manual, per CLAUDE.md §13 — this plan makes no app-runtime claims, but
flagging what a human should eyeball once this ships and a language is later
activated):** switch the app's content language (once a language is flipped active
per "Risks & rollout notes") to Urdu/Hindi/Arabic and confirm the new category chips
render their native names correctly, RTL layout is correct for `ur`/`ar`, and emoji
render as expected on both iOS and Android.

## Edge cases & error handling

- **Re-running the migration is safe.** Every `insert` uses `on conflict ... do
  nothing` against the exact constraints already enforced by the schema
  (`categories_language_slug_unique`, `subcategories_category_slug_unique`, the
  `taxonomy_i18n` primary key) — running the whole file twice is a no-op the second
  time, not an error or a duplicate-row problem.
- **`enforce_question_language_match` trigger** (on `questions`, from the
  multilingual migration) is irrelevant here — this plan inserts zero `questions`
  rows, so it never fires.
- **A `categories`/`subcategories` row without a matching `taxonomy_i18n` row** is
  the one real failure mode this plan needs to avoid — it wouldn't error, it would
  silently render the English-ish `slug` in the app instead of a native name (see
  `CatalogApi._categoryFromRow`'s fallback,
  `lib/features/catalog/data/catalog_api.dart:55`). Testing strategy queries 1 and 2
  above exist specifically to catch this before it ships.
- **Emoji rendering** — a small number of chosen emoji include variation selectors
  (e.g. 🏎️, 🕊️-style sequences) which render fine on modern iOS/Android but are worth
  a quick visual check per "To verify" above, same risk class as any existing emoji
  already in the `en ` taxonomy.

## Acceptance criteria

- [ ] `ur` has 8 categories (up from 1) and its `science` category has 5
      subcategories (up from 1); the pre-existing `solar-system` row's `group_name`
      reads `فلکیات`, not `Astronomy`.
- [ ] `hi`, `ar`, `fr`, `es` each have the category/subcategory counts listed in
      their respective sections above (8/39, 7/37, 7/37, 7/33 respectively, per the
      as-drafted tables).
- [ ] Every new/edited category and subcategory has a matching `taxonomy_i18n` row
      in its own language (Testing strategy queries 1–2 both return 0 rows).
- [ ] No existing `en` or `ur` `science`/`solar-system` question rows, `level_progress`
      rows, or `level_attempts` rows were touched — this migration only inserts new
      taxonomy rows and updates two specific pre-existing columns (Urdu
      `sort_order`/`group_name`).
- [ ] `languages.is_active` is unchanged (`hi`/`ar`/`fr`/`es` remain `false`) unless
      a human reviewing this plan explicitly decides otherwise (see Assumptions).
- [ ] `dart analyze` and the existing test suite are unaffected (no Dart files
      touched by this plan) — re-run only as a sanity check that nothing else on the
      branch regressed.

## Risks & rollout notes

- **Content gap after this ships.** The moment this migration lands, `hi`/`ar`/`fr`/`es`
  have real categories/subcategories but **zero questions** — `is_active` staying
  `false` (per Scope) prevents this from being player-visible, but anyone querying
  these tables directly (e.g. an admin dashboard, or `/generate-questions`' own
  Step 0 live-lookup query) will see fresh empty pools. This is expected and by
  design — the next step is running `/generate-questions` per subcategory.
- **Sequencing recommendation:** after this migration lands, prioritize authoring
  enough questions to clear `v_thin_question_pools`' threshold (see
  `.claude/specs/quizoo-difficulty-language-questionbank-spec.md` §3.4) for at least
  the "globally general" categories (Sports/Science/General/IQ/Maths) in each
  language before considering `is_active = true` — those are the categories a newly
  onboarded player in that language will hit first.
- **No rollback migration is included** — if this needs to be reverted, the safest
  path is a follow-up migration deleting by `language_code in
  ('hi','ar','fr','es')` (whole-language rows, safe since those languages have no
  other data yet) and, for `ur`, deleting specifically the 7 new category slugs
  listed in this plan's Urdu section (never touch the pre-existing `science`
  category beyond reverting its `sort_order`/`group_name` back to `1`/`'Astronomy'`)
  — not written out in full here since it's a straightforward inverse of Phase 1,
  and only needed if something goes wrong.
- **Docs to update after implementation:** none required by CLAUDE.md — this is a
  content/data change, not an architectural one.
