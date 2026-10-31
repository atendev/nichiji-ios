---
id: "037"
title: Build the dataset generator and pin its first output
type: task
mode: AFK
status: open
blocked_by: ["036"]
claimed: false
---

## Question

Does a repeatable generator turn pinned KANJIDIC2, JMdict, KanjiVG and N-level inputs into the bundle the app expects?

## Notes

Skills: `tdd`, `unslop`.
Follow the decisions in "Settle the bundled dataset scope and schema" and the format in [Verified kanji and stroke dataset sources](../closed/002-verified-kanji-dataset-sources.md): `kanji-index.json`, `kanji/<hex>.json`, `stroke-order/<hex>.svg`, and a generated `DATA-SOURCES.md` with versions, URLs, SHA-256 and licenses.
The generator lives outside the app targets. Add a `make dataset` target. Downloading upstream files is network access outside the app; if the generator needs it, record the exact URLs and checksums so the run is reproducible.
Tests cover the parsers and the join on small fixture files, not the full upstream dumps.
Minor bump. Runtime loading is the next ticket.

Decisions from [Settle the bundled dataset scope and schema](../closed/036-bundled-dataset-scope-and-schema.md):

- Python 3, standard library only, in `tools/dataset/`, with `unittest` tests on fixture files. Output is committed to a repo-root `Dataset/`: `Dataset/Shared/` (`kanji-index.json`, `kanji/<hex>.json`, `DATA-SOURCES.md`) for both targets, `Dataset/AppOnly/` (`stroke-order/<hex>.svg`, `words.json`) for the app only.
- Two make targets: `make dataset-fetch` (downloads into untracked `tools/dataset/.cache/`, writes `sources.lock.json` with URL, SHA-256 and upstream version) and `make dataset` (offline, deterministic). KanjiVG r20260714 and OpenJLPT `0d1d341` are hash-enforced. The EDRDG files are rolling, so record their hash and version without enforcing them.
- Ship 2,383 kanji (Jōyō plus Waller N1 jinmeiyō), flag the 172 supplemented levels, up to 3 JMdict example words per kanji, and the app-only `words.json` of 17,709 common forms. Ranking and filter rules are in the resolution.
- Hand-author a 214-entry Kangxi radical table (character and English name) as a generator input, since `KanjiRadical.meaning` has no upstream source.
- Write a Hepburn romaji transliterator (readings with `.` and `-` markers, small kana, long vowels) with tests.
- Keep a committed allow-list of the 9 known KanjiVG stroke-count mismatches and fail on any new one. Fail the run if the widget set exceeds 3 MB or the app set exceeds 8 MB.
- Add a Swift contract test in `NichijiTests` that decodes the committed bundle with the real `KanjiEntry` and `KanjiIndexEntry` and asserts the grade counts (80/160/200/202/193/191/1,110) and N-level counts (N5 84, N4 169, N3 387, N2 398, N1 1,345).
- Add the data refresh to the release checklist with the 6-month staleness floor.

## Resolution

