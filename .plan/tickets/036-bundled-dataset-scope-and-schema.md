---
id: "036"
title: Settle the bundled dataset scope and schema
type: grilling
mode: HITL
status: open
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

