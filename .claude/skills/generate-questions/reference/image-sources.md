# Image sourcing & verification reference (generate-questions, image/all modes)

Read this file in full before any run whose mode includes `image`
(`-mode image`, `-mode all`). It is the approved-source catalog, the license
gate, and the verification protocol for every image question this skill
authors. `SKILL.md`'s Hard rule 6 summarizes the non-negotiables; this file is
the detail.

Captured 2026-10-05; license policy expanded to CC-BY / CC-BY-SA on
2026-10-06; images pinned to a fixed 16:9 frame (and questions to four
options) on 2026-10-10. If a source's API shape or license policy changes,
update this file — don't silently drift.

## 0. The four non-negotiables

1. **Approved sources only.** Images come from the catalog below. Never from
   a general web-search image result, never from a "here's a URL I found"
   guess, never a stock-photo preview, never social media.
2. **Openly licensed only: PD, CC0, CC-BY, or CC-BY-SA.** Attribution-
   required images (CC-BY, CC-BY-SA) are allowed — the attribution travels
   with the content itself as a mandatory credit line in the question's
   `explanation`, so no in-app credit UI is needed:
   `Credit: <author>, <license short name>, <license URL>.` (final sentence
   of the explanation; exact format in §5). Reject CC-BY-NC, CC-BY-ND,
   GFDL-only, "fair use", stock-photo previews, and anything all-rights-
   reserved or unverifiable. PD/CC0 carry no credit obligation, but every
   image still records source/author/license in `review.html` as an audit
   trail.
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
  graphic/medical content, no trademarks/logos/currency/brands. Public
  figures are fine when the photo is openly licensed; avoid private
  (non-public) individuals and privacy-sensitive candid shots.
- **Normalizes cleanly to 16:9**: every uploaded image is cropped to an
  exact 16:9 frame (640–1280 px wide; §4) because the app's plate is a
  fixed-height, full-width strip drawn with `BoxFit.contain` — a consistent
  ratio is the *only* thing that makes every question's photo render the
  same size on screen. Prefer landscape/centered-subject photos, and choose
  the crop so the answer-critical content (the landmark, the flag's
  charges, the animal/person, the object being asked about) stays fully
  inside the frame. A tall/portrait candidate is only acceptable when a
  16:9 band centered on its subject still shows everything the question
  depends on; an extreme panorama is fine when cropped down to a centered
  band. If neither crop keeps the context, reject the candidate.
- **Evergreen**: no "currently", no current office-holders (image of a
  current president/PM), no "newest/latest" subjects subject to change.

## 2. Approved source catalog

### 2.1 FlagCDN — flags (country, US state, EU/UN)

- List: `https://flagcdn.com/en/codes.json` (`{ "jp": "Japan", ... }`).
- Image: `https://flagcdn.com/w1280/{code}.png` (also `w640`, `w320`;
  PNG/WebP/SVG available — always pick PNG for this skill). Use `w1280` as
  the default so the 16:9 crop keeps a full 1280×720; fall back to `w640`
  only if the source file is too large.
- Free service, no key, no per-image license metadata; flags are drawn from
  Wikimedia Commons flag SVGs and are PD/CC0 in substance. Record
  `Source: https://flagcdn.com/ + <code>` in `review.html`.
- Perfect for "Which country's flag is this?" with four country-name
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
  &titles=File:<name>&prop=imageinfo&iiprop=url|extmetadata|size&iiurlwidth=1600
```

- Download `imageinfo[0].thumburl` (1600px wide) when present, else
  `imageinfo[0].url` if it isn't enormous; the 16:9 crop loses height, so
  start wide (see §4). Never use `upload.wikimedia.org`-style hotlinks in
  `media_url`.
- **License gate** — from `extmetadata`:
  - Accept: `LicenseShortName` / `License` containing `Public domain`,
    `PD`, `CC0`, `PDM` (e.g. `PD-old-100`, `PD-US`, `CC0 1.0`), `CC BY`
    (any version, e.g. `CC BY 2.0 / 3.0 / 4.0`), or `CC BY-SA` (any
    version). Also `UsageTerms` saying "Public domain" with no
    restrictions.
  - Reject: `CC BY-NC`, `CC BY-NC-SA`, `CC BY-ND`, `GFDL` alone, "fair
    use", and anything unverifiable.
  - CC-BY/CC-BY-SA files are usable **only if the author is determinable**
    (`extmetadata.Artist` or equivalent) — no author → reject, since the
    required credit line can't be written.
  - If `extmetadata` has no recognizable license → reject the file.
- Record from `extmetadata`: `ImageDescription` (identity!), `Artist`
  (author — strip any HTML), `LicenseShortName`, `LicenseUrl` (goes in the
  credit line and the review audit), plus the Commons file page URL
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
  `links[0].href` (`~medium.jpg` ≈ 1024px or `~large.jpg` ≈ 1920px — start
  at `~large` when present, since the 16:9 crop trims height; `~orig` is
  too big).
- NASA-authored imagery is generally not subject to copyright (public
  domain), but some items carry third-party credits — stick to items whose
  `secondary_creator`/credit is NASA or blank, and record `nasa_id` +
  title. Best for Solar System / Space / Astronomy / Earth-science
  subcategories.

### 2.5 The Met — art, artifacts, world culture (CC0)

- Search:
  `https://collectionapi.metmuseum.org/public/collection/v1.1/search?q=<query>&hasImages=true&limit=20`
  (the old `/v1/search` endpoint was retired 2026-10-01; v1.1 is Elastic-backed and
  returns `{total, objectIDs}`, paginated via `offset`/`limit`)
