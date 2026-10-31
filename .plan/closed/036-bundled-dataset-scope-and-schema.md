---
id: "036"
title: Settle the bundled dataset scope and schema
type: grilling
mode: HITL
status: closed
blocked_by: ["033", "034"]
claimed: false
---

## Question

Which kanji does the generated bundle ship, what does each record hold, and how is the generator built and run?

## Notes

Skills: `grilling`, `domain-modeling`, `unslop`.
Read [Verified kanji and stroke dataset sources](../closed/002-verified-kanji-dataset-sources.md) and the resolution of "Find a licensable JLPT N5-N1 kanji list" first.
Decide:

- Character set: all 2,136 Jōyō kanji, only those with an N-level, or both unioned.
- `KanjiEntry` changes: replace or supplement `jlptLevel` with the licensed N-level plus a `legacyJLPTLevel`, make `frequencyRank` and `strokePaths` optional, and how the UI labels an unofficial N-level.
- Example words per kanji: how many, the JMdict filter (priority tags, excluded forms), and whether every word must stay within the kanji's level.
- Whether Dictionary search needs more JMdict words than the per-kanji examples. If yes, the bundle carries a separate word index.
- Generator language and location (e.g. a Swift package under `tools/`), whether it downloads upstream files or takes them as inputs, and whether the generated output is committed.
- Bundle size budget for the app and the widget extension, which both carry the index and records.
- Update cadence for the EDRDG regular-update obligation, if "Fix the v1.0 scope" put it in v1.0.
- Verify the Jōyō grade counts the UI shows (80, 160, 200, 202, 193, 191, 1110) against KANJIDIC2 `grade`; the design notes say they came from memory.

## Resolution

The bundle ships 2,383 kanji: all 2,136 Jōyō plus Waller's 247 N1 jinmeiyō kanji (`joyoGrade` nil). The 172 Jōyō kanji missing from Waller's lists take OpenJLPT's supplementary level and are flagged `isJLPTLevelEstimated`.

`KanjiEntry` keeps `jlptLevel`, documented as an unofficial community level, gains `isJLPTLevelEstimated` (on the record only, not the index), and drops `strokePaths`, which load lazily from `stroke-order/<hex>.svg`. There is no `legacyJLPTLevel`. `frequencyRank` stays optional. `ExampleWord` drops `maxJLPTLevel` and `maxJoyoGrade`. `KanjiIndexEntry` gains `frequencyRank`. `strokeCount` is KANJIDIC2's value, with a generator allow-list for 9 known KanjiVG mismatches. `listIndex` orders by Jōyō grade, then frequency, then stroke count, then code point.

The UI shows "N5", shows "N1 (est.)" for estimates, and adds a footer to the Level screens ("JLPT levels are unofficial community lists") that links to Sources.

Each kanji has up to 3 example words from JMdict, chosen at generation time. Ranking goes by priority tier, then a soft preference for same-level words, then `nf` band. Headwords with digits, Latin or `sK/iK/oK/rK` forms are excluded, and every kanji in a word must be in the bundle. Five kanji end up with none. An app-only `words.json` of 17,709 common forms feeds Dictionary search; the widget does not carry it. Words with no kanji form (such as ありがとう written in kana only) are excluded, so a romaji query for one finds nothing by design.

The generator is standard-library Python in `tools/dataset/`, a build-time repo script that is not part of any app target. `make dataset-fetch` downloads inputs and writes `sources.lock.json`. `make dataset` runs offline and deterministically. The output is committed to `Dataset/`: `Dataset/Shared/` (`kanji-index.json`, `kanji/<hex>.json`, `DATA-SOURCES.md`) goes to both targets, and `Dataset/AppOnly/` (`stroke-order/<hex>.svg`, `words.json`) goes to the app only. `KanjiRadical.meaning` has no upstream source, so the generator takes a hand-authored 214-entry Kangxi radical table (character and English name) as an input. Budgets are 3 MB for the widget and 8 MB for the app, checked by the generator.

EDRDG data refreshes at every release, plus a data-only patch if the snapshot is older than 6 months. Waller's lists and the OpenJLPT supplement stay pinned.

The Jōyō grade counts are verified against KANJIDIC2 (db 2026-304): 80/160/200/202/193/191/1,110. Bundle counts: N5 84, N4 169, N3 387, N2 398, N1 1,345.

