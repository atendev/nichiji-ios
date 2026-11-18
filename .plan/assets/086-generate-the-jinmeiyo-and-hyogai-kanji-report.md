# Report: Generate the Jinmeiyō and Hyōgai kanji

`make dataset` now builds 6,464 kanji with a per-record classification. The Swift contract types carry the field. Swift was not compiled: this host has no Swift toolchain, so every Swift edit and test was checked by eye only. The master's CI run is the first real compile.

## Result

| Level | Kanji | Notes |
| --- | --- | --- |
| Jōyō | 2,136 | Unchanged. |
| Jinmeiyō | 863 | 247 are Waller N1. 616 are new and have no N-level. |
| Hyōgai | 3,465 | Every other JIS X 0208 kanji. |
| Total | 6,464 | |

- Shared: 5,361,613 B (5.11 MiB) of 8 MiB. AppOnly: 12,294,312 B. App total 16.84 MiB of 24 MiB.
- 6,375 stroke SVGs. The 89 Jinmeiyō kanji KanjiVG lacks ship without one.
- 19,025 common words, up from 18,195.
- No example word: 1,339 kanji (Hyōgai 1,129, Jinmeiyō 210, Jōyō 0).
- No English meaning: 25 kanji. All are Jinmeiyō and all have readings.
- Estimated JLPT levels: 172, unchanged.
- No JLPT level: 4,081.
- Checks run: `make dataset-test` (58 tests pass), and a Python recount of all 6,464 record files and the index (classification, example, meaning and level counts above). `make dataset` was not re-run in this thread because `.cache/` is empty. The previous thread ran it and found it deterministic.

## New stroke-count mismatches

93 kanji whose KanjiVG stroke count differs from KANJIDIC2 joined `strokecount-allowlist.json`, which now holds 102 (the old 9 plus these). 57 are Hyōgai and 36 are Jinmeiyō.

倏倦僊儲兎厩呀呰噌嚔圍堵娩嫂屠嶐幃廐惓搜旡晦榊榔槌樋櫛欝歎沛漣潛瀕瀞瀦灘煉煕甑祁祇祓禰禱稗穿窿笈筬絳縋繡繦纛腿菟蓬蕚蕣薯藷蝕襖訝諛譖谺赱辻辿迂迄迦逗這逢逼遁遏邁邉鄰鎚鑁鑓陟隧霈頤飴鴉麭龜

Most are variant stroke-count conventions between the two sources, not data errors. The check still runs for every kanji that has a file.

## Decisions

| Question | Options | Choice | Who |
| --- | --- | --- | --- |
| How is the Jōyō test written for classification? | Reuse `joyoGrade`, or a separate `classification` | Separate field on record and index. `joyoGrade` stays Jōyō-only. | 085 decision, implemented here |
| Who gets an OpenJLPT supplement level? | All kanji, or Jōyō only | Jōyō only. Jinmeiyō and Hyōgai outside Waller have no `jlptLevel`. | Implementer |
| Which Waller-listed kanji are kept? | Only those in the three sets, or all | All of them, so no listed kanji is dropped. Anything not in KANJIDIC2 fails the build. | Implementer |
| Which kanji need a KanjiVG file? | All, or Jōyō only | Jōyō only. The stroke-count check still runs on every kanji with a file. | 085 decision, implemented here |
| Swift initialiser default for `classification` | Required argument, or infer from `joyoGrade` | `classification: KanjiClassification? = nil`, inferred as Jōyō with a grade and Jinmeiyō without. This keeps about 25 existing test fixtures compiling. | Implementer |
| Handwriting test floors | Keep, or lower | Kept at 82/91 and 70/80, unrun. See the CI risk below. | Implementer |

## Audit

Council APPROVE in round 2 of 5: claude 8, gemini 10, gpt 9. Round 1: claude DISAPPROVE 6, gemini APPROVE 10, gpt APPROVE 9.

- Round 1 blocking (claude): the last Jōyō browse group now holds 4,328 kanji but is still titled "Name kanji". Rebutted. Browse grouping belongs to the app ticket (Add the Jinmeiyō and Hyōgai levels to the app), which is blocked behind this one. This ticket only changes the test counts. Claude's round 2 reply dropped the blocker and kept it as a minor note.
- Declined minor: `classify()` returns Hyōgai without checking the JIS flag. Selection only admits Jōyō, grade 9 or 10, JIS X 0208 or Waller-listed kanji, and the 247 Waller kanji outside Jōyō are all grade 9 or 10, so the real bundle has no non-JIS Hyōgai. My round 2 rebuttal said "3,465 equals the JIS X 0208 count". That was loose: 3,465 is the JIS X 0208 count outside Jōyō and Jinmeiyō. The conclusion holds.
- Declined minor: `KanjiClassification.inferred` labels a hand-built record with no grade as Jinmeiyō. It exists for fixtures. The generator always writes the field.
- Declined minor: no app-side handling for the 89 missing SVGs. The app ticket covers it.

## Risks for the master's CI run

- **Handwriting accuracy floors.** `HandwritingAccuracyTests` keeps its 82/91 and 70/80 floors, now over 6,375 template candidates instead of 2,383. A bigger candidate pool with many look-alike Hyōgai kanji can push accuracy under the floors. This test also needs `templates.count == 6_375` and a slower Debug template build.
- **Swift not compiled.** `KanjiClassification`, `KanjiEntry`, `KanjiIndexEntry`, `DatasetContractTests` and the three count-dependent tests were re-read for Swift 6 correctness. No error found, but CI is the first compile.
- **Decoding needs the field.** `KanjiEntry` and `KanjiIndexEntry` use the synthesised decoder, so every record and index entry must carry `classification`. A Python recount confirms all 6,464 do.

## Surfaced for later tickets

- The app ticket owns the browse label ("Name kanji" now covers 4,328 kanji until it lands), the "No stroke order" state for 89 kanji, the widget peak memory with the larger index, and the search-index build cost.
