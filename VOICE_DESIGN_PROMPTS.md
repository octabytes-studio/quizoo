# Quizoo — ElevenLabs Voice Design Prompts

Voice Design prompts for the **"Quizoo Host"** narrator voice in every language
Quizoo serves questions in. The list comes from the live `languages` table
(all `is_active = true`), in `sort_order`:

| # | Code | Language | Dialect / register chosen | `voice_id` today |
|---|------|----------|---------------------------|------------------|
| 1 | `en` | English | General American | `MN7bvz2v9Z55XnbHzEk4` (set) |
| 2 | `ur` | Urdu | Standard Pakistani Urdu (educated Karachi) | `hJjeT6ze0Ivs3MpeFd3t` (set) |
| 3 | `hi` | Hindi | Standard Khari Boli Hindi (educated Delhi) | — |
| 4 | `ar` | Arabic | Modern Standard Arabic (Fusha), pan-Arab broadcast | — |
| 5 | `fr` | French | Standard Parisian French | — |
| 6 | `es` | Spanish | Neutral Latin American (Mexico-based *español neutro*) | — |

**Shared persona:** male, early 30s, warm and elegant quiz-show host. Every
prompt uses the same persona and delivery wording. Only the dialect sentences
change, so the host sounds like the same character in every language.

> **🤖 AI agents:** if you were pointed at this file to create a voice prompt
> for a new language (or to redo an existing one), go straight to
> **§6 "Agent playbook"** and follow it step by step. It is the source of
> truth for how every prompt in this file was built. §1–§5 are the reference
> material it relies on.

---

## 1. Read this first: getting the same voice twice

ElevenLabs Voice Design is generative. **In the web UI, the same prompt gives
you a different voice every time.** The UI only exposes *Loudness* and
*Guidance scale*. It has no seed control, so no prompt wording can make the UI
repeat a voice. Two things do work:

1. **Save the voice once and reuse its `voice_id` (the real guarantee).** A
   saved voice stays in your ElevenLabs library permanently. Put its
   `voice_id` in `languages.voice_id`, and the `generate-audios` skill will
   narrate every question with exactly that voice. Never "recreate" a voice
   that already exists; reuse the id.
2. **Generate through the API with a fixed `seed` (the backup).** The
   `POST /v1/text-to-voice/design` endpoint takes a `seed`. With the same
   **seed + prompt + preview text + model + guidance_scale + loudness +
   should_enhance**, you should get the same previews back. This is how you
   rebuild a voice in another ElevenLabs account, or after one is deleted.
   Run each seed twice once to confirm the previews match. If ElevenLabs later
   upgrades the model on its side, results can change, so option 1 is still
   the primary guarantee.

To keep things reproducible, **never change a character** of a prompt or
preview text below once you've used it. Record every setting in the log table
in §4.

### Fixed generation settings (all languages)

| Setting | Value | Why |
|---|---|---|
| Model | `eleven_ttv_v3` (UI: *Eleven v3*) | Matches the v3 TTS model `generate-audios` narrates with (`eleven_v3_conversational`) |
| Guidance scale | `5` | ElevenLabs default. Higher follows the prompt more strictly; try `7` only if the accent drifts, and record it |
| Loudness | `0.5` | Default. Identical for every language, so volume doesn't jump when a player switches language |
| `should_enhance` | `false` | Enhancement has an LLM rewrite the prompt differently on each call, which breaks reproducibility |
| `auto_generate_text` | `false` | Always use the fixed preview text below. The preview text affects the voice |
| Quality | leave unset | Setting it trades away variety |
| Seed | per language (below) | Only available via the API |

---

## 2. The prompts

Paste **Voice prompt** into *Describe the voice* and **Preview text** into
the text box (turn off *auto-generate text*). Both stay under ElevenLabs'
limits: 1000 characters for the prompt, and 100–1000 for the preview text.

### 🇺🇸 English (`en`), General American · seed `101`

**Voice prompt**

```
Native American English speaker with a neutral General American accent, the clean, educated standard heard on national public radio and in premium documentary narration. Relaxed, open American vowels, a lightly flapped 't' between vowels, and a clear rhotic 'r'. Easygoing American friendliness with the natural rising and falling intonation of spoken English questions. Male, early 30s. Perfect studio-quality audio: close-mic, clean and dry, with a silent background. Persona: elegant, friendly quiz show host. Emotion: warm, confident, gently curious. Smooth, rich mid-low baritone with a clear, bright presence; polished and articulate, every word crisp and easy to understand. Measured, moderate pace with natural pauses before key words. A slight smile in the voice: inviting, encouraging and refined, with calm, restrained energy.
```

