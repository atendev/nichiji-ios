---
id: "086"
title: Generate the Jinmeiyō and Hyōgai kanji
type: task
mode: AFK
status: open
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
