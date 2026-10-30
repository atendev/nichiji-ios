---
id: "042"
title: Build the Practice sheet
type: task
mode: AFK
status: open
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

