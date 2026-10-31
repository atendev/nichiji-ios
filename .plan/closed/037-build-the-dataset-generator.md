---
id: "037"
title: Build the dataset generator and pin its first output
type: task
mode: AFK
status: closed
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

The generator is standard-library Python in `tools/dataset/`. `make dataset-fetch` pins 18 inputs in `sources.lock.json` (KanjiVG r20260714 and the Waller and OpenJLPT files at commit `0d1d341` are hash-enforced; the EDRDG files record hash and version only: KANJIDIC2 2026-304, JMdict 2026-10-31). `make dataset` runs offline, is byte-identical across runs, and writes the committed `Dataset/`. `make dataset-test` runs 39 `unittest` cases on inline fixtures and runs in CI.

The first bundle matches the pinned counts: 2,383 kanji, grades 80/160/200/202/193/191/1,110 plus 247 without a grade, N5 84, N4 169, N3 387, N2 398, N1 1,345, and 172 flagged `isJLPTLevelEstimated`. The 9 KanjiVG stroke-count mismatches match the count of 9 the dataset ticket expected and sit in `strokecount-allowlist.json`. Shared is 2.2 MB of the 3 MB widget budget and the app set is 7.0 MB of 8 MB.

Decisions made here:

- `kanji-index.json` is `{"formatVersion": 1, "entries": [...]}` ordered by `listIndex`, 0-based. `listIndex` sorts by Jōyō grade (secondary after grade 6, no grade last), frequency, stroke count, then code point. `primaryReading` is the first on'yomi, else the first kun'yomi. File names use five lowercase hex digits. Nil fields are omitted.
- Romaji keeps the `.` and `-` markers as written and uses macrons for long vowels.
- SVGs are cut down to their ordered stroke paths. The full KanjiVG files were 9.7 MB and put the app set at 14.3 MB. The licence and attribution moved into `DATA-SOURCES.md`.
- An example word counts as same-level when its headword is in Waller's vocabulary list at the kanji's level or an easier one. `ExampleWord.id` is `<JMdict sequence>:<headword>`; the gloss is the first three glosses of the first sense.
- `words.json` holds every word whose kanji are all in the bundle and whose headword or reading carries `news1`, `ichi1`, `spec1` or `gai1`.

Two figures from the dataset ticket did not reproduce under any selection rule tried: the bundle has 18,195 common words (not 17,709) and 11 kanji with no example word (not 5). All 11 are jinmeiyō name kanji (侑 崚 嵯 彪 怜 晟 滉 瑚 舜 赳 燿) with no word that passes the filters. The counts the app depends on all match.

Deviations from the ticket Notes and the research ticket: the tests use inline fixtures, not fixture files; the generated metadata records the upstream versions and the generator source rather than a separate parser version; and `DATA-SOURCES.md` credits each source with its licence name and site, not a bundled licence text or per-licence link. Headwords with a Greek letter or a fullwidth symbol are also dropped. Hepburn romaji reads を as "o", so 顔をつぶす comes out as "kaootsubusu"; this is cosmetic and left alone.

Swift: `KanjiEntry` gains `isJLPTLevelEstimated`, `KanjiIndexEntry` gains `frequencyRank`, and a `KanjiIndex` wrapper decodes the index. `KanjiEntry` decodes a missing `strokePaths` as empty. Dropping `strokePaths` and the `ExampleWord` `max*` fields stays with "Load the generated dataset in the app and widget", which also rewires the call sites. `DatasetContractTests` decodes the committed bundle with the real types. Nothing was built locally because the host is Linux with no Swift toolchain, so CI is the gate for the Swift side. The 々 iteration mark appears in some words and has no record by design; the loading ticket's kanji links must tolerate it. CI had not run when this ticket was closed.
