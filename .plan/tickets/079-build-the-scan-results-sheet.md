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
