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

Branch `t3/build-scan-results-sheet`. Audit round 0 (council not run yet). Printf tag `wfm-nichiji-v1-079-1794967719`. No Swift toolchain on the host, so CI is the build, lint (`swiftlint --strict`: file 400, type body 250, function 50 lines, no trailing commas) and test check.

Done (uncommitted work is in the wip commit):
- `Nichiji/PhotoLookup/ScanSheet.swift`: `ScanSheetState`, `ScanSheetGeometry` (heights, snap with the 40 pt rule, presentation, corner radius, photo pose, riseDelay), `ScanScreenMetrics`.
- `Nichiji/PhotoLookup/ScanSheetModel.swift`: `@Observable ScanSheetModel` (state nil until rise, drag, endDrag, move, step, pullToFull, reset, photoPose) and `View.scanSheetPhotoPose(_:)`.
- `PhotoLookupModel`: `meanings`, `newCount`, `learnedCount`, `PhotoReadOutcome`.
- `Nichiji/Views/Dictionary/ScanResultTile.swift` (copy extension on `PhotoLookupCopy`, tile) and `ScanResultsSheet.swift` (`ScanSheetLayer`, `ScanResultsSheet`).

Left, in order:
1. Wire `PhotoLookupScreen.swift` (keep edits small: siblings Crop and Save edit its `topBar` and copy). Add `@State private var sheet = ScanSheetModel()`. Drop `showsPanel`, the panel call and its `.animation(value: showsPanel)`. Add `ScanSheetLayer(model:sheet:image: frozenImage, onPick:)` as the last ZStack child. Show `ScanningPill` while `!isLive && !sheet.isVisible`. Add `.scanSheetPhotoPose(sheet)` to `FrozenPhotoLayer` plus `.accessibilityHidden(sheet.isFull)`. Use `.toolbar(sheet.isFull ? .visible : .hidden, for: .tabBar)`. Feed `.onGeometryChange(for: ScanScreenMetrics.self)` (size, safeAreaInsets top/bottom) into `sheet.update`. Add a `.task(id: sweep?.resultsAt)` that sleeps `ScanSheetGeometry.riseDelay(readStart: sweep.readStart, now: .now)` then calls `sheet.rise(reduceMotion:)`. Call `sheet.reset()` in `updateSweep` for `.empty` and `.reading`. Keep `PhotoLookupScreen.swift` under 400 lines (383 now).
2. Delete `PhotoLookupResultsPanel.swift` and `PhotoLookupCopy.allStarted`.
3. Tests: `NichijiTests/Suites/ScanSheetTests.swift` (heights, snap, 40 pt rule, pose, corner radius, riseDelay, model rise/reset/pullToFull) and model tests for meanings, newCount, learnedCount. Reread all new Swift for compile and lint risk.
4. Docs per `docs/workflow.md` (PROGRESS, CHANGELOG, IMPLOG; MINOR bump after v0.28.0), decision report at `.plan/assets/079-build-the-scan-results-sheet-report.md` (unslop), council audit, `## Resolution` in this ticket, then commit, push, return PUSHED.

Read first: the new files above, `PhotoLookupScreen.swift`, `.plan/assets/078-build-the-frozen-photo-and-highlights-report.md`.