**Preview text**

```
Welcome back to Quizoo! Let's see how much you really know. Which planet is known as the Red Planet? In The Wizard of Oz, what is the name of Dorothy's dog? And now, a tricky one: roughly how long does sunlight take to reach the Earth? Take your time, trust your instincts, and choose the answer you believe is correct.
```

### 🇵🇰 Urdu (`ur`), standard Pakistani Urdu · seed `102`

**Voice prompt**

```
Native Pakistani Urdu speaker with the refined, standard Urdu of an educated Karachi native, with the clear pronunciation of a PTV newsreader. Authentic Urdu sounds: a distinct deep 'q' separate from 'k', throaty 'kh' and 'gh', clear 'f' and 'z', soft dental 't' and 'd', and gentle nasalized vowels. Graceful, courteous tehzeeb in the delivery, with the natural musical rise and fall of spoken Urdu. Male, early 30s. Perfect studio-quality audio: close-mic, clean and dry, with a silent background. Persona: elegant, friendly quiz show host. Emotion: warm, confident, gently curious. Smooth, rich mid-low baritone with a clear, bright presence; polished and articulate, every word crisp and easy to understand. Measured, moderate pace with natural pauses before key words. A slight smile in the voice: inviting, encouraging and refined, with calm, restrained energy.
```

**Preview text**

```
کوئزو میں ایک بار پھر خوش آمدید! آئیے دیکھتے ہیں کہ آپ کتنا جانتے ہیں۔ سورج سے چوتھے نمبر پر کون سا سیارہ ہے؟ پاکستان کا قومی شاعر کون ہے؟ اور اب ایک مشکل سوال: سورج کی روشنی کو زمین تک پہنچنے میں تقریباً کتنا وقت لگتا ہے؟ اطمینان سے سوچیے، اور وہ جواب چنیے جو آپ کے خیال میں درست ہے۔
```

### 🇮🇳 Hindi (`hi`), standard Khari Boli Hindi · seed `103`

**Voice prompt**

```
Native Indian Hindi speaker with the clean, standard Khari Boli Hindi of an educated Delhi native, combining the clarity of a Doordarshan or All India Radio announcer with modern, conversational warmth. Crisp distinction between retroflex and dental consonants, fully aspirated sounds, and natural Hindi vowel lengths. Respectful, graceful delivery with the natural melodic flow of spoken Hindi. Male, early 30s. Perfect studio-quality audio: close-mic, clean and dry, with a silent background. Persona: elegant, friendly quiz show host. Emotion: warm, confident, gently curious. Smooth, rich mid-low baritone with a clear, bright presence; polished and articulate, every word crisp and easy to understand. Measured, moderate pace with natural pauses before key words. A slight smile in the voice: inviting, encouraging and refined, with calm, restrained energy.
```

**Preview text**

```
क्विज़ू में आपका फिर से स्वागत है! आइए देखते हैं कि आप कितना जानते हैं। सूर्य से चौथा ग्रह कौन सा है? भारत का राष्ट्रीय पक्षी कौन सा है? और अब एक कठिन सवाल: सूर्य की रोशनी को पृथ्वी तक पहुँचने में लगभग कितना समय लगता है? आराम से सोचिए, और वह उत्तर चुनिए जो आपको सही लगता है।
```

### 🇸🇦 Arabic (`ar`), Modern Standard Arabic · seed `104`

**Voice prompt**

```
Native Arabic speaker reading Modern Standard Arabic (Fusha) with a neutral, pan-Arab broadcast pronunciation, like a premium documentary narrator on a major Arabic news network. Precise, full emphatic consonants, a true deep 'qaf', clear throat sounds for 'ayn' and 'ha', and correct long and short vowels. Eloquent, dignified classical elegance with the natural cadence of formal spoken Arabic. Male, early 30s. Perfect studio-quality audio: close-mic, clean and dry, with a silent background. Persona: elegant, friendly quiz show host. Emotion: warm, confident, gently curious. Smooth, rich mid-low baritone with a clear, bright presence; polished and articulate, every word crisp and easy to understand. Measured, moderate pace with natural pauses before key words. A slight smile in the voice: inviting, encouraging and refined, with calm, restrained energy.
```

