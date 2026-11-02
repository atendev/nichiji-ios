---
id: "042"
title: Build the Practice sheet
type: task
mode: AFK
status: closed
blocked_by: ["038"]
claimed: false
---

## Question

Does "Practice this kanji" on Today open a sheet where the learner can trace the kanji over a faint guide, with undo, clear and a stroke count?

## Notes

Skills: `apple`, `unslop`.
Design: `docs/ui-reference/design-notes.md` (Practice), screens 12, 37-38, `PracticeSheet.dc.html`.

- A bottom sheet with a partial and a near-full detent. The full detent reveals the stroke order grid (reuse `StrokeOrderCardView`).
- Pad: PencilKit or a SwiftUI `Canvas` path recorder. The requirements report picks one and says why.
- Guide toggle, Undo, Clear, stroke counter. It records strokes only; checking them depends on "Fix the v1.0 scope".
- Dismiss by drag, tap outside, or Done.
- Wire the Today entry point. The review answer side and the kanji detail screen add their own entry in their tickets, using a shared presenter this ticket provides.

Blocked on real stroke data so the guide and grid work for every kanji. Minor bump.

## Resolution

Yes. "Practice this kanji" on Today now opens `PracticeSheet` through the shared `View.practiceSheet(target:)` presenter, which takes a `PracticeTarget` built with `PracticeTarget(entry:strokePaths:)` from content the caller has already loaded.

- Pad: a SwiftUI `Canvas` path recorder on `DragGesture(minimumDistance: 0)`, not PencilKit. Each drag is one stroke and a tap counts as one, so the counter, Undo and Clear come from a plain `PracticePad` value type that stores unit-coordinate points. Ink is 7/342 of the pad side with round caps. PencilKit's pressure ink and tool picker are not needed for finger tracing, and its undo manager would have to be kept in step with the counter.
- Sheet: `.fraction(0.7)` and `.large` detents, drag indicator, Done; drag or a tap on the dim dismisses it. Guide toggle (on by default) shows a fixed-size Shippori Mincho guide; Undo is disabled with no finished stroke, Clear with an empty pad. The stroke order grid reuses `StrokeOrderCardView`, whose `onPractice` is now optional (nil hides the button).
- Stroke data: the counter total is `KanjiEntry.strokeCount`. Missing SVGs give empty paths, so the pad and guide still work and the grid shows its "unavailable" line.
- The review answer side ("Build the Review tab and session") and kanji detail ("Build kanji detail and the Dictionary browse grid") call `practiceSheet(target:)` themselves.

CI: pending; see Final Report. Requirements and Deviation Reports are in `docs/IMPLOG.md` under v0.12.0.
