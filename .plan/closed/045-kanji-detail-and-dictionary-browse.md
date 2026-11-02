---
id: "045"
title: Build kanji detail and the Dictionary browse grid
type: task
mode: AFK
status: closed
blocked_by: ["038", "042"]
claimed: false
---

## Question

Can the learner browse every kanji by level in the Dictionary tab and open any kanji's detail screen?

## Notes

Owns the Forget it entry point on kanji detail (closed decision on review rules): a quiet control with a confirmation, calling `ReviewService.forgetIt`. Rebuild reminders after it.

Skills: `apple`, `unslop`.
Design: screens 32, 35-36, `Dictionary.dc.html`, `KanjiDetail.dc.html`.

- Kanji detail is one shared screen reused from Today's cards (`KanjiHeroView`, `DetailsCardView`, `ExampleWordsCardView`, `StrokeOrderCardView`) with the Practice entry. Later tickets open it from Review and You.
- Browse grid grouped by the active level system, JLPT or Jōyō. The design notes flag that it was JLPT-only. Share the grid with `CustomKanjiPickerView` where it fits.
- Replace the Dictionary placeholder. Search arrives in the next ticket, so leave the search bar out or disabled.

Minor bump.

From [Settle the bundled dataset scope and schema](../closed/036-bundled-dataset-scope-and-schema.md): the 247 jinmeiyō N1 kanji have no Jōyō grade, so Jōyō browse mode places them in no group. Decide whether to add a "Name kanji" group or leave them search-only. Estimated levels show "(est.)" in the Details row.

## Resolution

The learner can browse every kanji and open any kanji's detail screen. Shipped in v0.14.0.

- **Browse grid.** Dictionary lists all 2,383 kanji by the active level system: N5 to N1, or grade 1 to Secondary, then a "Name kanji" group for the 247 jinmeiyō kanji. The open question from the dataset decision is settled: they can be browsed, not only searched. An "Other kanji" group catches any kanji with no JLPT level. It is empty today and stays hidden. The grid is built from `KanjiContentStore.indexEntries()` through `KanjiBrowseGrouping`, so opening Dictionary decodes no records. Section headers read "N kanji".
- **Shared tile.** `KanjiGridTile` is the square cell for both the Dictionary grid and `CustomKanjiPickerView`. The picker keeps its own sections and its pool rules.
- **Detail.** `KanjiDetailView(kanjiID:)` is pushed from a tile inside the Dictionary `NavigationStack`. Its back button reads "Dictionary". It reuses `KanjiHeroView`, `DetailsCardView`, `ExampleWordsCardView` and `StrokeOrderCardView`, and Practice is wired in. There is no settings button. `KanjiDetailContent.load` loads it.
- **Forget it.** `ForgetItControl` sits at the foot of detail and also on Today. The ticket only named detail, but the review-rules decision lists Today. Two report audits disagreed, and the user chose Today as well. The control shows only for learning, familiar or known kanji, and confirms first. It calls `ServiceContainer.forgetIt`, which runs `ReviewService.forgetIt`, then rebuilds reminders. A failed reminder rebuild does not surface as an error.
- **Search.** The search bar and the draw button are left out. A TODO in `DictionaryView` marks where search goes.

Requirements Report: written by a subagent. The two haiku audits did not return `APPROVE`. The user picked "Add to Today too" and the run went on with every fix applied. The implementation audit and CI results are in the Final Report. CI was pending at commit time.