**Preview text**

```
أهلاً بكم من جديد في كويزو! لنرَ مدى معرفتكم. ما هو الكوكب الرابع من حيث البعد عن الشمس؟ من هو مؤلف كتاب المقدمة الشهير؟ والآن سؤال صعب: كم من الوقت يستغرق ضوء الشمس تقريباً للوصول إلى الأرض؟ خذوا وقتكم، وثقوا بحدسكم، واختاروا الإجابة التي ترونها صحيحة.
```

### 🇫🇷 French (`fr`), standard Parisian French · seed `105`

**Voice prompt**

```
Native French speaker from Paris with standard metropolitan French pronunciation, with the polished, cultivated diction of a France Inter radio host. Soft uvular 'r', pure rounded vowels, smooth natural liaisons, and the natural French melody with a gentle rising intonation on questions. Male, early 30s. Perfect studio-quality audio: close-mic, clean and dry, with a silent background. Persona: elegant, friendly quiz show host. Emotion: warm, confident, gently curious. Smooth, rich mid-low baritone with a clear, bright presence; polished and articulate, every word crisp and easy to understand. Measured, moderate pace with natural pauses before key words. A slight smile in the voice: inviting, encouraging and refined, with calm, restrained energy.
```

**Preview text**

```
Bienvenue à nouveau sur Quizoo ! Voyons ce que vous savez vraiment. Quelle est la quatrième planète en partant du Soleil ? Qui a peint La Joconde ? Et maintenant, une question plus difficile : combien de temps la lumière du Soleil met-elle, environ, pour atteindre la Terre ? Prenez votre temps, faites confiance à votre intuition, et choisissez la réponse qui vous semble juste.
```

### 🇲🇽 Spanish (`es`), neutral Latin American · seed `106`

**Voice prompt**

```
Native Mexican Spanish speaker using neutral Latin American Spanish (español neutro), the clean standard of professional Latin American dubbing and news broadcasting. Seseo pronunciation, crisp pure vowels, soft consonants, a lightly tapped 'r' and a clear rolled 'rr', with warm, melodic Latin American intonation. Male, early 30s. Perfect studio-quality audio: close-mic, clean and dry, with a silent background. Persona: elegant, friendly quiz show host. Emotion: warm, confident, gently curious. Smooth, rich mid-low baritone with a clear, bright presence; polished and articulate, every word crisp and easy to understand. Measured, moderate pace with natural pauses before key words. A slight smile in the voice: inviting, encouraging and refined, with calm, restrained energy.
```

**Preview text**

```
¡Qué gusto tenerte de vuelta en Quizoo! Veamos cuánto sabes realmente. ¿Cuál es el cuarto planeta desde el Sol? ¿Qué ciudad es la capital de Colombia? Y ahora, una pregunta difícil: ¿cuánto tiempo tarda aproximadamente la luz del Sol en llegar a la Tierra? Tómate tu tiempo, confía en tu instinto y elige la respuesta que creas correcta.
```

---

## 3. Reproducible generation via the API

Use this to regenerate a voice with its recorded seed, for example in a second
ElevenLabs account (see §5.1). Replace `<...>` with the prompt and preview text
from §2, character for character.

```sh
# 1. Design: returns 3 previews (base64 audio + a temporary generated_voice_id each)
curl -s https://api.elevenlabs.io/v1/text-to-voice/design \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model_id": "eleven_ttv_v3",
    "voice_description": "<Voice prompt>",
    "text": "<Preview text>",
    "seed": 104,
    "guidance_scale": 5,
    "loudness": 0.5,
    "should_enhance": false,
    "auto_generate_text": false
  }' > previews_ar.json

# 2. Listen: decode each preview to an mp3
python3 -c "import json,base64;d=json.load(open('previews_ar.json'))
for i,p in enumerate(d['previews']):open(f'ar_preview_{i}.mp3','wb').write(base64.b64decode(p['audio_base_64']));print(i,p['generated_voice_id'])"

# 3. Save the preview you picked as a permanent voice -> returns the real voice_id
curl -s https://api.elevenlabs.io/v1/text-to-voice \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"voice_name": "Quizoo Host - Arabic (ar)", "voice_description": "<Voice prompt>", "generated_voice_id": "<id from step 2>"}'
```

> The key you use needs the Voice Design / voices-write permissions. The
> current `001` key is missing `voices_read`, so a restricted key may be
> refused.

