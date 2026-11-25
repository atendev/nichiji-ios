---
id: "101"
title: Build the stroke player
type: task
mode: AFK
status: closed
blocked_by: ["100"]
claimed: false
---

## Question

Build the stroke player sheet that ticket 100 designed, with Play entry points on the stroke order card and the Practice sheet.

## Notes

Skills: `apple`, `tdd`, `unslop`. Read the 100 Resolution for the design. Keep the playback state (current stroke, progress, playing or paused) in a plain value type like `PracticePad` and unit-test it. The view only renders that state. Reuse `StrokePathParser` and `KanjiContentStore.strokePaths(for:)`. Kanji with no stroke file show `StrokeOrderCardView.noStrokeOrderMessage` and no Play button. Honour Reduce Motion as 100 decides. Branch `feature/stroke-player`.

## Resolution

The stroke player is built on branch `feature/stroke-player`. `StrokePlayback` (`Nichiji/Views/Practice/StrokePlayback.swift`) is a plain Sendable value type with five phases. It takes stroke durations as input and moves on `advance(by:)`, so the unit tests need no clock. `StrokePlayerSheet` only renders it. A `.task` loop on `ContinuousClock` feeds it time, and the scene leaving `.active` pauses it. Stroke length comes from `StrokePathParser.length(of:)`, which flattens each curve. Duration is length ÷ 100 s clamped to 0.3 to 1.0 s, eased, with a 0.35 s rest. Reduce Motion shows whole strokes, one every 0.8 s, with no auto-start.

Play buttons: the stroke order card (`onPlay`, title row), Today and kanji detail, and an icon button in the Practice header. A kanji with no stroke file gets none. The player draws its current stroke in one place, `StrokePlayerCanvas.drawCurrentStroke`, where ticket 099's markers wire in after both branches merge. Stepping Next onto the last stroke goes straight to the finished (all ink) state. That is the one point the design left open.

Swift was not compiled and no tests ran, since this machine has no Xcode. The master's CI on the merged batch is the first compile. Audit: council-audit, single mode, approved in round 2 with a score of 8. Two minor problems were declined. The decision report is `.plan/assets/101-build-the-stroke-player-report.md`.

Timing: wall 10m, active 10m, user 0s, wait 0s, blocked 0s | implement 4m, audit 4m (2 rounds), gate 33s | tools 27 (7 subagent) | limits 0, compactions 0, handoffs 0 | ctx peak 134k | cost $1.42 sonnet-5-5 + $0.05 haiku-5-5
