---
id: "031"
title: Reconcile docs and stale TODOs with v0.6.0
type: task
mode: AFK
status: open
blocked_by: []
claimed: false
---

## Question

Do `docs/PROGRESS.md`, `docs/DESIGN.md` and the in-code TODOs match what shipped in v0.6.0 and what this map plans next?

## Notes

Skills: `unslop`.
Patch bump. Docs and comments only, no behavior change.

- `PROGRESS.md`: slices 1-5 and 8-11 say `done` although each has a passing Swift Testing suite in CI. Move them to `tested`. Drop "Not yet built or run" from Slices 10 and 11 (CI run 41041313347 passed).
- `DESIGN.md`: the status line still reads "Phase 0 approved". Point it at v0.6.0 and this map. Leave Non-goals alone; ticket "Fix the v1.0 scope" rewrites them.
- `Nichiji/Views/Today/LevelCompleteView.swift:41` says "in Slice 7", which is closed. Retarget it to the You stats work (ticket "Build the You tab").
- `Nichiji/Views/MainTabView.swift:88` and `Nichiji/Views/Settings/SettingsSheet.swift:187`: name the tickets that replace them.

## Resolution