---

## 4. Generation log (fill in as you go)

Record which of the 3 previews you kept (index 0/1/2). The same seed
reproduces the same set of 3, and the index tells you which one to keep.

| Code | Seed | Guidance | Loudness | Preview # kept | Saved voice name | `voice_id` | Date |
|---|---|---|---|---|---|---|---|
| en | 101 | 5 | 0.5 | | Quizoo Host - English (en) | | |
| ur | 102 | 5 | 0.5 | | Quizoo Host - Urdu (ur) | | |
| hi | 103 | 5 | 0.5 | | Quizoo Host - Hindi (hi) | | |
| ar | 104 | 5 | 0.5 | | Quizoo Host - Arabic (ar) | | |
| fr | 105 | 5 | 0.5 | | Quizoo Host - French (fr) | | |
| es | 106 | 5 | 0.5 | | Quizoo Host - Spanish (es) | | |

If none of a seed's 3 previews is good enough, try a new seed (e.g. `1104`,
`2104`, …) **without editing the prompt**, and log the seed you finally kept.

After saving, link the voice to the language (run it yourself in the Supabase
SQL editor):

```sql
update languages set voice_id = '<voice_id>' where code = 'ar';
```

---

## 5. Suggestions and gotchas

1. **The voices must live in every account whose key `generate-audios` rotates
   to.** Key `002` belongs to a different ElevenLabs account and cannot see
   the current English voice (`voice_not_found`). The batch script only
   rotates on 401/429, so if a run fails over to key `002`, every question
   fails with 404 and no audio is produced. Fix: either keep all generation on
   one account, or add each voice to the second account. A voice added there
   gets a **different** `voice_id`, and `languages.voice_id` holds only one, so
   one-account-per-voice is simpler.
2. **Test with real questions before saving.** The previews come from the
   design model. Real narration uses `eleven_v3_conversational`. After
   saving, run 5–10 real questions per language through TTS (a short
   `/generate-audios -n 5` run once questions exist in that language). Keep
   the voice only if it still sounds right. Pay attention to numbers, proper
   nouns, and the rising/falling pitch at the end of questions.
3. **English and Urdu already have voices** with 924 and 51 narrated
   questions. Replacing them with the new Quizoo Host voices means
   regenerating all of that audio: clear `audio_url` and re-run
   `generate-audios` (roughly 975 TTS calls). Do it only if the old voices
   clearly don't match the new ones. Otherwise the old voices can stay.
4. **Hindi and Urdu will sound related.** That's authentic, because spoken
   Hindi and Urdu share a base. The Urdu prompt leans on Perso-Arabic sounds
   (q, kh, gh, f, z), and the Hindi prompt on retroflex and aspirated
   consonants. If the two voices come out nearly identical, generate with a
   different seed for one of them, not a different prompt.
5. **Arabic narration quality depends on the text.** MSA text without
   diacritics is ambiguous, so TTS sometimes guesses the wrong vowel. When
   generating Arabic questions, add *tashkeel* on names and ambiguous words.
   The voice itself can't fix this.
6. **Keep the brand name consistent** across narration: *Quizoo* is spelled
   کوئزو / क्विज़ू / كويزو in the preview texts. If you later want the host to
   say the app name in-app, keep the same spelling.
7. **Don't use "Enhance prompt"** in the UI. It rewrites the prompt with an
   LLM and makes results unrepeatable.
8. **Store the prompt as the voice's description** (the save call does
   this). Then the library itself records how each voice was made.

---

## 6. Agent playbook: creating a prompt for a new language

> **Audience:** an AI model that was told something like *"read
> VOICE_DESIGN_PROMPTS.md and create the voice prompt for Portuguese."*
> Follow every step in order. The rules here are **mandatory**. If the user
> asks for something that conflicts with them, say which rule it breaks and
> ask them to confirm. Never deviate silently.

### 6.1 What you produce

For each requested language, add these to this file:

1. A **voice prompt**, in English, following the locked template (§6.5).
2. A **preview text**, in the target language, following §6.6.
3. A unique **seed** (§6.7).
4. Rows and a subsection added in the right places (§6.8).
5. A short report to the user, with recommendations (§6.10).

Out of scope unless the user explicitly asks: calling the ElevenLabs API
(it spends credits), writing to the database, creating a `languages` row,
or editing any other language's prompt.

### 6.2 Step 1: gather facts before asking anything

