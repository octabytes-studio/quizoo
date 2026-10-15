# Image sourcing & verification reference (generate-questions, image/all modes)

Read this file in full before any run whose mode includes `image`
(`-mode image`, `-mode all`). It is the approved-source catalog, the license
gate, and the verification protocol for every image question this skill
authors. `SKILL.md`'s Hard rule 6 summarizes the non-negotiables; this file is
the detail.

Captured 2026-10-05; license policy expanded to CC-BY / CC-BY-SA on
2026-10-06; images pinned to a fixed 16:9 frame (and questions to four
options) on 2026-10-10; source catalog expanded with public-domain art
museums, national libraries/archives and government science agencies on
2026-10-15 (see §2.9–2.33, plus the rejected-source list in §6). If a
source's API shape or license policy changes, update this file — don't
silently drift.

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
  approved catalog in this section when it covers the topic.

### 2.9 Europeana — discovery fallback only (verify at source)

- `https://api.europeana.eu/` (free account + API key required).
- Aggregates millions of digitised objects from thousands of European
  galleries, libraries, archives and museums. Europeana's **metadata** is
  CC0, but a **digital object's** rights are whatever the provider
  declared (`edm:rights` / `europeana:rights`). Filter to the `PD`, `CC0`,
  `CC BY`, `CC BY-SA` rights statements, then open the provider's own
  record and verify + capture the author before downloading.
- Same "discovery only" discipline as Openverse (§2.8): prefer the direct
  institutional catalog when it covers the topic; use Europeana to reach
  small European institutions that have no API of their own.

### 2.10 GBIF — discovery/reference only (verify at source)

- `https://api.gbif.org/v1/` (no key for occurrence search; bulk image
  downloads may need a free account).
- Occurrence **datasets** can only be CC0, CC-BY or CC-BY-NC, but the
  **image** license is per-media and is frequently more restrictive than
  the record. Read the media's own license URL and accept only
  PD/CC0/CC-BY/CC-BY-SA. Many GBIF images are mirrored from iNaturalist —
  prefer §2.32 and do the license filtering there.
- Use it to locate a specimen/occurrence for a species, then verify the
  media license at the publisher.

### 2.11 Smithsonian Open Access — art, natural history, history, space, design (CC0)

- Search/records:
  `https://api.si.edu/openaccess/api/v1.0/search?q=<query>&api_key=<key>`
  and `https://api.si.edu/openaccess/api/v1.0/content/<id>?api_key=<key>`
  (free key from `api.data.gov/signup/`; the same key serves many
  US-government APIs).
- **CC0.** 2.8M+ images across 30+ units: Smithsonian American Art
  Museum, National Portrait Gallery, National Air and Space Museum,
  National Museum of Natural History (birds, botany, entomology, fishes,
  herps, mammals, minerals, paleo, anthropology), National Museum of
  African American History & Culture, National Museum of the American
  Indian, National Museum of American History, Cooper Hewitt, Hirshhorn,
  Archives of American Art, EEPA, Freer|Sackler, Smithsonian Libraries.
- **Gate on the media-level `usage.access`, not the record-level flag.**
  A record's `metadata_usage.access` can read CC0 while a specific
  `media.usage.access` does not — only use an image whose
  **media-level** `usage.access` is CC0, and take its `content`/`ids`
  URL. Objects still in copyright expose CC0 metadata but **no media
  file** at all.
- Record: title, unit/creator, `media.usage` (access + CC0), the object
  page URL (`record_link`), and the `idsId`/CDN image URL.
- Broadest single addition for natural-history specimens, portraits,
  American history and space-history objects. Some unit pages (e.g.
  `npg.si.edu`) bot-block scripted page loads; the API and CDN do not.

### 2.12 Rijksmuseum — Dutch/European art, decorative arts (CC0/PD; some CC-BY)

- Search (no key): `https://data.rijksmuseum.nl/search/collection?...`
  (Linked Art search — returns identifiers; resolve each with the
  Persistent Identifier Resolver and read `dc:rights`/`edm:rights`).
  IIIF image: `https://iiif.micr.io/{id}/full/{size}/0/default.jpg`.
  OAI-PMH for bulk: `https://data.rijksmuseum.nl/oai`.
- Most objects are **CC0 / Public Domain Mark**; some are **CC BY 4.0**
  (then the credit line is required, attributing "Rijksmuseum"); a
  minority are rights-restricted → reject.
