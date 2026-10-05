# Image sourcing & verification reference (generate-questions, image/all modes)

Read this file in full before any run whose mode includes `image`
(`-mode image`, `-mode all`). It is the approved-source catalog, the license
gate, and the verification protocol for every image question this skill
authors. `SKILL.md`'s Hard rule 6 summarizes the non-negotiables; this file is
the detail.

Captured 2026-10-05. If a source's API shape or license policy changes,
update this file — don't silently drift.

## 0. The four non-negotiables

1. **Approved sources only.** Images come from the catalog below. Never from
   a general web-search image result, never from a "here's a URL I found"
   guess, never a stock-photo preview, never social media.
2. **PD / CC0 only.** The app has no credit UI, so anything requiring
   attribution (CC-BY, CC-BY-SA, GFDL-only, "fair use") is rejected even if it
   is otherwise freely usable. Public domain and CC0 have no attribution
   requirement; the skill still records source/author/license in `review.html`
   as an audit trail.
3. **Download, verify by sight, re-host.** Every image is downloaded to the
   scratchpad, viewed with the Read tool (not just trusted from metadata),
   and uploaded to the `question-media` bucket via
   `scripts/upload_question_media.py`. **Never put a source-site URL into
   `media_url`** — hotlinks rot, get rate-limited, lack CORS, and can be
   renamed/deleted at any time.
4. **One image, one question, once.** An image already referenced by another
   question (same subcategory) is not reused, even for a different
   difficulty or prompt.

## 1. What makes a good image question

- The image is **load-bearing**: the question cannot be answered without
  seeing it. If the prompt gives away the subject, don't use an image.
- **Exactly one unambiguous answer.** Reject photos with multiple valid
  readings ("which country is this coastline?"), lookalike species,
  Neptune/Uranus-style pairs, generic landscapes, crowds, composites, and
  diagrams with unlabelled parts.
- **Identity is confirmable from source metadata**, not just from vibes:
  Commons file title/categories/description, a museum object record title, a
  NASA image title. If the metadata doesn't state what it is, reject it —
  vision alone is not sufficient ground truth.
- **Clean presentation**: no watermarks, no overlaid answer text, no
  timestamp/channel bugs, no heavy filters or meme formatting, no
  identifiable private individuals, no graphic/medical content, no
  trademarks/logos/currency/brands.
- **Fits the media plate**: the app's plate is 132 logical px tall and
  full-width, and the future render is `BoxFit.cover`-shaped — prefer
  landscape/centered-subject images where the subject survives a wide crop.
  Reject extremly tall or panoramic images.
- **Evergreen**: no "currently", no current office-holders (image of a
  current president/PM), no "newest/latest" subjects subject to change.

## 2. Approved source catalog

### 2.1 FlagCDN — flags (country, US state, EU/UN)

- List: `https://flagcdn.com/en/codes.json` (`{ "jp": "Japan", ... }`).
- Image: `https://flagcdn.com/w640/{code}.png` (also `w320`, `w1280`; PNG/WebP/SVG available — always pick PNG for this skill).
- Free service, no key, no per-image license metadata; flags are drawn from
  Wikimedia Commons flag SVGs and are PD/CC0 in substance. Record
  `Source: https://flagcdn.com/ + <code>` in `review.html`.
- Perfect for "Which country's flag is this?" with three country-name
  options. Distractors should be flags that are visually distinct.

### 2.2 Wikimedia Commons — the workhorse (landmarks, species, art, history, maps)

Search:

```
https://commons.wikimedia.org/w/api.php?action=query&format=json&list=search
  &srsearch=<query>&srnamespace=6&srlimit=20
```

Then fetch the file's URL + license metadata:

```
https://commons.wikimedia.org/w/api.php?action=query&format=json
  &titles=File:<name>&prop=imageinfo&iiprop=url|extmetadata|size&iiurlwidth=800
```

- Download `imageinfo[0].thumburl` (800px wide) when present, else
  `imageinfo[0].url`. Never use `upload.wikimedia.org`-style hotlinks in
  `media_url`.
