---
id: "097"
title: Draw the current stroke above the others
type: task
mode: AFK
status: open
blocked_by: []
claimed: true
---

## Question

In each stroke order cell, can the highlighted stroke draw on top of every other stroke?

## Notes

Skills: `apple`, `unslop`. `StrokeStepView` in `Nichiji/Views/Today/StrokeOrderCardView.swift` strokes the paths in index order. Later strokes, drawn in `.nichijiHairline`, paint over the current `.nichijiInk` stroke where they cross. Draw the earlier and later strokes first, then the current stroke last. The stroke files are KanjiVG vector paths, not images, so this is a drawing-order fix only. Check a kanji with crossing strokes, such as 十 or 木, in light and dark mode.

## Resolution

<Filled in at close: the decision and the reason for it.>
