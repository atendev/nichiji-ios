---
id: "034"
title: Fix the v1.0 scope
type: grilling
mode: HITL
status: open
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

