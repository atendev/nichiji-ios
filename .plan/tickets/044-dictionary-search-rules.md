---
id: "044"
title: Decide how Dictionary search matches and ranks
type: grilling
mode: HITL
status: open
blocked_by: ["034", "036"]
claimed: false
---

## Question

What can the learner type into Dictionary search, what comes back, and in what order?

## Notes

Skills: `grilling`, `domain-modeling`, `unslop`.
Design: screens 32-34 and the Dictionary section of `docs/ui-reference/design-notes.md`. The design calls search fuzzy and shows kanji and word results.
Decide:

- Fields matched: kanji literal, English meaning, kana reading (hiragana and katakana folded), romaji, example words.
- Ranking and fuzziness: prefix, substring, edit distance, and how kanji and word results mix.
- The word source, which depends on the dataset decision (per-kanji examples only, or a word index).
- Whether the index is built at generation time or at launch, and its memory budget.
- Draw to search: in or out per "Fix the v1.0 scope". If out, the button is hidden, not mocked.

Settled by [Settle the bundled dataset scope and schema](../closed/036-bundled-dataset-scope-and-schema.md): the word source is an app-only `words.json` of 17,709 common JMdict forms (`id`, `word`, `kana`, `romaji`, `meaning`), built at generation time, about 1.6 MB raw. Kana-only words are excluded. This ticket still owns matching, ranking, romaji folding and the memory budget.

## Resolution

