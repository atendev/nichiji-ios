---
id: "086"
title: Generate the Jinmeiyō and Hyōgai kanji
type: task
mode: AFK
status: open
blocked_by: ["085"]
claimed: true
---

## Question

Does `make dataset` build the bundle with the Jinmeiyō and Hyōgai levels that [Add kanji beyond Jōyō](../closed/085-add-kanji-beyond-joyo.md) settled, and do the Swift contract types decode it?

## Notes

Skills: `tdd`, `domain-modeling`, `unslop`.
Read 085 and `tools/dataset/README.md` first.

- Select every KANJIDIC2 grade 9 or 10 kanji and every other JIS X 0208 kanji. Expect about 6,464 kanji: 863 Jinmeiyō (616 new) and 3,465 Hyōgai.
- Add the per-record classification (Jōyō, Jinmeiyō, Hyōgai) to the record and `kanji-index.json`, and to the Swift `KanjiEntry` and `KanjiIndexEntry`. Update `CONTEXT.md` with the term.
- Order the list by frequency, then JMdict common-word count, then stroke count, then code point.
- Skip stroke SVGs for kanji KanjiVG lacks (89 Jinmeiyō). Keep the stroke-count allow-list check for kanji that have a file. List any new mismatches in the report.
- Raise budgets to 8 MB Shared and 24 MB app.
- Regenerate `Dataset/`, `DATA-SOURCES.md` and the counts in `tools/dataset/README.md`. Existing kanji gaining example words is expected.
- Update `DatasetContractTests` for the new counts and field.
- Report per-level counts, the Shared and app sizes, the number of kanji with no example word, and the number with no English meaning.

## Resolution

## Handoff

Branch `t3/generate-jinmeiyo-hyogai-kanji`, tag `wfm-nichiji-v1-086-1794983873`, wip commit 596375d. Audit round 0 of 5 used. No council has run.

Done and verified (`make dataset-test` 58 pass, `make dataset` deterministic, 6,464 kanji written):
- `kanjidic.py` reads the JIS X 0208 flag. `build.py` has `classify`, the new selection, ordering (frequency, common-word count, strokes, code point), Joyo-only SVG requirement, `classification` on records and index, 8 MB and 24 MB budgets, level counts in `DATA-SOURCES.md`.
- Allow-list grew from 9 to 102 literals (93 new: 57 Hyōgai, 36 Jinmeiyō). List in `/tmp/new-mismatches.txt` may be gone: recompute with the stroke-count check.
- Swift: `KanjiClassification` enum plus `classification` on `KanjiEntry` and `KanjiIndexEntry` (init default infers it from `joyoGrade`). Tests updated: `DatasetContractTests`, `DictionaryBrowseTests`, `DictionarySearchDatasetTests`, `HandwritingAccuracyTests` (templates now 6,375). `CONTEXT.md`, dataset README, CHANGELOG v0.35.0, PROGRESS, IMPLEMENTATION updated.
- No Swift toolchain on Linux, so the Swift edits and the handwriting accuracy floors (82/91 and 70/80, now over 6,375 candidates) are unrun.

Numbers for the report: Joyo 2,136, Jinmeiyō 863 (247 N1, 616 no N-level), Hyōgai 3,465. Shared 5.11 MiB, app 16.84 MiB (Shared 5,361,613 B, AppOnly 12,294,312 B). 19,025 common words. 1,339 kanji with no example word (Hyōgai 1,129, Jinmeiyō 210, Jōyō 0). 25 with no English meaning (all Jinmeiyō, all have readings). 89 Jinmeiyō with no SVG. 172 estimated levels unchanged.

Left, in order:
1. Run `council-audit` (round 1) on the diff excluding `Dataset/` (`git diff main...HEAD -- . ':!Dataset'`), with the ticket question and map Notes and Decisions 085.
2. Fix problems, repeat to APPROVE, at most five rounds.
3. Write `.plan/assets/086-generate-the-jinmeiyo-and-hyogai-kanji-report.md` (decisions, options, who decided, audit verdict, declined minors, per-level counts, sizes, new mismatches), run unslop, commit with the work.
4. Run the Timing close (`--slug nichiji-v1 --ticket 086`), write the Resolution, delete this section, set `status: closed` handling per the master, commit, push without force, return DONE.

Surface in the report: widget peak memory and search-index build cost stay with the app ticket; handwriting floors and `templates.count == 6_375` need the master's CI run; Dictionary browse's last Jōyō group now holds 4,328 until the app ticket; 89 no-stroke kanji need the "No stroke order" state in the app ticket.

Read first: `tools/dataset/build.py`, `tools/dataset/tests/test_build.py`, `Nichiji/Models/KanjiContent.swift`, `NichijiTests/Suites/DatasetContractTests.swift`.
