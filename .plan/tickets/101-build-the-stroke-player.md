---
id: "101"
title: Build the stroke player
type: task
mode: AFK
status: open
blocked_by: ["100"]
claimed: true
---

## Question

Build the stroke player sheet that ticket 100 designed, with Play entry points on the stroke order card and the Practice sheet.

## Notes

Skills: `apple`, `tdd`, `unslop`. Read the 100 Resolution for the design. Keep the playback state (current stroke, progress, playing or paused) in a plain value type like `PracticePad` and unit-test it. The view only renders that state. Reuse `StrokePathParser` and `KanjiContentStore.strokePaths(for:)`. Kanji with no stroke file show `StrokeOrderCardView.noStrokeOrderMessage` and no Play button. Honour Reduce Motion as 100 decides. Branch `feature/stroke-player`.

## Resolution

<Filled in at close: the decision and the reason for it.>
