# Functional Harmony — App Store Connect Metadata (en-US)

Ready-to-paste copy for **Apple ID `1564025162`**, version **1.2.4** (Prepare for Submission).

Validated against:

- Live App Store Connect UI (Name/Subtitle remaining-character counters; version localization fields)
- `asc` metadata limits (`asc migrate validate` / `asc-metadata-sync`)
- Ahrefs Keyword Generator (US) for SEO density

**Display name:** Functional Harmony  
**Bundle ID (historical, unchanged):** `com.dpstudios.Chord-Solver`  
**SKU (historical, unchanged):** `Chord-Solver-iOS-First`  
**Xcode project / scheme:** `Functional Harmony.xcodeproj`  
**Primary language:** English (U.S.)

---

## Character limits (ASC requirements)

| Field | Limit | This copy | Status |
|-------|------:|----------:|--------|
| Name | 30 | 18 | OK |
| Subtitle | 30 | 23 | OK |
| Keywords | 100 | 98 | OK |
| Promotional Text | 170 | 103 | OK |
| Description | 4000 | ~1240 | OK |
| What's New | 4000 | ~440 | OK |
| Copyright | 200 | see below | OK |
| Support URL | URL | existing | keep or update |
| Marketing URL | URL | optional | — |

### Keyword rules (Apple + ASO)

- Comma-separated; **no spaces after commas** (spaces count toward the 100 limit).
- **Do not repeat** words already in **Name** or **Subtitle** (wasted budget).
- Singular/plural are indexed separately when useful (`chord` is in subtitle; keep `chords`).
- No competitor brand stuffing (removed legacy `tenuto`).

---

## App Information (app-level · all platforms)

*ASC path: Distribution → App Information · Localizable Information*

### Name

```
Functional Harmony
```

- **Chars:** 18 / 30  
- **Already set** in ASC (Edited, unsaved until you Save).  
- **Ahrefs:** `functional harmony` → Easy KD, >100 volume.

### Subtitle

```
Scale Finder & Chord ID
```

- **Chars:** 23 / 30  
- **Replaces:** `Music theory in an instant`  
- **Ahrefs:** packs `scale finder` (Easy, >1,000) + chord-ID intent without making “Scale Finder” the brand.

### Categories

| Slot | Value | Notes |
|------|--------|--------|
| Primary | **Music** | Current; correct for instrument/practice tools |
| Secondary | **Education** | Current; theory/learning fit |

Optional swap (only if you want classroom discoverability first): Primary **Education**, Secondary **Music**. Recommend keeping **Music → Education**.

### App Tags (US)

*ASC: App Information → App Tags · currently only supported in the United States*

| Tag | Keep? |
|-----|--------|
| Music | Yes |
| Education | Yes |
| Learning | Yes |

These three already match the product. Prefer **Music / Education / Learning** over generic lifestyle tags. (ASC shows max practical set of three on this app today.)

### Age rating

Keep **4+** (no changes required for this metadata pass).

### Content rights

Keep: *No, this app does not contain, show, or access third-party content.*

---

## Version localization (iOS · en-US · 1.2.4)

*ASC path: Distribution → iOS App → 1.2.4 Prepare for Submission*

Localization ID (API): `37f1880a-61a6-471e-a944-b710768e5ebc`  
Version ID (API): `adda605e-4c36-4eaa-9f38-000d11294db7`

### Promotional Text (editable without new binary)

```
Build chords & scales, identify from notes, or Ask in plain English. Instant music theory for practice.
```

- **Chars:** 103 / 170  
- Rotatable for launches; no App Review required for promo-only edits when version is live.

### Description

```
Functional Harmony is a fast music theory desk for players and students.

Build chords and scales from a root and quality. Identify harmony from notes. Or just Ask—type a chord, scale, or note stack in plain English and jump straight to the answer.

SCALE FINDER
• Choose a root and scale quality—major, minor, modes, pentatonic, and more
• See every degree spelled clearly for practice and ear training
• Perfect when you need a quick scale finder without flipping textbooks

CHORD BUILDER & CHORD ID
• Spell major, minor, sevenths, suspended, augmented, diminished, and more
• Stack notes in the Notes tab to identify chords and intervals (reverse lookup)
• Piano-friendly note entry with accidentals—great as a chord identifier

ASK
• Natural-language queries: “C major 7”, “F# dorian”, “C E G”
• Live preview before you open Chords, Scales, or Notes
• Built for homework, rehearsals, and songwriting sessions

WHY FUNCTIONAL HARMONY
• Chords, scales, and note identification in one app
• Clean, bottom-anchored controls designed for one-handed practice
• No accounts, no clutter—just theory when you need it

Whether you call it a scale finder, chord identifier, or harmony lab, Functional Harmony keeps tonal music theory at your fingertips.
```

