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

Yes. `StrokeStepView` now paints every other stroke first and the current stroke last, through `StrokeStepView.drawOrder(count:step:)`, so later hairline strokes no longer cover the ink stroke where they cross. Colours are unchanged, and the strokes are still KanjiVG vector paths, so only the drawing order moved. `StrokePathParserTests.currentStrokeDrawsLast` covers the order. Swift was not compiled and no kanji was checked by eye in light and dark mode; the master's batch build and a look at 十 and 木 still owe that. Report: `.plan/assets/097-draw-the-current-stroke-above-the-others-report.md`.

Timing: wall 1m, active 1m, user 0s, wait 0s, blocked 0s | audit 38s (1 round) | tools 11 (2 subagent) | limits 0, compactions 0, handoffs 0 | ctx peak 64k | cost $0.38 sonnet-5-5 + $0.01 haiku-5-5
