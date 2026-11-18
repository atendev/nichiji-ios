---
id: "079"
title: Build the scan results sheet
type: task
mode: AFK
status: open
blocked_by: ["078"]
claimed: true
---

## Question

Does the results sheet move between peek, half and full as designed, with the tile grid, New only and kanji detail?

## Notes

Skills: `apple`.
Design: `docs/ui-reference/camera/screens/4-results-half.png`, `5-results-new-only.png`, `6-full-screen-grid.png`, `7-kanji-detail.png`, and `camera-design-notes.md` "Sheet states".
The sheet rises to half about 1.9 s after the shutter. Peek is 112 pt, half is 456 pt with the photo scaled to 0.8 and moved up 100 pt, and full fills the screen and brings the tab bar back. A drag follows the finger, snaps to the nearest state, and a drag over 40 pt always moves one state. The snap is 0.32 s `cubic-bezier(.2,.8,.2,1)`. Top corners are 20 pt and flatten at full. The photo scales with the drag between peek and half. Scrolling the half grid pulls the sheet to full.
The header reads "N kanji found" over "X new to you · Y learned" (or "Showing X new"), with the New only switch. The 3-column tiles show the kanji, its short meaning, and either a NEW tag (vermilion wash `#f7e6de`, raised tile, darker border) or a green check. The full header is 写 | Scan with a chevron back to the photo, a thumbnail, "Your photo / Scanned just now" and View photo. "Nothing new here…" shows when New only empties the grid. A tile opens detail with the back label "Scan results", and Back restores the sheet. Reduced motion snaps without animation.

## Resolution

<Filled in at close.>

## Handoff

Branch `t3/scan-results-sheet-2`, pushed at `67fb077`, PR https://github.com/atendev/nichiji-ios/pull/57 against `wayfinder/nichiji-v1-master`. Printf tag `wfm-nichiji-v1-079-1794967719`. Council approved in round 3 (claude 8, gemini 10, gpt 10), so the audit is done. Three audit rounds used, one CI fix used (the first CI run failed to compile `ScanSheetTests.swift`, now fixed).

Done: the sheet, model, tiles, host modifier, screen wiring, tests, docs under placeholder `v0.X.0`, the decision report `.plan/assets/079-build-the-scan-results-sheet-report.md`, and the PR.

Left, in order:
1. Wait for the master's CI result. On "CI red", fix the failure, run the changed hunks through the council (round 4 and 5 are left), push, return PUSHED.
2. On "CI green" or "no CI", run `python3 -I ~/.claude/skills/wayfinder-runner/wf-time.py close --slug nichiji-v1 --ticket 079 --name 'Build the scan results sheet' --ticket-file .plan/tickets/079-build-the-scan-results-sheet.md`, fill in `## Resolution` here, delete this `## Handoff` section, commit, push, return DONE.

Report notes: 3 commits, 15 files, +1077 -143 against the master branch. Decision line for the map: the sheet is an `@Observable ScanSheetModel` over pure `ScanSheetGeometry`, wired through `ScanSheetHost` so `PhotoLookupScreen.swift` stays under 400 lines, and the old results panel is deleted. Minor problems declined: 3. No surfaced tickets so far.

Read first: this ticket, the decision report, `Nichiji/Views/Dictionary/ScanSheetHost.swift`.
