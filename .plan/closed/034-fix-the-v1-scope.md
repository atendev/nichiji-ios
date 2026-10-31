---
id: "034"
title: Fix the v1.0 scope
type: grilling
mode: HITL
status: closed
blocked_by: []
claimed: false
---

## Question

Which of the features the MVP deferred count toward v1.0, and which stay out?

## Notes

Skills: `grilling`, `domain-modeling`, `unslop`.
`docs/workflow.md` defines 1.0.0 as feature-complete per `DESIGN.md`, so this ticket sets the map's destination and rewrites the Non-goals in `DESIGN.md`.
Candidates, each in or out:

- Handwriting recognition for Dictionary "Draw to search" (`docs/ui-reference` screen 34). Needs an on-device recognizer or a model.
- Stroke-order checking on the Practice sheet. The design notes say the pad only records strokes.
- iPhone Duo / iPad two-pane layout (iOS 27.1 SDK, availability-guarded).
- Configurable widgets (choose level or kanji).
- Release work: privacy manifest, App Store metadata, signing, TestFlight.
- The EDRDG requirement for a regular data update process (cadence and who runs it).

Each "in" item graduates from Not yet specified into tickets. Each "out" item moves to Out of scope.

## Resolution

In: release work (privacy manifest, App Store metadata, signing, TestFlight) as the last stage of the map; a minimal EDRDG cadence (the dataset is version-pinned per release and regenerated from upstream at each release, recorded in `DESIGN.md`); registering the `nichiji` URL scheme; a real CSV export from the You tab.

Out: handwriting recognition for "Draw to search" and stroke-order checking on the Practice pad. Both need a stroke-matching core with live re-ranking and tuning, and the repo has no corpus of drawn strokes — the only unknown-quality item on the map. Dictionary ships without the draw button; the Practice pad records strokes only. Checking, being the cheaper of the two, is the natural candidate to revisit first after v1.0. Also out: the Duo/two-pane layout (architecture still leaves room), configurable widgets, the "Customize your kanji" onboarding option (the Settings path covers it), the daily review cap and the furigana toggle.

Graduated: "Register the nichiji URL scheme", "Prepare the v1.0 release build" and "Write App Store metadata". The CSV export already sits inside "Build the You tab"; the draw-button removal is noted on "Build Dictionary search". The review reminder stays with "Decide the review scheduling and progress rules".

`DESIGN.md`'s Non-goals were rewritten to this boundary.