1. Read this **whole file**, especially §1 (reproducibility), the fixed
   settings table, and every existing prompt in §2. Your prompt must look
   like it belongs to that family.
2. If the Supabase MCP server is available, run these queries (read-only):
   ```sql
   select code, name, native_name, is_rtl, is_active, sort_order, voice_id
   from languages order by sort_order;

   select prompt from questions
   where language_code = '<code>' order by random() limit 8;
   ```
   Use the result to learn: whether the language already exists (and its
   code), whether it already has a voice, and **how the question text is
   actually written**: script, formal vs colloquial register, and whether
   there are diacritics or digits.
3. If the language already has a subsection in §2, this is a **redo**.
   Don't edit the existing prompt unless the user asks you to. Ask first
   (§6.3), because changing a prompt breaks reproducibility of the saved voice.
4. If Supabase isn't reachable, continue anyway. Ask the user about the
   question text (script and register) instead.

### 6.3 Step 2: ask clarifying questions, then wait

Ask **all** questions in a single round, before writing anything. Use the
`AskUserQuestion` tool if it's available; otherwise use a numbered list. For
every question:

- Put your **recommended option first**, labelled "(Recommended)", with a
  one-line reason.
- Give 2–4 concrete options. Never ask an open-ended "what do you want?"
- Skip any question the facts from §6.2 already answer. Say what you
  inferred instead of asking.
- Never ask about the locked items (§6.4) unless the user raised them.

**Question bank.** Ask each one that applies:

| Ask when… | Question | How to pick the recommendation |
|---|---|---|
| The language has more than one prestige variety (almost always) | Which regional variant or dialect? | Rank by: (1) matches how the question text is written, (2) the app's biggest target market, (3) most widely understood broadcast standard. |
| The language has distinct formal and spoken registers (Arabic, Tamil, Bengali, Greek, …) | Formal/literary register or everyday spoken register? | The register the question text is written in. Reading formal text in a colloquial accent sounds wrong. |
| The language uses more than one script (Serbian, Punjabi, Kazakh, Chinese, …) | Which script will the questions use? | The script the target market reads. The preview text must use it. |
| The target market is unclear | Which country/audience is this voice mainly for? | The market with the most expected players. |
| The request names a macro-language or ambiguous name ("Chinese", "Filipino/Tagalog", "Persian/Farsi/Dari", "Malay/Indonesian") | Which exact language? | The one with the most expected players. Treat Malay and Indonesian, Hindi and Urdu, and Farsi and Dari as separate voices. |
| Formality of address is a real choice (tu/vous, du/Sie, tú/usted) | Formal or informal "you" in the preview text? | Whatever the app's UI and questions use in that language. Default to polite/formal, except informal *tú* for Latin American Spanish apps. |
| The language already has a voice | Replace it (all its audio must be regenerated) or keep it? | Keep, unless the user reports a problem with it. |

**Common dialect decisions (starting recommendations):**

| Language | Options | Usual recommendation |
|---|---|---|
| Portuguese | Brazilian / European | Brazilian (São Paulo standard), for audience size |
| Chinese | Mainland Mandarin (Putonghua, Simplified) / Taiwan Mandarin (Traditional) / Cantonese | Mainland Putonghua, Beijing-standard broadcast (CCTV-style) |
| German | Germany Standard German / Austrian / Swiss Standard | Standard German, *Hochdeutsch* (Hanover/northern pronunciation) |
| Bengali | Bangladesh (Dhaka) / India (Kolkata) | Follow the text's spelling and the target market |
| Persian | Iranian Farsi (Tehran) / Dari (Kabul) / Tajik | Tehran standard Farsi |
| Turkish | Istanbul standard | Istanbul Turkish (TRT-style) |
| Russian | Moscow standard | Moscow standard literary Russian |
| Indonesian | Jakarta standard | Standard formal Bahasa Indonesia, Jakarta newsreader |
| Punjabi | Pakistani (Shahmukhi, Lahore) / Indian (Gurmukhi, Amritsar/Jalandhar) | Follow the script and the market; ask |
| Tamil | Chennai (India) / Jaffna (Sri Lanka) | Chennai, formal-spoken register |
| Swahili | Kenya / Tanzania | Tanzanian standard (Dar es Salaam), the reference variety |
| English (non-US variant requested) | UK RP-leaning / Australian / Indian English | Whatever the user asked. `en` itself stays General American |

