---
id: "033"
title: Find a licensable JLPT N5-N1 kanji list
type: research
mode: AFK
status: closed
blocked_by: []
claimed: false
---

## Question

Which redistributable per-kanji JLPT N5-N1 classification list can the app ship, under what license, and how should the app label it?

## Notes

Skills: `research`, `unslop`.
KANJIDIC2's `jlpt` field is the pre-2010 four-level test and the JLPT publishes no official kanji list (see [Verified kanji and stroke dataset sources](../closed/002-verified-kanji-dataset-sources.md)). The app groups kanji by N5-N1 in onboarding, Settings, the custom picker, Dictionary and You, so the dataset needs a mapping before it can be generated.
Acceptable licenses: CC BY-SA or more permissive. Unlicensed lists are out.

## Resolution

Resolved by a research subagent during charting on 2026-10-30. Nothing was committed outside this ticket.

### Decision

Use Jonathan Waller's tanos.co.uk N5-N1 kanji lists, licensed CC BY. Every other candidate found is a copy of them. The sharing page (https://www.tanos.co.uk/jlpt/sharing/, read through the Wayback Machine because the site did not resolve) says everything on the site not for sale is under Creative Commons "BY", for commercial or non-commercial use, with credit.

Pin it through `evanclan/OpenJLPT` at commit `0d1d3410bec90bd4098a7c72de820543cb4f707c` (2026-10-02). `sources/waller/kanji-eng-n{1..5}.json` is a verbatim snapshot of Waller's lists: 2,211 kanji, N5 79, N4 166, N3 367, N2 367, N1 1,232. It matches the `jlpt_new` field in `davidluzgouveia/kanji-data` exactly. Ship only the character-to-level mapping and drop Waller's glosses.

Waller's list predates the 2010 Jōyō revision, so 172 Jōyō kanji have no level, among them 分, 的, 誰, 頃 and 鍵. Ticket "Settle the bundled dataset scope and schema" chooses between:

- OpenJLPT's processed `data/json/kanji/n*.json` (CC BY-SA 4.0), which places each of the 172 at the easiest level of an OpenJLPT word containing it, else N1, and flags it `supplementary: true`. Total 2,383: N5 84, N4 169, N3 387, N2 398, N1 1,345.
- Leaving them unleveled, reachable only through Jōyō grades.

A heuristic built from KANJIDIC2's legacy four-level field is not needed. Waller's list is that split already: old level 2 went to N3 339, N2 349, N1 44.

### License notes

- Waller: CC BY, no version stated. Compatible with the CC BY-SA bundle.
- OpenJLPT: CC BY-SA 4.0 because it includes JMdict and KANJIDIC2. Its `NOTICE.md` asks for credit to OpenJLPT and its upstreams.
- `davidluzgouveia/kanji-data` labels itself MIT, but it bundles KANJIDIC (CC BY-SA) and WaniKani content (not openly licensed). Do not use it as a source.
- kanjiapi.dev and other GitHub copies have no license or an MIT label they cannot grant.

### Labelling and attribution

- Label levels as unofficial, e.g. "JLPT level (unofficial estimate)", with an info line: "The JLPT has not published official kanji lists since 2010. Levels follow Jonathan Waller's community lists."
- Mark supplementary kanji as estimated, or leave them unleveled.
- Attribution: "JLPT N5-N1 kanji levels: Jonathan Waller's JLPT Resources (https://www.tanos.co.uk/jlpt/), CC BY." If OpenJLPT supplements are used, add: "Levels for 172 Jōyō kanji not in those lists: OpenJLPT (https://github.com/evanclan/OpenJLPT), CC BY-SA 4.0, built from JMdict and KANJIDIC2 (EDRDG), Jonathan Waller's JLPT lists, and Tatoeba."
- Record the pinned commit SHA in the generated `DATA-SOURCES.md`.

### Sources

- https://www.tanos.co.uk/jlpt/sharing/ and https://www.tanos.co.uk/jlpt/skills/kanji/ (Wayback Machine copies)
- https://github.com/evanclan/OpenJLPT (`NOTICE.md`, `LICENSE`, `data/json/meta.json`, `scripts/build-kanji.ts`, `sources/waller/`)
- https://github.com/davidluzgouveia/kanji-data (`README.md`, `LICENSE`, `kanji.json`)
- https://github.com/onlyskin/kanjiapi.dev (`jlpt.tsv`)

