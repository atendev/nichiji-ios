---
id: "086"
title: Generate the Jinmeiyō and Hyōgai kanji
type: task
mode: AFK
status: closed
blocked_by: ["085"]
claimed: false
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

Yes. `make dataset` builds 6,464 kanji: 2,136 Jōyō, 863 Jinmeiyō and 3,465 Hyōgai. Every record and `kanji-index.json` entry carries `classification`, and `KanjiEntry` and `KanjiIndexEntry` decode it through the new `KanjiClassification` enum. The list is ordered by frequency, then JMdict common-word count, then stroke count, then code point. The 89 Jinmeiyō kanji KanjiVG lacks ship with no stroke SVG, and 93 new stroke-count mismatches joined the allow-list (102 in all). Shared is 5.11 MiB of 8 and the app set is 16.84 MiB of 24. 1,339 kanji have no example word and 25 have no English meaning. `make dataset-test` passes 58 tests. Swift was not compiled here, and the handwriting accuracy floors over 6,375 candidates need the master's CI run. Full report: [086 report](../assets/086-generate-the-jinmeiyo-and-hyogai-kanji-report.md).

Timing: wall 11m, active 11m, user 0s, wait 0s, blocked 0s | implement 7m, audit 2m (2 rounds) | tools 70 (4 subagent) | limits 0, compactions 0, handoffs 1 | ctx peak 147k | cost $2.54 sonnet-5-5 + $0.02 haiku-5-5
