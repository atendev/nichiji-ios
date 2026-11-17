---
id: "075"
title: Decide the camera scan open questions
type: grilling
mode: HITL
status: closed
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

The design in `docs/ui-reference/camera/` stands, with these gaps settled (auto-mode grilling; full record in `assets/075-decide-the-camera-scan-open-questions-report.md`):

- **Where the camera lives.** It is pushed onto the Dictionary's `NavigationStack` with the nav bar hidden, and the tab bar is hidden with `.toolbar(.hidden, for: .tabBar)` until the results reach full screen. Peek, half and full are a custom overlay inside the camera screen, not a system `.sheet`, because a sheet would cover the stack and block the detail push. The camera screen's navigation title is "Scan results" (bar hidden), so detail pushes with the design's "< Scan results" back label. The full state's "写 | Scan" header is drawn in the overlay, not a nav title, and Back returns to the overlay in the same state. Switching tabs keeps the stack. Tapping the Dictionary tab again pops to the root. The `AVCaptureSession` runs only while the viewfinder is on screen. (079, 076)
- **Save stays.** It asks for add-only Photos access (`NSPhotoLibraryAddUsageDescription`) on the first Save tap. It saves the plain frozen photo, or the crop after Crop, with no boxes. Save is hidden for an uncropped library photo. With access denied or restricted, the toast reads "Photos access is off" with Open Settings, and nothing is saved. A write error reads "The photo couldn't be saved." `DESIGN.md`'s "Nothing is saved or sent" and any other privacy copy change to say the photo is saved only when you tap Save. The camera usage string ("read on your device and never leaves it") gets the same check, since a saved photo can sync through iCloud Photos. The label stays Data Not Collected. (081)
- **Highlights.** Boxes come only from Vision. When the read came from Live Text, no boxes are drawn and the Highlights option is hidden, and the sheet still lists the kanji. Each box's tap region is at least 44 × 44 pt. Where expanded regions overlap, the box nearest the touch wins. VoiceOver reaches every kanji through the grid. (077, 078)
- **Sweep.** The line loops until the read finishes. Boxes fade in as the line passes once results exist. The sheet rises to half when the read is done and a full pass has finished. Under Reduce Motion there is no line or flash: boxes and the sheet appear with a short crossfade. (078, 079)
- **Learned.** On the scan, "learned" means "not new to you": green box and check for any stage past new (learning, familiar and known), the set 074's filter used and the design's own "unseen vs learned or known" split (`camera-design-notes.md:76`). Red box and NEW for kanji still at stage new. The subtitle's "N learned" counts that same set. It is a scan-only label and does not change 065's split of known from Learned on the You tab. "New to you" becomes the "New only" switch, off by default. (078, 079)
- **Missing states.** 074's copy is reused. No kanji found and read failed show in the half sheet ("No kanji found. Try a closer, sharper photo." / "That photo could not be read."), and Crop and X stay available. Camera access off and no camera show 074's viewfinder overlay with Open Settings and the library button. There is no blurry-photo hint. The found count and toasts are announced to VoiceOver. (076, 079)
- **Tile meaning.** The first one or two `KanjiEntry` meanings, joined by ", " on one line and truncated. The full meaning goes in the VoiceOver label. (079)
- **Crop.** Done crops the image, the crop becomes the frozen photo, the sweep reruns on it alone, and its results replace the old ones. Crop works again on a cropped photo. There is no undo, and X still returns to the live camera. (080)
- **Entry.** "Scan a kanji" replaces "Look up kanji in a photo" beside "Draw a kanji". Both stay Pro, and locked buttons look unchanged: a tap opens the paywall with that feature first. At accessibility text sizes the two buttons stack. (076)
- **Words and vertical text.** Every bundled kanji found gets its own tile and box, including a kanji that appears only inside a word (入 and 口 from 入口). Word results are out of scope for v1. Vertical text gets nothing special: Vision's boxes and line order, with Crop as the workaround.