If the user answers "you decide" or leaves a question blank, use your
recommended option and **say so explicitly** in the final report.

### 6.4 Locked rules (never change these per language)

- **Persona:** male, early 30s, elegant and friendly quiz-show host. It's
  the same character in every language.
- **Fixed settings:** the table in §1 (model `eleven_ttv_v3`, guidance `5`,
  loudness `0.5`, `should_enhance: false`, fixed preview text).
- **The persona block** (§6.5) is copied **word for word, character for
  character**. Changing any of it for one language breaks consistency across
  the whole set.

Changing the persona is a **global** decision. It requires rewriting every
language's prompt and regenerating every voice and all existing audio. If
the user asks for it, explain that cost and confirm before doing it.

### 6.5 Step 3: write the voice prompt (locked template)

```
<DIALECT BLOCK> <PERSONA BLOCK>
```

**PERSONA BLOCK.** Copy exactly, do not edit:

```
Male, early 30s. Perfect studio-quality audio: close-mic, clean and dry, with a silent background. Persona: elegant, friendly quiz show host. Emotion: warm, confident, gently curious. Smooth, rich mid-low baritone with a clear, bright presence; polished and articulate, every word crisp and easy to understand. Measured, moderate pace with natural pauses before key words. A slight smile in the voice: inviting, encouraging and refined, with calm, restrained energy.
```

**DIALECT BLOCK.** Exactly three sentences, about 250–450 characters, in
English:

1. **Identity:** `Native <nationality/region> <Language> speaker with/using
   <named prestige standard, tied to a specific city or region>, <a
   well-known broadcast reference: a national broadcaster, radio station, or
   dubbing/news standard>.`
   Examples: *"…standard Urdu of an educated Karachi native, with the clear
   pronunciation of a PTV newsreader."*, *"…polished, cultivated diction of a
   France Inter radio host."*
2. **Sound hallmarks:** 3–5 concrete phonetic features that make the
   dialect authentic, such as specific consonants, vowel qualities, stress,
   liaison, tones, or vowel length. Write sounds in Latin letters in single
   quotes (`'q'`, `'kh'`, `'rr'`). Use no IPA and no native script.
3. **Cultural delivery:** the culturally specific quality of polished
   speech in that language (courtesy, eloquence, musicality, rhythm, tone
   contours), ending with `the natural <melody/cadence/flow> of spoken
   <Language>`.

**Writing rules:**

- **English only.** Voice Design follows English descriptions best. The
  target language appears only in the preview text.
- **Positive phrasing only.** Never write negations such as "not robotic",
  "no Indian accent", or "avoid sounding like X". Naming a trait tends to
  pull it into the voice. Describe what you want instead.
- **Be specific about the dialect.** Name a city or region and a standard,
  not just a country. Don't use vague words like "foreign", "exotic", or a
  bare "accent". For accent strength, ElevenLabs recommends "thick" or
  "light", not "strong". Since every Quizoo voice is a native speaker of the
  standard variety, you normally don't need a strength word at all.
- **No real people's names**, including celebrities and specific
  newsreaders. Institutions (PTV, France Inter, NHK) are fine.
- **Don't add emotions, age, gender, or quality words.** The persona block
  already covers them, and duplicates or contradictions confuse the model.
- **Length:** the total prompt must be ≤ 1000 characters. Target 700–900.

### 6.6 Step 4: write the preview text

The preview text shapes the designed voice, so it matters as much as the
prompt.

- **Language and script:** the target language, in the chosen dialect's
  standard spelling, in **the same script and register as the app's
  questions** (§6.2).
- **Length:** 250–400 characters. The hard limits are 100–1000.
- **Structure.** Mirror the existing previews so all voices are designed
  from comparable material:
  1. Welcome back to Quizoo. Transliterate *Quizoo* into the native script
     where the language uses its own script, and record that spelling in
     §5.6.
  2. "Let's see how much you (really) know."
  3. Question: *the fourth planet from the Sun?*
  4. Question: **one culturally local question** for that market (national
     poet, national bird, capital city, a famous local painting or
     monument). Choose words that exercise the sound hallmarks from
     dialect-block sentence 2.
  5. "And now a hard one:" *roughly how long does sunlight take to reach
     the Earth?*
  6. Closing: take your time (trust your instincts), and choose the answer
     you think is correct.
- Include **at least 3 questions** ending with the language's own question
  mark (`?`, `؟`, `¿…?`, `？`). That exercises question intonation, which is
  exactly what Quizoo narrates.
