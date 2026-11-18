---
id: "082"
title: Fix the crop photo fit and drag the whole frame
type: task
mode: AFK
status: open
blocked_by: []
claimed: true
---

## Question

Does Crop show the whole photo at its own aspect ratio, and can the learner drag the whole crop frame as well as its corners?

## Notes

Skills: `apple`, `diagnosing-bugs` for the fit bug.
Reported by the user on device after [Build Crop for the scanned photo](../closed/080-build-scan-crop.md):

- **Fit bug.** A square or landscape photo (from the library, or a cropped photo) zooms in to fill the height on the Crop screen instead of fitting inside it, so part of the photo is cut off. Crop should letterbox the photo to its own aspect ratio, centred, with the frame and handles placed on the visible photo. The user confirmed on 2026-11-17 that the zoom is on the frozen photo screen, not Crop; that fix is [084](084-fit-library-and-cropped-photos-on-the-frozen-photo.md). Crop keeps its fit only as hardening. Add a unit test on the fit geometry for portrait, square and landscape sizes.
- **Drag the frame.** Dragging inside the frame moves the whole frame without resizing it, clamped to the photo's edges. The corner handles keep resizing. Use plain SwiftUI gestures. If a whole-frame drag conflicts with the corner handles in a way that needs workarounds, keep the corners working, skip the frame drag and say why in the report. The user is fine without it. VoiceOver gets a matching move action if that's cheap.
- Keep the 44 pt corner targets. `PhotoLookupScreen.swift` is near SwiftLint's 400-line `file_length` limit, so keep the changes in `PhotoCropView.swift` and the photo lookup geometry files.

## Resolution

<Filled in at close.>
