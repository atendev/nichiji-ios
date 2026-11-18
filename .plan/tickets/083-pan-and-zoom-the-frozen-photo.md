---
id: "083"
title: Pan and zoom the frozen photo
type: task
mode: AFK
status: open
blocked_by: []
claimed: true
---

## Question

Can the learner pinch to zoom and drag to pan the frozen photo on the scan screen, with the kanji boxes staying on their kanji?

## Notes

Skills: `apple`.
The user asked for this after batch 3 (results sheet, Crop, Save). The frozen photo screen is `PhotoLookupScreen` with the sweep and boxes from [Build the frozen photo, scan sweep and highlights](../closed/078-build-the-frozen-photo-and-highlights.md) and the sheet from [Build the scan results sheet](../closed/079-build-the-scan-results-sheet.md).

- Pinch zooms from 1x (fit) up to a sensible cap, such as 4x, around the pinch point. Drag pans while zoomed, clamped so the photo never leaves the screen. Double-tap toggles between 1x and about 2.5x. Use SwiftUI gestures (`MagnifyGesture`, `DragGesture`), not a `UIScrollView` wrapper, unless SwiftUI can't do it without workarounds. Say which one you used in the report.
- The kanji boxes, their tap targets and the Highlights toggle follow the zoom and pan. A box tap still opens detail and is never stolen by the pan. The sweep plays at 1x, and zoom waits until it settles, as box taps already do.
- The sheet's peek/half/full pose still scales and lifts the photo. Zoom applies on top of that pose and resets to 1x on Retake, on a new photo and after a crop rescan. Decide whether a drag on the sheet header still wins over the photo pan, and say so in the report.
- Reduce Motion: zoom and pan follow the fingers, and the double-tap snaps without animation.
- `PhotoLookupScreen.swift` is near SwiftLint's 400-line `file_length` limit, so put the zoom state and gestures in their own file. Put the geometry (clamping, box transform) in a pure type with unit tests.

## Resolution

<Filled in at close.>

## Handoff

Branch `t3/pan-zoom-frozen-photo`. The work and the decision report are committed (see `git log -1`). Council approved in round 2 (Claude 8, Gemini 9, GPT 9), three minor problems declined. Audit rounds used: 2 of 5.

Done: `PhotoZoom.swift` (pure geometry), `PhotoZoomGestures.swift`, `FrozenPhotoView.swift` wiring, `PhotoZoomTests.swift` (18 tests, never run, no Swift toolchain), docs v0.33.0, report at `.plan/assets/083-pan-and-zoom-the-frozen-photo-report.md`.

Left, in order:
1. Push the branch without forcing. If the repo works through PRs, open one against `wayfinder/nichiji-v1-master` and link it. Return PUSHED. The master triggers and watches CI.
2. On "CI red", fix the named failure (changed hunks only through a council round, rounds continue from 2), commit, push, return PUSHED.
3. On "CI green" or "no CI", run the Timing close (`python3 -I ~/.claude/skills/wayfinder-runner/wf-time.py close --slug nichiji-v1 --ticket 083 --name 'Pan and zoom the frozen photo' --ticket-file .plan/tickets/083-pan-and-zoom-the-frozen-photo.md`), fill `## Resolution` in this file, delete this Handoff section, commit, push, return DONE with the Decisions line and Timing line.

Decisions line: Pinch (1x to 4x, about the pinch point), drag pan (clamped) and double-tap (1x or 2.5x) use SwiftUI gestures, not a UIScrollView wrapper. Boxes are re-mapped in screen space so strokes and 44 pt targets stay constant. A single tap waits out the double-tap window, zoom waits for the sweep and resets on a new photo, and a sheet header drag wins over the photo pan by hit testing.

Surfaced: none so far. Open question for device feedback, not a ticket: aspect-fill's cropped-off edges cannot be zoomed into.

Files to read first: the report above, `Nichiji/PhotoLookup/PhotoZoom.swift`, `Nichiji/Views/Dictionary/PhotoZoomGestures.swift`.