- **Chars:** ~1240 / 4000  
- **First ~170 characters** (search/snippet priority): brand + chords/scales + identify + Ask.  
- Natural language includes Ahrefs phrases: *scale finder*, *chord identifier*, *music theory*, *chords*, *scales*.

### Keywords

```
music,theory,chords,scales,identifier,piano,guitar,triad,intervals,modes,builder,notes,major,minor
```

- **Chars:** 98 / 100  
- **Omitted on purpose** (already in name/subtitle): `functional`, `harmony`, `scale`, `finder`, `chord`, `id`  
- **Removed vs live listing:** `tenuto` (competitor), redundant spacing, low-value duplicates  
- **Added:** `identifier`, `piano`, `guitar`, `modes`, `builder`, `notes` (product + search intent)

### What's New in This Version

```
What's new in Functional Harmony:

• Notes — identify chords and intervals from note stacks
• Ask — type natural-language queries (chords, scales, or notes) with live preview
• Clearer Chords & Scales layout with bottom-anchored controls
• Smarter parsing (scale queries, major-minor 7ths)
• Design polish: consistent radii, spacing, and snappier animations

Now named Functional Harmony — your desk for building and identifying harmony.
```

- **Chars:** ~440 / 4000  
- Mentions rename so existing Chord Solver users understand the update.

### Support URL

```
https://dpshadey22.wixsite.com/chordsolver-ios
```

**Action:** keep for this release, then update the Wix title/copy to **Functional Harmony** (or replace with a dedicated URL when ready). Required field — do not clear.

### Marketing URL

```
(leave empty until a public landing page exists)
```

Optional. Only set if the page is live and on-brand.

### Copyright

```
2021–2026 Dylan Shade
```

- Replaces `2021 Dylan Shade` for the rename release.

### Version string

```
1.2.4
```

(matches binary already selected)

---

## App Review Information

| Field | Value |
|-------|--------|
| Sign-in required | **No** (unchecked) |
| First name | Dylan |
| Last name | Shade |
| Phone | (existing ASC value) |
| Email | (existing ASC value) |
| Notes | see below |

### Review notes

```
Functional Harmony (formerly Chord Solver) is a fully offline music theory utility. No account or login.

How to review:
1. Chords tab — pick a root and quality to spell a chord.
2. Scales tab — pick a root and scale quality (scale finder).
3. Notes tab — enter 2–4 notes to identify an interval or chord.
4. Ask tab — type e.g. “C major 7”, “F# dorian”, or “C E G” and submit.

No third-party content, no social features, no IAP required for core features.
```

---

## Screenshot caption suggestions (first 3 matter most)

Use on device frames or as accessibility/alt guidance when re-exporting:

1. **Build any chord** — Root + quality → spelled notes  
2. **Scale finder** — Modes, minor forms, and more  
3. **Identify from notes** — Notes tab reverse lookup  
4. **Just Ask** — Type chords, scales, or note stacks  
5. **Theory at your fingertips** — Bottom-anchored, practice-ready UI  

