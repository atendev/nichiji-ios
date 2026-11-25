---
id: "099"
title: Show stroke direction in stroke order
type: task
mode: AFK
status: closed
blocked_by: ["098"]
claimed: false
---

## Question

Build the direction markers that ticket 098 chose.

## Notes

Skills: `apple`, `tdd`, `unslop`. Read the 098 Resolution for the design. `StrokePathParser` in `Nichiji/Views/Today/StrokeOrderCardView.swift` builds each `Path`. Add the start point, and the start direction if 098 asks for arrows, as tested values beside it. Do not read them back out of the `Path`. Unit-test those values against hand-checked KanjiVG strokes with `M…c…`, `M…C…`, `M…l…` and `S` starts. Keep each marker's VoiceOver label in step with the existing "Stroke N of M" label.

## Resolution

Built as 098 decided. `StrokePathParser.parse(_:)` returns the path and a `StrokeMarker?`, so the start point and the unit direction (the chord to the point 10 units along the path, or to the end on shorter strokes) are recorded while parsing and never read back out of the `Path`. `path(from:)` is unchanged for its other callers. Each cell draws the vermilion dot and halo before the current stroke and the arrow and halo after it, on the current stroke only. The VoiceOver label becomes "Stroke 2 of 4, starts going down" from the same vector. A stroke with no length gets a dot, no arrow and the old label.

`StrokeMarker` is a plain `Sendable` struct in `Nichiji/Views/Today/StrokeMarker.swift`, with `drawDot(in:)` and `drawArrow(in:)` for the stroke player to reuse. Not wired into the player. `StrokeMarkerTests` checks real strokes with `M…c`, `M…C` and a relative first `m`, plus synthetic `M…l`, `M…L` and `S` starts, because KanjiVG has no stroke that starts `M…l` or `M…S`. Expected values come from an independent script and were checked by hand. Swift was not compiled, so the first compile is the master's CI run.

Audit: council-audit single mode (Claude seat), round 1 APPROVE 8 with three minor problems (two fixed, one declined), round 2 APPROVE 9. Report: `.plan/assets/099-show-stroke-direction-in-stroke-order-report.md`. Version bump is the master's call on the merged batch (a new feature, so minor).

Timing: wall 5m, active 5m, user 0s, wait 0s, blocked 0s | implement 2m, audit 2m (2 rounds) | tools 26 (4 subagent) | limits 0, compactions 0, handoffs 0 | ctx peak 102k | cost $1.04 sonnet-5-5 + $0.03 haiku-5-5
