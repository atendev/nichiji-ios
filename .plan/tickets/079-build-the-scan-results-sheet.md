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

Yes, as far as reading the code and CI can show. The results sheet is an `@Observable ScanSheetModel` over pure `ScanSheetGeometry`. It rises to half 1.9 s after the shutter and moves between peek (112 pt), half (456 pt, photo at 0.8 and lifted 100 pt) and full (tab bar back) by drag. It snaps to the nearest state, a drag over 40 pt always moves one state, and Reduce Motion snaps with no animation. Half and full show a 3-column tile grid with each kanji's short meaning and a NEW tag or a green check, a New only switch, and "Nothing new here…" when the filter empties the grid. A tile opens detail with the back label "Scan results", and Back restores the sheet. `ScanSheetHost` carries the wiring, so `PhotoLookupScreen.swift` stays under the 400-line lint cap for the Crop and Save branches. The old results panel is deleted.

Council approved in round 3 (Claude 8, Gemini 10, GPT 10) with 3 minor problems declined. CI is green on 943d0dc. The drag, snap, tab bar and photo pose still need a device check. Docs use the placeholder version `v0.X.0` for the master to renumber. Decision report: `.plan/assets/079-build-the-scan-results-sheet-report.md`. PR: https://github.com/atendev/nichiji-ios/pull/57.

Timing: wall 46m, active 15m, user 1m, wait 30m, blocked 0s | implement 9m, audit 6m (3 rounds), ci 2m, handoff 27m | tools 110 (9 subagent) | limits 0, compactions 0, handoffs 2 | ctx peak 159k | cost $4.13 sonnet-5-5 + $0.04 haiku-5-5