- Object: `https://collectionapi.metmuseum.org/public/collection/v1/objects/{objectID}`
- Require `isPublicDomain: true`. Use `primaryImageSmall` only when it's
  ≥ ~900px wide (enough for the 16:9 crop); otherwise `primaryImage`.
  Record `title`, `artistDisplayName`, `objectID`, `objectURL`.
- No key. 80 req/s limit. Best for art/history/culture questions ("Who
  painted this?", "Which civilization made this?").

### 2.6 Art Institute of Chicago — art (CC0, CORS-friendly)

- Search:
  `https://api.artic.edu/api/v1/artworks/search?q=<query>&fields=id,title,image_id,is_public_domain,artist_title,date_display`
- Require `is_public_domain: true`; image:
  `https://www.artic.edu/iiif/2/{image_id}/full/1686,/0/default.jpg`
  (1686px wide gives the 16:9 crop full 1280×720 headroom; IIIF serves any
  `full/{width},/` size).
- Record `title`, `artist_title`, `date_display`. No key.

### 2.7 Cleveland Museum of Art — art (CC0)

- `https://openaccess-api.clevelandart.org/api/artworks/?q=<query>&has_image=1`
- Require `share_license_status == "CC0"`; image from
  `images.web.url`. Record `title`, `creators[0].description`, `accession_number`.

### 2.8 Openverse — discovery fallback only (verify at source)

- `https://api.openverse.org/v1/images/?q=<query>&license=cc0,pdm,by,by-sa&filter_dead=true&page_size=20`
- Openverse aggregates from many sites and its own docs say license
  accuracy is not guaranteed. Only use it to *find* a candidate, then open
  the original source page and verify PD/CC0/CC-BY/CC-BY-SA there (and
  capture the author for the credit line) before downloading. Prefer the
  catalog above when it covers the topic.

## 3. Per-topic strategy

| Subcategory topic | Primary sources | Question shapes |
|---|---|---|
| Flags / Countries / Geography | FlagCDN, Commons maps & landmarks | Which country's flag/country is this? Where is this landmark? |
| Landmarks / Architecture | Commons (named file + description), Wikipedia REST | In which city/country is this? What is this structure? |
| Space / Solar System / Astronomy | NASA Image library, Commons | Which planet/moon/nebula is this? What mission? |
| Art / Paintings / History | Met, AIC, Cleveland, Commons | Who painted this? Which movement/civilization? |
| Animals / Nature / Birds | Commons (named species files), Openverse→source | Which animal/species is this? |
| Sports / Athletes / Celebrities / Pop culture | Commons CC-BY/CC-BY-SA portraits and event photos (many athletes and famous people have them — check per subject); PD historical photos | Who is this athlete/person? Which sport/team are they associated with? Prefer landscape or face-centered files that survive a 16:9 crop over tall action shots; keep facts evergreen (achievements pinned to years, not "current") |
| Religion / Language / Math | No reliable open-license photo pool that tests the topic (math → pattern mode fits better) | Prefer text or pattern mode; if image mode is forced, assess feasibility and stop rather than force |

Make sure the image actually tests the subcategory — a generic satellite
photo in a "Solar System" quiz is fine, a generic satellite photo in
"Football" is not.

## 4. Download & verification protocol (per image question)

1. **Find** 1–3 candidates from an approved source, using a query that names
   the subject, not the question. Prefer landscape/centered-subject files —
   every image is cropped to a 16:9 band next (step 4), and the crop has to
   keep the answer-critical content.
2. **License-gate** each candidate from its metadata before downloading
   (PD/CC0/CC-BY/CC-BY-SA only; for CC-BY/CC-BY-SA the author must be
   recoverable for the credit line).
3. **Download** a large rendition to the scratchpad
   (`.../opencode/` is pre-approved) with a descriptive filename:
   `curl -sL -A "<UA>" "<url>" -o <scratch>/<subject>.jpg`.
   Start wide — the 16:9 crop trims height: 1280–2048px wide when the
   source offers it (per-source sizes in §2), JPEG or PNG only (no SVG/WEBP
   in image mode). If the file is much bigger than ~2 MB, pick a smaller
   rendition from the same source.
4. **Choose the 16:9 crop and normalize.** Inspect first:
   `python3 .claude/skills/generate-questions/scripts/prepare_question_media.py
   --input <scratch>/<subject>.jpg` — it prints the EXIF-upright size and a
   suggested centered band. Then write the normalized file:
   `... prepare_question_media.py --input <scratch>/<subject>.jpg
   --output <scratch>/<subject>-16x9.jpg --crop <x>,<y>,<w>`
   (height is derived as w×9/16). Shift/shrink the band so the
   answer-critical content stays fully inside the frame — a flag's whole
   charge, the landmark, the animal, the person's face. The script enforces
   a ≥ 640px crop width, never upscales, and lands the file on a canonical
   exact-16:9 size (1280×720 down to 640×360). The raw download is never
   uploaded.
5. **View the normalized file with the Read tool.** Mandatory and cannot be
   skipped or replaced by metadata. Confirm against the checklist in §1 —
   identity, single answer, no giveaways, presentation — **and** that the
   16:9 crop kept everything the question depends on.
6. **Reject and swap** on any doubt (including a crop that cuts context) —
   go back to step 1. Never "make it work" with a weak image or a
   context-losing crop. It is fine to spend a few candidates per accepted
   image; it is not fine to lower the bar.
7. **Write the question** only after the image is accepted: short prompt
   (doesn't name the answer), exactly **4 options** (one correct, three
   plausible), `correct_index` 0–3, one-sentence explanation that adds a
   real detail. For CC-BY/CC-BY-SA, append the **mandatory credit line**
   as the explanation's final sentence — keep this fixed format, don't
   translate the keyword: `Credit: <author>, <license short name>,
   <license URL>.` Example: `Credit: Diego Delso, CC BY-SA 4.0,
   https://creativecommons.org/licenses/by-sa/4.0/.` PD/CC0 need no
   credit line. Write the rest natively in the target language/script.
8. **Pre-generate the question UUID** (`python3 -c "import uuid; print(uuid.uuid4())"`)
   — the storage object path is `<language_code>/<uuid>.<ext>`, so the SQL
   row must use that exact id.
9. **Upload** via `scripts/upload_question_media.py` (one run for the batch,
   after all images are accepted; the manifest points at the **normalized**
   files from step 4). Read the result JSON; only uploads with a
   `public_url` go into `questions.sql`.
10. **Log for `review.html`**: Commons/official title, source page URL,
    author, license short name + license URL, the public URL, and the
    scratchpad filename if useful.

### If a download fails

| Symptom | Action |
|---|---|
| HTTP 403/429 | Wait a moment, retry once with the proper User-Agent. Still failing → reject source/swap candidate. |
| Wrong content type (HTML error page saved as .jpg) | Check with `file <path>`; reject unless it reports JPEG/PNG. |
| Image too small/large | Pick a different rendition from the same source (`iiurlwidth`, FlagCDN size, NASA `~medium`/`~large`). If even the largest rendition can't give a ≥ 640px-wide 16:9 crop, reject the candidate. Never upscale. |
| 16:9 crop would cut the subject/context | Shift or shrink the band and re-inspect; if no band keeps the answer-critical content, reject and swap candidates — never ship a context-losing crop. |
| No open-license candidate after a few tries | Swap the subject for an easier one. If several subjects in a row are impossible, revisit the Step 1 image-capability assessment. |

## 5. Recording & licensing notes

- Each image question's card in `review.html` must carry a source line in
  exactly this shape (HTML-escape the text; the URL goes in `href`):

  ```html
  <p class="source">Source: <a href="https://commons.wikimedia.org/wiki/File:Taj_Mahal_(Edited).jpeg" rel="noopener">File:Taj Mahal (Edited).jpeg</a> — Yann Forget, Public domain. Stored at <code>question-media/en/&lt;uuid&gt;.jpg</code>.</p>
  ```

  For CC-BY/CC-BY-SA, link the license too:

  ```html
  <p class="source">Source: <a href="https://commons.wikimedia.org/wiki/File:Example.jpg" rel="noopener">File:Example.jpg</a> — Jane Doe, <a href="https://creativecommons.org/licenses/by-sa/4.0/">CC BY-SA 4.0</a>. Stored at <code>question-media/en/&lt;uuid&gt;.jpg</code>.</p>
  ```

- **CC-BY/CC-BY-SA images carry the credit line in the question's
  `explanation`** — mandatory, as the explanation's final sentence, in
  exactly this shape (fixed keyword and punctuation; the URL is the license
  URL from the source metadata):

  ```
  Credit: <author>, <license short name>, <license URL>.
  ```

  Example: `... Shah Jahan as a mausoleum for Mumtaz Mahal. Credit: Diego Delso, CC BY-SA 4.0, https://creativecommons.org/licenses/by-sa/4.0/.`
  This is what lets the app satisfy the attribution requirement without a
  credit UI. PD/CC0 images need no credit line, but the source line above
  is still written for every image.
- `questions.sql` carries the `media_url` plus, for CC-BY/CC-BY-SA, the
  credit line embedded in `explanation`; the fuller attribution trail
  (source page, license link, stored path) lives in `review.html` and, 
  through it, the batch folder next to the project.
- If you cannot prove PD/CC0/CC-BY/CC-BY-SA for a candidate, it does not
  exist for this skill. There is always another subject.
