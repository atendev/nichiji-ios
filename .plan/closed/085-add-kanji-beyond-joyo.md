---
id: "085"
title: Add kanji beyond Jōyō
type: grilling
mode: HITL
status: closed
blocked_by: []
claimed: false
---

## Question

Which kanji past the 2,383 in the bundle does the app add, what are their levels called, where do they sit on the level ladders, and what size budgets replace the old ones?

## Notes

Skills: `grilling`, `domain-modeling`, `unslop`.
Reopens part of [Settle the bundled dataset scope and schema](036-bundled-dataset-scope-and-schema.md): the character set and the 3 MB and 8 MB budgets.

Counts from the cached inputs (KANJIDIC2 db 2026-304, KanjiVG r20260714):

| Set | Not yet bundled | With KanjiVG strokes |
|---|---|---|
| Jinmeiyō (KANJIDIC2 grade 9 or 10) | 616 | 527 |
| Other JIS X 0208 kanji | 3,465 | 3,465 |
| Rest of KANJIDIC2 | about 6,600 | partial |

A bundled kanji averages 0.8 KB of record and 1.2 KB of stroke SVG.

## Resolution

The bundle adds two levels, both from KANJIDIC2 and KanjiVG, so no new source or licence is needed:

- **Jinmeiyō** ("Name kanji"): every KANJIDIC2 grade 9 or 10 kanji, 863 in all. 247 are already bundled as Waller N1, and 616 are new.
- **Hyōgai** ("Beyond the lists"): every other JIS X 0208 kanji, 3,465 new. The rest of KANJIDIC2 stays out, since most of it is variant forms with no stroke order, examples or English meaning.

The bundle grows to about 6,464 kanji.

Both levels go on both ladders, after the last existing level:

- **Jōyō ladder:** 1st grade through Secondary school, then Jinmeiyō, then Hyōgai. On this ladder, Jinmeiyō holds all 863 kanji, including the 247 that now have no grade.
- **JLPT ladder:** N5 through N1, then Jinmeiyō, then Hyōgai. On this ladder, Jinmeiyō holds only the 616 with no N-level, so no kanji sits in two JLPT levels.
- A level step means "kanji new at this step". Picking Jinmeiyō or Hyōgai marks the easier levels known, the same way existing levels do in `AutoKnownLevels`.

Each record gains a classification (Jōyō, Jinmeiyō or Hyōgai) that both ladders derive from. `joyoGrade` stays Jōyō-only. The Requirements Report of the generator ticket names the field.

Hyōgai kanji mostly lack a KANJIDIC2 frequency rank (298 of 3,465 have one). In list order, frequency comes first, then the count of JMdict common words that use the kanji, then stroke count, then code point.

The rule that every kanji in an example word must be bundled stays. The bundle is larger, so existing kanji can gain examples and `words.json` grows. That change is expected, not a regression.

The 89 Jinmeiyō kanji with no KanjiVG file ship without stroke order. Every surface that draws strokes (detail, Practice, the handwriting matcher) must handle a missing file without crashing or showing an empty pad as if strokes existed.

Budgets: the old 3 MB and 8 MB limits were never tied to a platform limit. The new limits are 8 MB for Shared (widget) and 24 MB for the app set. They still guard against accidental growth. The real widget limit is runtime memory (extensions are killed at about 30 MB), so the build measures the widget's peak memory with the larger index.

No new upstream inputs. `DATA-SOURCES.md` counts and the Sources screen copy update to the new totals.