- Best for Dutch Golden Age and European paintings, decorative arts,
  prints and history.

### 2.13 National Gallery of Art, Washington — Western painting & sculpture (CC0)

- No live search API. Download the open-data CSVs from
  `github.com/NationalGalleryOfArt/opendata` (`data/published_images.csv`,
  `data/objects.csv`) and join on `depictstmsobjectid` → `objectid`.
  Images via IIIF: `https://api.nga.gov/iiif/{uuid}/full/!1600,/0/default.jpg`
  (`info.json` for native dimensions).
- **Gate: only rows with `published_images.openaccess = 1`** (and
  `viewtype = "primary"`). `openaccess = 0` rows are resolution-capped /
  rights-restricted and are **not** open access. CC0.
- Best for Western painting/sculpture, prints and decorative arts;
  `assistivetext` gives an auto-description field.

### 2.14 Getty (Open Content Program) — European art, antiquities, photography (CC0)

- Collection data and images on `getty.edu` (no single public search
  endpoint — browse the collection and use the object's image URL).
- Getty-owned works in the public domain marked with the **CC0 icon** are
  CC0. (Getty's collection *text* is CC-BY per record, but that does not
  cover the images.)
- **Gate: confirm the object page shows the CC0 Open Content marker** —
  per-image `VisualItem.subject_to` rights are inconsistently populated on
  older records. Reject anything without the marker.
- Best for European painting, antiquities, photography, illuminated
  manuscripts.

### 2.15 Walters Art Museum — world art & manuscripts (CC0)

- Static data files (v1 API retired 2023):
  `github.com/WaltersArtMuseum/api-thewalters-org` (`art.csv`,
  `media.csv`), plus `art.thewalters.org` object pages and PURLs. High-res
  manuscript images at `thedigitalwalters.org`.
- **CC0** for digital images of public-domain works and the associated
  metadata (the long-form object text is GFDL — don't use it as image
  rights). Exceptions apply to loaned/under-copyright works (small
  derivative only) → reject those.
- Best for world art, artifacts and illuminated manuscripts.

### 2.16 Minneapolis Institute of Art (Mia) — world art (CC0 / Public Domain Mark)

- Metadata JSON on GitHub; object pages expose a download button. No
  formal search API.
- **Gate: only works marked Public Domain (CC PDM).** Copyrighted / unclear
  works are offered only at a smaller size and are restricted. (Mia's own
  site *text* is CC BY; that does not license the images.)
- Best for world art across 5,000 years; 50k+ PD works.

### 2.17 Paris Musées — French/European art, history, photography (CC0)

- GraphQL API: `apicollections.parismusees.paris.fr` — free account + auth
  token required. Request `fieldVisuelsPrincipals { entity { vignette } }`
  for the available image.
- **CC0** for the images Paris Musées publishes as Open Content (HD
  ~3000px); everything else is "tous droits réservés" and must be
  rejected. The public API exposes only the free images + small
  thumbnails.
- Best for French/European art, history and 19th–20th c. photography
  (Atget, Marville, Carjat).

### 2.18 SMK — National Gallery of Denmark — Danish/European art (CC0 / Public Domain Mark)

- `https://api.smk.dk/api/v1/art/search?keys=*&filters=[public_domain:true]&filters=[has_image:true]&offset=0&rows=10`
  (no key). **Pass `filters` as a repeated parameter — one `[field:value]`
  bracket per occurrence**; concatenating both brackets into one value is
  accepted by the server but silently ignores the second condition.
  Full-res via the item's `image_native` (downloadable JPEG) or IIIF
  `image_iiif_id` (`{id}/{region}/{size}/{rotation}/default.jpg`).
- Filter `public_domain:true`; `rights` is usually Public Domain Mark 1.0.
  Credit "SMK / Statens Museum for Kunst" as good practice.
- Best for Danish/European art.

### 2.19 Yale University Art Gallery — world art (public domain)

- IIIF/LUX services: `https://media.art.yale.edu/` (IIIF collection) and
  `https://lux.collections.yale.edu/` (Presentation manifests); images are
  downloadable from object records that show a download link.
- Yale's open-access policy: public-domain works may be used freely, and
  the rights status is shown beneath the image. **Only works with a
  download link** are open access; the PD statement is "without
  warranty," so confirm it genuinely is PD.
- Best for world art (154k+ works).

### 2.20 Cooper Hewitt — design, posters, textiles, objects (CC0)

- GraphQL API: `https://api.collection.cooperhewitt.org/` (token
  required); docs at `apidocs.cooperhewitt.org`. Each media item carries a
  `cc0: true` flag when it is licensed CC0.
- **Gate: only media with `cc0: true`.** Collection *data* is CC0, but the
  images are only CC0 where that flag is present.
- Best for design, posters, wallcoverings, textiles and decorative
  objects. (Also reachable through Smithsonian Open Access, §2.11.)

### 2.21 Library of Congress — history, photography, posters, maps (public domain / "no known restrictions")

- `https://www.loc.gov/` JSON API (append `?fo=json`) and the Prints &
  Photographs Online Catalog (`https://www.loc.gov/pictures/api`). No key.
- **Gate:** only items whose Rights Advisory reads **"No known
  restrictions on publication."** LOC does not own rights and does not
  guarantee status — "Publication may be restricted" or "Rights not
  evaluated" → reject. Many pre-1930 and US-government works are PD; the
  FSA/OWI and Prokudin-Gorskii collections are reliably PD.
- Best for US & world history, Depression-era color photography, WPA
  posters, maps, Japanese prints and Civil War photographs.

### 2.22 National Archives (NARA) — US history & photographs (US-government public domain)

- `https://catalog.archives.gov/api/v2/records/search?...` (free api key;
  send it in the `x-api-key` header). IIIF image delivery.
- NARA records are US-government works → public domain, with rare
  exceptions (third-party quotations / copyrighted attachments) — check
  the record's rights note. API use requires displaying the notice
  "This product uses the National Archives Catalog API but is not endorsed
  or certified by the National Archives and Records Administration."
- Best for historical photographs, documents, maps and presidential-library
  material.

### 2.23 NYPL Digital Collections — historical photos, maps, prints (CC0 content; **API is non-commercial**)

- `https://api.repo.nypl.org/api/v2/items/search?...&publicDomainOnly=true`
  (free token; header `Authorization: Token token="<t>"`). Image links are
  returned for public-domain items.
- **Gate:** `publicDomainOnly=true` items carry the CC0 / no-known-U.S.-
  copyright designation. **But the API service itself is licensed for
  non-commercial use** — a commercial product must confirm those terms,
  attribute "From the New York Public Library," or (cleaner) use NYPL's
  public-domain bulk data release
  (`github.com/NYPL-publicdomain/data-and-utilities`) or the same PD items
  via Wikimedia/LOC.
- Best for historical photographs, maps, prints and illustrations.

### 2.24 Internet Archive — book scans & natural-history illustrations (per-item; default ToS non-commercial)

- Metadata API: `https://archive.org/metadata/<identifier>`; files under
  `https://archive.org/download/<identifier>/`. No key for reads.
- **Gate:** the site's default Terms of Use are non-commercial; that is
  overridden **only** when the item, uploader or sponsoring institution
  states an explicit license. Use only items with a clear
  PD/CC0/CC-BY/CC-BY-SA statement — treat it like Openverse (§2.8).
- Best for public-domain book scans and natural-history illustrations
  (often the origin behind BHL/Wikimedia files).

### 2.25 US Fish & Wildlife Service — wildlife, birds, fish, plants (public domain)

- `https://www.fws.gov/media/library` and
  `https://www.fws.gov/search/images`. Each item carries a "Media Usage
  Rights/License" field.
- **Gate:** use items whose media license reads **Public Domain**.
  Photographer names are given for credit (courtesy).
- Best for wildlife, birds, fish, plants, habitats and conservation.

### 2.26 NOAA Photo Library — weather, oceans, coasts, marine life (public domain)

- `https://www.noaa.gov/noaa-collections/photo-library` (~70,000 images;
  browse/search galleries, per-image "Download").
- **Public domain** and not subject to copyright. The **exception is
  video**, which may use third-party footage — images only.
- Best for weather, oceans, marine life, coasts, sanctuaries, geodesy and
  satellite/space-weather imagery.

### 2.27 USGS Multimedia Gallery — geology, landscapes, water, maps (public domain)

- `https://www.usgs.gov/products/multimedia-gallery/images`. Gallery items
  are public domain unless otherwise noted (a "USGS photo by X" credit is
  normal and should be carried).
- Best for geology, volcanoes, earthquakes, landscapes, water, historical
  survey photography, satellite imagery and minerals/fossils.

### 2.28 USDA ARS Image Gallery — plants, crops, insects, microscopy (public domain)

- `https://www.ars.usda.gov/oc/images/image-gallery/` (~6,500 images;
  categories: Plants, Animals, Crops, Insects, Food, People, Lab Research,
  Electron/scanning-microscopy).
- **Public domain** unless otherwise indicated. Credit "Photo courtesy of
  USDA Agricultural Research Service" (or the named photographer); images
  must not imply ARS endorsement.
- Best for plants/crops, insects, agricultural and microscopy imagery.

### 2.29 National Park Service — landscapes, geology, wildlife, historic sites (public domain)

- `https://npgallery.nps.gov/` and the NPS Data API
  (`https://www.nps.gov/subjects/digital/nps-data-api.htm`, free key),
  which returns park content incl. images.
- **Gate:** images **credited to NPS without a © symbol are public
  domain**; images with a © symbol, or credited to anyone other than NPS,
  must not be presumed PD → reject or verify with the host park. Some
  museum-collection images require a permission agreement — skip those.
- Best for landscapes, geology, wildlife and historic sites.

### 2.30 ESA/Hubble & ESO — space & astronomy (CC-BY 4.0)

- ESA/Hubble: `https://esahubble.org/images/`; ESO:
  `https://www.eso.org/public/images/`.
- **CC BY 4.0.** The credit must be reproduced unaltered ("ESA/Hubble", or
  the ESO credit) and not hidden — this becomes the mandatory `Credit:`
  line. Logos are excluded. Individual images sometimes carry additional
  third-party credits — check the caption.
- Best for planets, moons, nebulae, galaxies, telescopes and astronomy.

### 2.31 Biodiversity Heritage Library — natural-history illustrations (PD/CC0/CC per item)

- API: `https://www.biodiversitylibrary.org/api3` (free API key from
  `biodiversitylibrary.org/getapikey.aspx`); page images + metadata. The
  image corpus is also on the AWS Open Data bucket `s3://bhl-open-data`.
- **Gate:** per-item — the corpus is "Public Domain, CC0, or Creative
  Commons"; accept PD/CC0/CC-BY/CC-BY-SA (author recoverable for BY/BY-SA)
  and reject the rest.
- Best for historical natural-history plates: botanical, zoological,
  entomological and ornithological illustrations.

### 2.32 iNaturalist — species identification across taxa (CC0/CC-BY/CC-BY-SA — filter!)

- `https://api.inaturalist.org/v1/observations?...&quality_grade=research&photo_license=cc0,cc-by,cc-by-sa&photos=true`.
  Photos served from the `inaturalist-open-data` domain are openly
  licensed; photos on `static.inaturalist.org` are not.
- **The `photo_license` filter is mandatory** — the default pool also
  contains **CC-BY-NC/ND**, which are rejected. Confirm the *individual
  photo's* license in the response, and capture the license + author at
  download time, since observers can change a photo's license later.
- Best for species questions across taxa (plants, animals, fungi,
  insects) — a much deeper pool than Commons for regionally specific or
  obscure species. Prefer research-grade observations.

### 2.33 Museums Victoria — Australia/Oceania science, history, culture (CC-BY / Public Domain)

- JSON API under `https://collections.museumsvictoria.com.au/api/`. Each
  media object carries a `rightsStatement` and a `licence` block
  (`shortName`, `uri`).
- **Gate:** accept items whose licence is **CC BY** or **Public Domain**;
  skip third-party-copyright material (the API mixes them).
- Best for Australia/Oceania natural sciences, history, technology and
  cultural collections — broadens coverage beyond North America/Europe.

## 3. Per-topic strategy

| Subcategory topic | Primary sources | Question shapes |
|---|---|---|
| Flags / Countries / Geography | FlagCDN, Commons maps & landmarks, LOC/CIA-style PD maps | Which country's flag/country is this? Where is this landmark? |
| Landmarks / Architecture | Commons (named file + description), Wikipedia REST, Smithsonian, NPS | In which city/country is this? What is this structure? |
| Space / Solar System / Astronomy | NASA Image library, ESA/Hubble, ESO, Commons | Which planet/moon/nebula is this? What mission? |
| Art / Paintings / Sculpture | Met, AIC, Cleveland, Smithsonian, Rijksmuseum, NGA, Getty, Walters, Mia, Paris Musées, SMK, Yale, Cooper Hewitt, Europeana→source, Commons | Who painted/made this? Which movement/civilization? |
| US / world history & vintage photography | LOC (FSA/OWI, "no known restrictions"), NARA, NYPL, Smithsonian, Internet Archive, Commons | Which period/place is this? Who is this? What event? |
| Animals / Nature / Birds | Commons (named species files), iNaturalist (filter!), USFWS, NOAA, USGS, BHL, Openverse→source | Which animal/species is this? |
| Plants / Agriculture / Insects / Fossils | USDA ARS, BHL, Smithsonian (NMNH), iNaturalist, Commons | Which plant/crop/insect is this? |
| Earth science / Geology / Volcanoes / Water | USGS, NPS, NOAA, Commons | What landform/process is this? Where is this? |
| Weather / Oceans / Marine life | NOAA, USFWS, Commons | What weather/ocean phenomenon is this? |
| National parks / Landscapes | NPS, USGS, NOAA, Commons | Which park/landscape is this? |
| Sports / Athletes / Celebrities / Pop culture | Commons CC-BY/CC-BY-SA portraits and event photos (many athletes and famous people have them — check per subject); Smithsonian National Portrait Gallery; PD historical photos | Who is this athlete/person? Which sport/team are they associated with? Prefer landscape or face-centered files that survive a 16:9 crop over tall action shots; keep facts evergreen (achievements pinned to years, not "current") |
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
   recoverable for the credit line). **Gate on the image/media-level
   rights field, never the collection-level statement** — the field to
   read is named in that source's §2 entry (e.g. Smithsonian
   `media.usage.access`, NGA `published_images.openaccess = 1`, LOC Rights
   Advisory "No known restrictions", Rijksmuseum `dc:rights`, iNaturalist
   `photo_license`, Cooper Hewitt `cc0`, FWS "Media Usage Rights",
   Europeana `edm:rights`, GBIF per-media license). When a collection-level
   claim and the per-image value disagree, the **per-image value wins**.
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
- The same `Credit:` line covers the newly added attribution-required
  sources: **ESA/Hubble** and **ESO** (CC BY 4.0 — reproduce the credit
  "ESA/Hubble" or the ESO credit verbatim, never hidden), **Rijksmuseum**
  when the object is CC BY (credit "Rijksmuseum"), and any CC-BY/CC-BY-SA
  item from Smithsonian, Museums Victoria, BHL, iNaturalist or Europeana.
