---
id: "098"
title: Decide how stroke order shows direction
type: prototype
mode: HITL
status: open
blocked_by: []
claimed: true
---

## Question

How does the stroke order card show where each stroke starts and which way it goes: a start dot, an arrow, or both, and on which strokes?

## Notes

Skills: `apple`, `prototype`, `unslop`. Each KanjiVG path is stored in writing direction, so its first point is the pen-down point and its first curve segment gives the starting direction. No new data is needed. The user suggested a red dot at the pen-down point, or arrows. Suggested starting point: a dot on the current stroke in every cell, plus a small arrow on the current stroke only, because arrows on every stroke crowd kanji with many strokes. Also decide:
- the dot colour, which must pass 4.5:1 contrast on `.nichijiSurfaceSunken` in light and dark mode
- the dot size at the cell's scale
- whether the Practice pad guide shows the dot too
- whether the stroke player (ticket 100) reuses the markers

Before deciding, compare about 20 kanji with a known stroke-order reference, such as the KanjiVG viewer, to confirm the path start is always the pen-down end.

## Resolution

<Filled in at close: the decision and the reason for it.>
