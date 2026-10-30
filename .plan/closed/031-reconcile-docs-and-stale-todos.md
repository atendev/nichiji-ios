---
id: "031"
title: Reconcile docs and stale TODOs with v0.6.0
type: task
mode: AFK
status: closed
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

Yes, after this change. v0.6.2, patch.

- `PROGRESS.md`: Slices 1-5 and 8-11 moved to `tested`. Each slice has a passing suite in `NichijiTests/Suites`, and CI run 41041313347 passed on `main` after Slice 11 merged. "Not yet built or run" is gone from Slices 10 and 11.
- `DESIGN.md`: the status line names v0.6.0 and `.plan/map.md`. Non-goals are unchanged for "Fix the v1.0 scope".
- TODOs now name their replacing tickets: `LevelCompleteView` ("Build the You tab"), `MainTabView` (the Dictionary, Review and You build tickets), `SettingsSheet` ("Build the Review settings screen"). Beyond the ticket's list, `SettingsSupportViews` and `NichijiWidgetBundle` now point at "Build the lock-screen widgets". The `.widgetURL` TODO in `DailyKanjiWidget` stays for "Open Today from a widget tap".
- Comments and docs only. No build or test ran locally (Linux host, no Xcode). CI: pending; see Final Report.