- **Address the player the way the app does.** Where the language marks
  gender, use a gender-neutral phrasing (e.g. Spanish *"¡Qué gusto tenerte
  de vuelta!"* rather than *"Bienvenido"*).
- **No digits.** Write numbers as words or avoid them.
- **Only true facts.** Every question in the preview must have a real,
  correct answer.
- **Native-quality text.** Write the way an educated native would, not like
  a literal translation of the English preview. If you're unsure about any
  phrase, say so in your report and recommend a native speaker check it
  before generating.
- Follow the language's punctuation conventions (e.g. French spaces before
  `?`, `!`, and `:`; Spanish opening `¿` and `¡`).

### 6.7 Step 5: assign the seed

- Seeds go in the `1xx` series, in the order languages are added. Take the
  **highest seed in the §4 log table + 1** (the next one after `106` is
  `107`).
- Never reuse a seed, even one belonging to a deleted language.

### 6.8 Step 6: write it into this file

Edit only these places and follow the existing formatting exactly:

1. **Intro table:** add a row with the next `#`, the code, the language, the
   chosen dialect/register, and `—` for `voice_id`.
2. **§2:** add a subsection after the last language, headed
   `### <flag> <Language> (\`<code>\`), <short dialect> · seed \`<seed>\``,
   with the **Voice prompt** and **Preview text** code blocks, the same as
   the others. For the flag, use the country of the chosen variant.
3. **§4 log table:** add a row with the seed, guidance `5`, loudness `0.5`,
   and the voice name `Quizoo Host - <Language> (<code>)`.
4. **§5:** add a numbered gotcha only if the language has a real
   narration-specific risk. Examples: tonal languages (tones must come from
   the text), RTL scripts, missing diacritics, heavy loanword use,
   digit-reading conventions, or two scripts in circulation.

If the language isn't in the `languages` table, don't add it. Tell the user
it's missing and that adding it is a separate task.

### 6.9 Step 7: check your work before reporting

Run this from the project root. It checks lengths and confirms every prompt
ends with the exact persona block:

```sh
python3 - <<'PY'
import re
t = open('VOICE_DESIGN_PROMPTS.md', encoding='utf-8').read()
persona = re.search(r'\*\*PERSONA BLOCK\.\*\*.*?```\n(.*?)\n```', t, re.S).group(1)
sec2 = t.split('## 2. The prompts')[1].split('## 3.')[0]
for name, prompt, preview in re.findall(
        r'### (.*?)\n.*?\*\*Voice prompt\*\*\n\n```\n(.*?)\n```.*?\*\*Preview text\*\*\n\n```\n(.*?)\n```', sec2, re.S):
    ok = prompt.endswith(' ' + persona)
    print(f"{name[:40]:40} prompt={len(prompt):4} preview={len(preview):4} persona_ok={ok}")
PY
```

Every row must show `prompt ≤ 1000`, `100 ≤ preview ≤ 1000`, and
`persona_ok=True`. Also check by hand:

- [ ] The dialect block is 3 sentences, in English, with no negations, no
      native script, no IPA, and no real people's names.
- [ ] The dialect and register match the user's answers (or your stated
      defaults).
- [ ] The preview text uses the correct script, has at least 3 questions,
      no digits, true facts, and gender-neutral address.
- [ ] The seed is unique and equals the previous highest + 1.
- [ ] No other language's prompt, preview text, or seed changed.

### 6.10 Step 8: report back to the user

Keep it short:

1. What you added (language, dialect, register, seed), and every default you
   chose on the user's behalf.
2. The voice prompt and preview text, so they can paste them straight from
   chat.
3. **Recommendations and risks** for that language. Always consider:
   - whether a native speaker should check the preview text (recommend it
     for any language you're less than fully fluent in);
   - pronunciation risks in the *question* text (missing diacritics, tones,
     numbers, abbreviations, loanwords) and how question authoring can
     reduce them;
   - whether the language exists in `languages` and already has
     questions;
   - that the voice must be created in the ElevenLabs account the
     `generate-audios` keys use (§5.1);
   - testing 5–10 real questions through TTS before committing (§5.2).
4. The next steps for the user: generate in ElevenLabs with the §1 settings
   (via the API recipe in §3 if they want reproducibility), fill in the §4
   log, then run the `update languages set voice_id …` SQL.
