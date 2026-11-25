---
id: "099"
title: Show stroke direction in stroke order
type: task
mode: AFK
status: open
blocked_by: ["098"]
claimed: true
---

## Question

Build the direction markers that ticket 098 chose.

## Notes

Skills: `apple`, `tdd`, `unslop`. Read the 098 Resolution for the design. `StrokePathParser` in `Nichiji/Views/Today/StrokeOrderCardView.swift` builds each `Path`. Add the start point, and the start direction if 098 asks for arrows, as tested values beside it. Do not read them back out of the `Path`. Unit-test those values against hand-checked KanjiVG strokes with `M…c…`, `M…C…`, `M…l…` and `S` starts. Keep each marker's VoiceOver label in step with the existing "Stroke N of M" label.

## Resolution

<Filled in at close: the decision and the reason for it.>