- If you cannot prove PD/CC0/CC-BY/CC-BY-SA for a candidate, it does not
  exist for this skill. There is always another subject.

## 6. Rejected sources (do not add)

Commonly suggested but they fail the license gate (§0.2) and/or the
re-host rule (§0.3). Never source images from these:

| Source | Why it's rejected |
|---|---|
| **Harvard Art Museums** | API is **non-commercial use only** *and* requires displaying images from its own URL rather than re-hosting a copy — fails both the license gate and the re-host rule. |
| **Unsplash** | Left CC0 in 2017 for the bespoke "Unsplash License" (prohibits compiling images to replicate a competing service); no longer public domain. |
| **Pexels** | Custom "Pexels License" (CC0-like but not CC0), with its own extra restrictions. |
| **Pixabay** | "Pixabay Content License" since 2019-01-09 (only pre-2019 uploads were CC0); the per-image upload date can't be verified reliably. |
| **Science Museum Group (UK)** | Images are CC BY-**NC**-SA / CC BY-**NC**-ND; only the metadata is CC0. |
| **National Gallery, London** | Images are CC BY-**NC**-ND; only titles/facts are CC0/CC-BY. |
| **Victoria & Albert Museum** | Images sit under bespoke V&A terms (not an accepted CC license), many "all rights reserved". |
| **David Rumsey Map Collection** | CC BY-**NC**-SA (NonCommercial). Source PD-by-age maps via LOC / Internet Archive / Commons instead. |
| **Flickr "The Commons" (NKCR)** | "No known copyright restrictions" is an assertion, not a license, and carries no warranty (at least one member, the Smithsonian, contradicts it). Prefer Flickr items explicitly licensed CC0/PDM/CC-BY/CC-BY-SA, or skip Flickr altogether. |

If a candidate's only license is NC/ND, GFDL-only, "fair use", a stock
preview, or its terms forbid re-hosting, it belongs here — not in §2.
