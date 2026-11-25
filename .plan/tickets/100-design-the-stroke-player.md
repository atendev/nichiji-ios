---
id: "100"
title: Design the stroke player
type: grilling
mode: HITL
status: open
blocked_by: []
claimed: false
---

## Question

What do the stroke player's layout and controls look like, and where does it open from?

## Notes

Skills: `apple`, `grilling`, `unslop`. Already decided by the user:
- A "Play" option on both the stroke order card and the Practice sheet opens a player sheet laid out like the Practice sheet.
- The whole kanji sits faintly in the background, and each stroke animates over it, so the learner watches the kanji fill in.
- The learner can step through stroke by stroke.

Each stroke can animate along its KanjiVG path with `trim(from:to:)`. Draw the background from the same paths in a faint colour, not from a font glyph, so the strokes line up with it exactly. Still to decide:
- controls (play/pause, previous and next stroke, replay, scrub)
- whether playback runs all strokes automatically or waits at each step
- stroke speed, and whether it scales with stroke length
- the pause between strokes
- whether the direction markers from 098 appear
- Reduce Motion behaviour, such as showing each stroke whole instead of animating it
- sheet detents
- the Play button's placement and label on the card and in the Practice sheet header

Read `Nichiji/Views/Practice/PracticeSheet.swift` for the sheet it mirrors. Is this in v1.0 or after? The map's scope ticket (034) did not cover it.

## Resolution

<Filled in at close: the decision and the reason for it.>
