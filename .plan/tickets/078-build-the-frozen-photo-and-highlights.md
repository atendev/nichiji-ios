---
id: "078"
title: Build the frozen photo, scan sweep and highlights
type: task
mode: AFK
status: open
blocked_by: ["076", "077"]
claimed: true
---

## Question

Does the frozen shot show the scan sweep and a red or green box on each kanji, with Crop, Save and Highlights options?

## Notes

Skills: `apple`.
Design: `docs/ui-reference/camera/screens/2-photo-frozen-scanning.png`, `3-photo-with-highlights.png`, `source/CameraScanning.dc.html`, `source/CameraScene.dc.html`.
The scan line sweeps down for about 1.6 s with the pill "Scanning for kanji…" (sweep timing per 075). Boxes are new `#e8603f` and learned `#8db483`, each with about 22% fill. The options top right are Crop, Save and Highlights, each with a text label: Highlights toggles the boxes, and Crop and Save open their tickets' work (hidden until those land). X at top left goes back to the camera. A tap on a box opens that kanji's detail. Boxes map from image to view coordinates under aspect-fill. Reduced motion skips the sweep.

## Resolution

<Filled in at close.>

## Handoff

Branch `t3/build-frozen-photo-highlights`; SHA is the `wip:` commit on its tip. Audit round used so far: 0. Context reached 150k before the first council dispatch.

**Done (uncommitted work is now in the wip commit):**
- `Nichiji/PhotoLookup/PhotoHighlights.swift`: `PhotoFit` (aspect-fill map), `HighlightBox`, `PhotoHighlights` (boxes, 44 pt tap region, nearest-box hit test), `ScanSweep` (loop clock, finish pass, box fade).
- `Nichiji/Views/Dictionary/FrozenPhotoView.swift`: `FrozenPhotoLayer`, scan line, highlights layer, `PhotoOptionButton`, `ScanningPill`.
- `PhotoLookupScreen.swift`: sweep state, X retakes in the frozen state, Highlights option (only after a Vision read with boxes), pill while reading, struct split into an extension for SwiftLint's type body length. `CameraOverlayStyle.swift`: `cameraNew` and `cameraLearned`.
- `NichijiTests/Suites/PhotoHighlightsTests.swift`: geometry, hit test and sweep tests.
- Docs: `docs/DESIGN.md`, `PROGRESS.md`, `CHANGELOG.md` (v0.28.0, MINOR).

**Left, in order:**
1. Add the IMPLOG entry for v0.28.0 in `docs/IMPLOG.md` (Requirements and Deviation Report, same shape as the v0.27.0 entry; Test Results: not run, no Swift toolchain, CI is the check).
2. Re-read the new Swift once for compile and `swiftlint --strict` risks (no toolchain here; CI compiles). Watch file_length of `PhotoLookupScreen.swift` (about 383 of 400 lines).
3. Run the council-audit (round 1) on the diff against the ticket's question, the map's Notes and Decisions (075, 076, 077).
4. Write `.plan/assets/078-build-the-frozen-photo-and-highlights-report.md`, run unslop on it, run the timing close, record the resolution in this ticket (delete this section), commit, push, open a PR against `wayfinder/nichiji-v1-master`, return PUSHED.

**Decisions made so far (for the report):** the existing results panel stays until the results sheet ticket; it covers up to 55% of the photo. Boxes are not filtered by "New to you". The sweep line finishes the pass in progress after results land (no restart). Taps on boxes wait until the sweep settles. Crop and Save are not built; a code comment marks where they join Highlights.

**Open problems from the council:** none yet.

**Read first:** `PhotoHighlights.swift`, `FrozenPhotoView.swift`, `PhotoLookupScreen.swift`, the tests file.
