---
id: "082"
title: Fix the crop photo fit and drag the whole frame
type: task
mode: AFK
status: closed
blocked_by: []
claimed: false
---

## Question

Does Crop show the whole photo at its own aspect ratio, and can the learner drag the whole crop frame as well as its corners?

## Notes

Skills: `apple`, `diagnosing-bugs` for the fit bug.
Reported by the user on device after [Build Crop for the scanned photo](080-build-scan-crop.md):

- **Fit bug.** A square or landscape photo (from the library, or a cropped photo) zooms in to fill the height on the Crop screen instead of fitting inside it, so part of the photo is cut off. Crop should letterbox the photo to its own aspect ratio, centred, with the frame and handles placed on the visible photo. The user confirmed on 2026-11-17 that the zoom is on the frozen photo screen, not Crop; that fix is [084](../tickets/084-fit-library-and-cropped-photos-on-the-frozen-photo.md). Crop keeps its fit only as hardening. Add a unit test on the fit geometry for portrait, square and landscape sizes.
- **Drag the frame.** Dragging inside the frame moves the whole frame without resizing it, clamped to the photo's edges. The corner handles keep resizing. Use plain SwiftUI gestures. If a whole-frame drag conflicts with the corner handles in a way that needs workarounds, keep the corners working, skip the frame drag and say why in the report. The user is fine without it. VoiceOver gets a matching move action if that's cheap.
- Keep the 44 pt corner targets. `PhotoLookupScreen.swift` is near SwiftLint's 400-line `file_length` limit, so keep the changes in `PhotoCropView.swift` and the photo lookup geometry files.

## Resolution

Yes to the drag; the fit is hardening only. Dragging inside the Crop frame moves the whole frame without resizing it, clamped to the photo's edges. The four 44 pt corners sit above the move area and keep resizing, so no workaround was needed. VoiceOver gets four move actions (left, right, up, down). The hint reads "Drag the corners to resize the frame, or drag inside it to move it". The Crop-screen fit was never reproduced: the old `PhotoFit.fittedFrame` math was already correct, so the canvas math is unchanged and `PhotoCrop.frameRect` is pulled out and tested on portrait, square and landscape photos. The user's zoom bug is on the frozen photo screen and belongs to [084](../tickets/084-fit-library-and-cropped-photos-on-the-frozen-photo.md); `FrozenPhotoView` is untouched. Crop now presents as a `fullScreenCover` instead of an overlay, kept because it is harmless: same opaque background, hidden status bar, Done and Cancel unchanged, slide-up instead of a fade. A device check of the drag and the cover is still due. Changes sit in `PhotoCropView.swift`, `PhotoCrop.swift` and `PhotoCropTests.swift`; `PhotoLookupScreen.swift` is unchanged. CI green on e755690 (run 44232109989). Report: `assets/082-fix-crop-fit-and-drag-the-frame-report.md`. v0.32.0.

Timing: wall 34m, active 13m, user 0s, wait 18m, blocked 0s | implement 3m, audit 9m (2 rounds), gate 30s, ci 11m, handoff 7m | tools 79 (11 subagent) | limits 0, compactions 0, handoffs 1 | ctx peak 154k | cost $2.78 sonnet-5-5 + $0.04 haiku-5-5
