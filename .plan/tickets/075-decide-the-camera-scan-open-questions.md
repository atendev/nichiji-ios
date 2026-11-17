---
id: "075"
title: Decide the camera scan open questions
type: grilling
mode: HITL
status: open
blocked_by: []
claimed: false
---

## Question

What does the camera scan package leave open that the build needs settled first?

## Notes

Skills: `grilling`, `apple`.
The user found the camera from [Build the photo lookup camera](../closed/074-build-the-photo-lookup-camera.md) badly designed and supplied a design: `docs/ui-reference/camera/` (start with `README.md` and `camera-design-notes.md`). That design replaces 074's layout. Open questions, each with a starting recommendation:
- **Where the camera lives.** The design hides the tab bar while the camera is open, brings it back on the full-screen grid, and pushes kanji detail with a "Scan results" back label. A full-screen cover cannot show the real tab bar. Recommend pushing the camera onto the Dictionary's `NavigationStack` with the nav bar hidden, toggling the tab bar with `.toolbar(_:for: .tabBar)`, and pushing detail on the same stack so Back restores the sheet.
- **Save to Photos.** It needs the add-only Photos permission, and `DESIGN.md` and the privacy copy say the photo is never saved. Keep Save (copy changes to "saved only when you tap Save") or drop it?
- **Highlights when Live Text reads.** Live Text gives no per-character boxes. Recommend boxes only from Vision, with Highlights hidden when the read came from Live Text.
- **The scan sweep against real reading time.** Recommend that the sweep loops until the read finishes, that boxes appear as the line passes, and that the sheet rises once both are done.
- **"Learned".** Recommend that learned means any stage past new (known included), as the "New to you" filter does now. Does "New to you" become "New only"?
- **States the design leaves out:** no kanji found, read failed, camera access off, no camera, and kanji that appear only inside words. Recommend reusing 074's copy in the sheet and overlay.
- **Tile meaning.** Recommend the first one or two meanings from `KanjiEntry`, on one line.
- **Crop.** Does Done rescan only the cropped area, and does the cropped photo replace the frozen one?
- **Entry.** "Scan a kanji" replaces "Look up kanji in a photo" beside "Draw a kanji". Do both stay Pro, and how does a locked button look?
Unblocks every camera scan build ticket.

## Resolution

<Filled in at close.>