*(Screenshots already uploaded for 6.5"; captions are creative guidance, not ASC text fields.)*

---

## SEO map (Ahrefs → field)

| Intent / keyword | KD (free) | Volume (band) | Where it lives |
|------------------|-----------|---------------|----------------|
| functional harmony | Easy | >100 | **Name** |
| scale finder | Easy | >1,000 | **Subtitle** + description H2 |
| chord identifier | Medium | >1,000 | Subtitle (“Chord ID”) + description + keywords `identifier` |
| piano chord finder / piano chord identifier | Easy | >100 | keywords `piano` + description |
| music theory | Hard | >100K | keywords `music,theory` + description (no name fight) |
| chord solver | N/A | <100 | **retired** from marketing copy |
| circle of fifths | Medium | >10K | future feature/content only |

**Strategy:** Brand = theory phrase people search lightly. Subtitle = high Easy tool demand. Description = long-tail density. Keywords = remainder not already indexed via name/subtitle.

---

## Before / after (live ASC → proposed)

| Field | Live now | Proposed |
|-------|----------|----------|
| Name | Functional Harmony *(edited, not necessarily saved)* | Functional Harmony |
| Subtitle | Music theory in an instant | Scale Finder & Chord ID |
| Promotional Text | *(empty)* | See above |
| Description | Chord Solver… intervals… | Functional Harmony full copy |
| Keywords | chord, chords, scale, music theory… tenuto… | Optimized 98-char string |
| What's New | Notes / Ask bullets | Same + rename line |
| Copyright | 2021 Dylan Shade | 2021–2026 Dylan Shade |
| Tags | Education, Learning, Music | Keep |
| Categories | Music + Education | Keep |

---

## Apply via App Store Connect UI

1. **App Information** → set **Name** + **Subtitle** → **Save**  
2. **1.2.4 Prepare for Submission** → paste Promotional Text, Description, Keywords, What's New, Copyright → **Save**  
3. Confirm **Support URL** still loads  
4. **Add for Review** when binary + screenshots are ready  

## Apply via `asc` (API)

```bash
# App-level name/subtitle may require app-info localizations; version fields:
asc app-info set --app "1564025162" --locale "en-US" \
  --description "$(cat <<'EOF'
Functional Harmony is a fast music theory desk for players and students.

Build chords and scales from a root and quality. Identify harmony from notes. Or just Ask—type a chord, scale, or note stack in plain English and jump straight to the answer.

SCALE FINDER
• Choose a root and scale quality—major, minor, modes, pentatonic, and more
• See every degree spelled clearly for practice and ear training
• Perfect when you need a quick scale finder without flipping textbooks

CHORD BUILDER & CHORD ID
• Spell major, minor, sevenths, suspended, augmented, diminished, and more
• Stack notes in the Notes tab to identify chords and intervals (reverse lookup)
• Piano-friendly note entry with accidentals—great as a chord identifier

ASK
• Natural-language queries: “C major 7”, “F# dorian”, “C E G”
• Live preview before you open Chords, Scales, or Notes
• Built for homework, rehearsals, and songwriting sessions

WHY FUNCTIONAL HARMONY
• Chords, scales, and note identification in one app
• Clean, bottom-anchored controls designed for one-handed practice
• No accounts, no clutter—just theory when you need it

Whether you call it a scale finder, chord identifier, or harmony lab, Functional Harmony keeps tonal music theory at your fingertips.
EOF
)" \
  --keywords "music,theory,chords,scales,identifier,piano,guitar,triad,intervals,modes,builder,notes,major,minor" \
  --whats-new "$(cat <<'EOF'
What's new in Functional Harmony:

• Notes — identify chords and intervals from note stacks
• Ask — type natural-language queries (chords, scales, or notes) with live preview
• Clearer Chords & Scales layout with bottom-anchored controls
• Smarter parsing (scale queries, major-minor 7ths)
• Design polish: consistent radii, spacing, and snappier animations

Now named Functional Harmony — your desk for building and identifying harmony.
EOF
)" \
  --support-url "https://dpshadey22.wixsite.com/chordsolver-ios"
```

> Name / subtitle are **app info localizations** (not always covered by `app-info set`). Prefer ASC UI for Name + Subtitle, or `asc localizations` with `--type app-info` after resolving app-info ID via `asc app-infos list --app 1564025162`.

Promotional text (if supported by your `asc` version):

```bash
asc app-info set --help   # confirm --promotional-text flag
```

---

## Fastlane-style files (validated)

Plain-text mirrors live at:

```
metadata/fastlane/metadata/en-US/
  name.txt
  subtitle.txt
  description.txt
  keywords.txt
  promotional_text.txt
  release_notes.txt
  support_url.txt
  copyright.txt
```

```bash
asc migrate validate --fastlane-dir ./metadata/fastlane --output table
# → VALIDATION PASSED · Locales: 1 · Errors: 0 · Warnings: 0
```

---

## Checklist before submit

- [ ] Name **Functional Harmony** saved on App Information  
- [ ] Subtitle **Scale Finder & Chord ID** saved  
- [ ] Description no longer says **Chord Solver**  
- [ ] Keywords ≤ 100 chars, no spaces after commas  
- [ ] Promotional text filled  
- [ ] What's New mentions rename + Notes/Ask  
- [ ] Copyright year range updated  
- [ ] Support URL works; ideally rebranded page  
- [ ] Screenshots still accurate for Chords / Scales / Notes / Ask  
- [ ] Categories Music + Education  
- [ ] Tags Music, Education, Learning  
- [ ] Review notes updated for four-tab flow  
- [ ] Home-screen display name / `CFBundleDisplayName` aligned in Xcode if desired  

---

## Notes / non-goals this file does not change

- Bundle ID / SKU (historical Chord Solver identifiers — fine to keep)  
- Privacy Nutrition Labels / App Privacy  
- Pricing, IAP, DSA trader status  
- Icon asset (update separately for rename polish)  
- tvOS 1.0 localization (update separately if shipping tvOS)  

---

*Generated for Functional Harmony rename + 1.2.4 ASO pass. Sources: App Store Connect UI (app 1564025162), `asc app-info get`, Ahrefs free Keyword Generator (US).*