- **License gate** — from `extmetadata`:
  - Accept: `LicenseShortName` / `License` containing `Public domain`,
    `PD`, `CC0`, `PDM` (e.g. `PD-old-100`, `PD-US`, `CC0 1.0`). Also
    `UsageTerms` saying "Public domain" with no restrictions.
  - Reject: `CC BY`, `CC BY-SA`, `GFDL` alone, `CC BY-NC`, `CC BY-ND`,
    anything with an attribution/ShareAlike term.
  - If `extmetadata` has no recognizable license → reject the file.
- Record from `extmetadata`: `ImageDescription` (identity!), `Artist`
  (author), `LicenseShortName`, plus the Commons file page URL
  (`https://commons.wikimedia.org/wiki/File:<name>`).
- **Identity gate**: the file title + description must name the subject
  (e.g. "Taj Mahal from the north", "Eiffel Tower from the Seine"). If the
  description is vague, reject.
- Send a descriptive `User-Agent` on every request (Wikimedia policy), e.g.
  `User-Agent: QuizooQuestionBot/1.0 (quiz content authoring; contact <repo owner>)`.
- Be polite: sequential requests, small backoff on 429/5xx.

### 2.3 Wikipedia REST — quick lead image for a named topic

- `https://en.wikipedia.org/api/rest_v1/page/summary/{Title}` returns
  `thumbnail.source` + `description` (e.g. "Marble mausoleum in Agra,
  India"). Great for "which city/country is this" questions about a known
  subject.
- The thumbnail is a Commons file: **still run the Commons license gate on
  the underlying file name before using it** (the summary API does not
  report the license).
- Language editions work too (`ur.wikipedia.org`, `ar.wikipedia.org`), but
  license verification always happens on Commons.

### 2.4 NASA Image and Video Library — space & Earth science

- Search: `https://images-api.nasa.gov/search?q=<query>&media_type=image`
  (no key needed; `api.nasa.gov` key only for other NASA APIs).
- Each item: `data[0].title`, `data[0].description`, `data[0].nasa_id`,
  `links[0].href` (`~medium.jpg` ≈ 1024px is the right rendition; `~orig`
  is too big).
- NASA-authored imagery is generally not subject to copyright (public
  domain), but some items carry third-party credits — stick to items whose
  `secondary_creator`/credit is NASA or blank, and record `nasa_id` +
  title. Best for Solar System / Space / Astronomy / Earth-science
  subcategories.

### 2.5 The Met — art, artifacts, world culture (CC0)

- Search:
  `https://collectionapi.metmuseum.org/public/collection/v1/search?q=<query>&hasImages=true`
- Object: `https://collectionapi.metmuseum.org/public/collection/v1/objects/{objectID}`
- Require `isPublicDomain: true`. Use `primaryImageSmall` (≈ fits the plate)
  or `primaryImage`. Record `title`, `artistDisplayName`, `objectID`,
  `objectURL`.
- No key. 80 req/s limit. Best for art/history/culture questions ("Who
  painted this?", "Which civilization made this?").

### 2.6 Art Institute of Chicago — art (CC0, CORS-friendly)

- Search:
  `https://api.artic.edu/api/v1/artworks/search?q=<query>&fields=id,title,image_id,is_public_domain,artist_title,date_display`
- Require `is_public_domain: true`; image:
  `https://www.artic.edu/iiif/2/{image_id}/full/843,/0/default.jpg`
- Record `title`, `artist_title`, `date_display`. No key.

### 2.7 Cleveland Museum of Art — art (CC0)

- `https://openaccess-api.clevelandart.org/api/artworks/?q=<query>&has_image=1`
- Require `share_license_status == "CC0"`; image from
  `images.web.url`. Record `title`, `creators[0].description`, `accession_number`.

### 2.8 Openverse — discovery fallback only (verify at source)

- `https://api.openverse.org/v1/images/?q=<query>&license=cc0,pdm&filter_dead=true&page_size=20`
- Openverse aggregates from many sites and its own docs say license
  accuracy is not guaranteed. Only use it to *find* a candidate, then open
  the original source page and verify PD/CC0 there before downloading.
  Prefer the catalog above when it covers the topic.

## 3. Per-topic strategy

| Subcategory topic | Primary sources | Question shapes |
|---|---|---|
| Flags / Countries / Geography | FlagCDN, Commons maps & landmarks | Which country's flag/country is this? Where is this landmark? |
| Landmarks / Architecture | Commons (named file + description), Wikipedia REST | In which city/country is this? What is this structure? |
| Space / Solar System / Astronomy | NASA Image library, Commons | Which planet/moon/nebula is this? What mission? |
| Art / Paintings / History | Met, AIC, Cleveland, Commons | Who painted this? Which movement/civilization? |
| Animals / Nature / Birds | Commons (named species files), Openverse→source | Which animal/species is this? |
| Sports / Religion / Language / Math / Pop culture | Usually **no** PD photo pool that tests the topic | Prefer text mode; if mode forces image, assess feasibility and stop rather than force |

Make sure the image actually tests the subcategory — a generic satellite
photo in a "Solar System" quiz is fine, a generic satellite photo in
"Football" is not.

## 4. Download & verification protocol (per image question)

1. **Find** 1–3 candidates from an approved source, using a query that names
   the subject, not the question.
2. **License-gate** each candidate from its metadata before downloading.
3. **Download** the chosen rendition to the scratchpad
   (`.../opencode/` is pre-approved) with a descriptive filename:
   `curl -sL -A "<UA>" "<url>" -o <scratch>/<subject>.jpg`.
   Target: ≥ 600px wide (800–1280 ideal), ≤ ~500KB, JPEG or PNG only
   (no SVG/WEBP in image mode — the app's future network render won't do
   SVG).
4. **View it with the Read tool.** This step is mandatory and cannot be
   skipped or replaced by metadata. Confirm against the checklist in §1:
   identity, single answer, no giveaways, presentation, crop.
5. **Reject and swap** on any doubt — go back to step 1. Never "make it
   work" with a weak image. It is fine to spend a few candidates per
   accepted image; it is not fine to lower the bar.
6. **Write the question** only after the image is accepted: short prompt
   (doesn't name the answer), exactly **3 options** (one correct, two
   plausible), `correct_index` 0–2, one-sentence explanation that adds a
   real detail. Write natively in the target language/script.
7. **Pre-generate the question UUID** (`python3 -c "import uuid; print(uuid.uuid4())"`)
   — the storage object path is `<language_code>/<uuid>.<ext>`, so the SQL
   row must use that exact id.
8. **Upload** via `scripts/upload_question_media.py` (one run for the batch,
   after all images are accepted). Read the result JSON; only uploads with
   a `public_url` go into `questions.sql`.
9. **Log for `review.html`**: Commons/official title, source page URL, author,
   license short name, the public URL, and the scratchpad filename if useful.

### If a download fails

| Symptom | Action |
|---|---|
| HTTP 403/429 | Wait a moment, retry once with the proper User-Agent. Still failing → reject source/swap candidate. |
| Wrong content type (HTML error page saved as .jpg) | Check with `file <path>`; reject unless it reports JPEG/PNG. |
| Image too small/large | Pick a different rendition from the same source (`iiurlwidth`, FlagCDN size, NASA `~medium`). Don't upscale/download-and-resize. |
| No PD/CC0 candidate after a few tries | Swap the subject for an easier one. If several subjects in a row are impossible, revisit the Step 1 image-capability assessment. |

## 5. Recording & licensing notes

- Each image question's card in `review.html` must carry a source line in
  exactly this shape (HTML-escape the text; the URL goes in `href`):

  ```html
  <p class="source">Source: <a href="https://commons.wikimedia.org/wiki/File:Taj_Mahal_(Edited).jpeg" rel="noopener">File:Taj Mahal (Edited).jpeg</a> — Yann Forget, Public domain. Stored at <code>question-media/en/&lt;uuid&gt;.jpg</code>.</p>
  ```
- `questions.sql` carries only the uploaded `media_url`; the attribution
  trail lives in `review.html` (and, through it, the batch folder next to the
  project).
- If you cannot prove PD/CC0 for a candidate, it does not exist for this
  skill. There is always another subject.
