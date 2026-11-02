---
id: "044"
title: Decide how Dictionary search matches and ranks
type: grilling
mode: HITL
status: closed
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

Settled by [Settle the bundled dataset scope and schema](../closed/036-bundled-dataset-scope-and-schema.md): the word source is an app-only `words.json` of common JMdict forms (`id`, `word`, `kana`, `romaji`, `meaning`), built at generation time. The generated file holds 18,195 words in 2.3 MB raw; 3 have no kanji. This ticket still owns matching, ranking, romaji folding and the memory budget.

## Resolution


Settled with the user in one grilling session (20 questions, every recommendation accepted except the word tap, which became a sheet).

**What matches.** A kanji matches on its literal, every meaning, every onyomi and kunyomi (hiragana and katakana folded together) and the romaji of those readings, with okurigana markers (`.`, `-`) stripped. Radical meanings and example words do not match a kanji. A word matches on its written form, kana, romaji and meaning, and on any kanji it contains.

**How the query is read.** The script decides the mode, kanji first: any kanji in the query searches literals and words containing the query; otherwise any kana searches readings and word kana, and Latin letters in it are dropped; otherwise Latin searches romaji and English together, with no toggle. No silent romaji-to-kana conversion. Kanji queries put each distinct kanji in typed order in the Kanji section and skip kanji outside the dataset.

**Folding and fuzziness.** One Swift folding function runs on both data and query: lowercase, macrons and doubled vowels collapse (`ō`, `ou`, `oo` to `o`; `ū`, `uu` to `u`), apostrophes, dots and hyphens drop, and `shi`/`si`, `tsu`/`tu`, `chi`/`ti` and `mb`/`nb` fold. Romaji and kana match as exact, prefix or substring. English matches only at a word start, and a multi-word query is a phrase that must start at a word boundary, with hyphens read as spaces (`one` finds "one-sided", not "someone"). No edit distance in v1.

**Ranking.** Kanji: match tier (exact, prefix, substring), then field (literal, reading, meaning), then `frequencyRank` with unranked last, then `listIndex`. Words: match tier, then a new `rank` from JMdict priority tags and `nf` bands, then shorter kana.

**Results.** Two sections as in the mock, Kanji then Words, under `Closest matches for "x"`: up to 20 kanji in a wrapping grid and up to 50 word rows; an empty section hides; no results shows `No matches for "x"`. Search runs as you type with about 150 ms debounce; kana and kanji search from one character, Latin from two. An empty field shows the browse grid. Search always covers all 2,383 kanji and every word, regardless of level system or study pool. Draw to search is out: the button is hidden.

**Word tap.** A word row opens a sheet like Practice (medium detent, swipe to dismiss) showing the word, kana, romaji and meaning over a "Which kanji?" row of one tile per distinct kanji with its primary meaning. A tile dismisses the sheet and opens that kanji's detail. A word with one distinct kanji skips the sheet and opens detail directly; the 3 words with no kanji are not tappable.

**Data and index.** The generator adds `rank` to each `words.json` record and writes an app-only `Dataset/AppOnly/kanji-search.json` with each kanji's full readings, romaji and meanings, raw and unfolded. The app builds the folded in-memory index on a background task the first time Dictionary appears and keeps it for the session; while it builds, a typed query shows "Preparing search…". Each keystroke is a linear scan over about 20.5k rows. Budget: about 20 MB resident for the index. The widget budget is untouched.

Graduates nothing new: "Build Dictionary search" carries all of it, including the generator change.
