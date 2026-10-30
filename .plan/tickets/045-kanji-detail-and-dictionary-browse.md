---
id: "045"
title: Build kanji detail and the Dictionary browse grid
type: task
mode: AFK
status: open
blocked_by: ["038", "042"]
claimed: false
---

## Question

Can the learner browse every kanji by level in the Dictionary tab and open any kanji's detail screen?

## Notes

Skills: `apple`, `unslop`.
Design: screens 32, 35-36, `Dictionary.dc.html`, `KanjiDetail.dc.html`.

- Kanji detail is one shared screen reused from Today's cards (`KanjiHeroView`, `DetailsCardView`, `ExampleWordsCardView`, `StrokeOrderCardView`) with the Practice entry. Later tickets open it from Review and You.
- Browse grid grouped by the active level system, JLPT or Jōyō. The design notes flag that it was JLPT-only. Share the grid with `CustomKanjiPickerView` where it fits.
- Replace the Dictionary placeholder. Search arrives in the next ticket, so leave the search bar out or disabled.

Minor bump.

## Resolution

