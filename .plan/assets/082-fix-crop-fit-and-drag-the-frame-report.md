# Decision report: Fix the crop photo fit and drag the whole frame

Branch `t3/fix-crop-fit-drag-frame-2`, continued from `8aa1e0a`. Version bump to v0.32.0 is in the work (CHANGELOG, DESIGN, PROGRESS, IMPLOG). Tagging is the user's call.

## Scope

The user's bug is ticket 084's. On 2026-11-17 the user confirmed the zoom happens on the frozen photo screen, after Crop's Done or with a library photo, not on the Crop screen. Ticket 084 ("Fit library and cropped photos on the frozen photo screen", blocked by 083) owns that fix, and `FrozenPhotoView` is untouched here. This ticket delivers the whole-frame drag, plus the Crop-screen fit as hardening only.

The Crop-screen fit bug was never reproduced. This host has no Swift toolchain. The old `PhotoFit.fittedFrame` math (min scale) was already correct, and the Crop background was already opaque. CI is the first compile.

## Decisions

1. **Frame drag.** Question: how does the learner move the whole frame? Options: a second gesture over the whole canvas, or a drag on the frame itself. Choice: `moveArea` in `PhotoCropView.swift`, a drag on the frame outline with `contentShape(Rectangle())`, placed below the four 44 pt corner targets in the ZStack so the corners win their own hit tests. The frame is at least 88 pt a side, so its middle stays draggable and no workaround was needed. Made by: implementer. Audit: all three seats approved.
2. **Drag math.** The pure helpers `PhotoCrop.translate` (normalized and in points), `frameRect(for:fitted:)`, and `nudge(_:toward:)` clamp the frame to the photo and never resize it. Made by: implementer. Unit tests in `PhotoCropTests.swift` cover frame moves, clamping, nudges, and `frameRect` on a portrait, a square and a landscape photo.
3. **VoiceOver.** Four move actions (left, right, up, down) on the frame element, cheap because they reuse `nudge`. Made by: implementer.
4. **Hint copy.** Changed to "Drag the corners to resize the frame, or drag inside it to move it". Made by: implementer.
5. **Crop-screen fit.** Question: change the fit math? Options: leave as is, or harden. Choice: keep the math, extract `frameRect`, and pin portrait, square and landscape geometry in tests. Round 1 added `.scaledToFit()` and `.clipped()`; two seats called these no-ops, and the implementer removed them. Made by: implementer, after council round 1.
6. **Overlay to `fullScreenCover`.** Question: keep the cover given the reduced scope? Options: revert to the overlay, or keep the cover if harmless. Choice: keep it. The checks, from the code (no device run):
   - `PhotoCropView` has an opaque `Color.cameraBase` background with `ignoresSafeArea()`, so the cover looks the same as the overlay did.
   - `PhotoCropView` sets its own `.statusBarHidden()`, matching the scan screen's `.statusBarHidden()`. A full-screen cover's presented controller controls the status bar, so the setting inside the cover is the one that applies.
   - The cover hides the tab bar by covering it.
   - Cancel sets the binding false. Done sets it false, then skips a full-photo frame and otherwise awaits `model.crop(to:)` and calls `onCropped`. The binding's getter also requires a non-nil image, so a changed photo during dismissal cannot reopen it.
   - The visible difference is the cover's slide-up transition instead of the overlay's 0.2 s fade. Judged harmless.
   Made by: main thread. Audit: all three seats approved. Needs a device check along with the drag.
7. **Declined minor problem.** The claude seat noted that the layering of the move area under the corner handles is reasoned from the code and has no automated test. Declined. SwiftUI hit-test layering has no unit-test seam in this repo, and the device check covers it.

## Audit

- Round 1 (overlay version, full scope): claude 7 DISAPPROVE, gemini 6 DISAPPROVE, gpt 9 APPROVE. The blocking problem from both dissenters was an undiagnosed zoom cause and no-op modifiers. Fixed by removing the modifiers and adding the cover. The cause turned out to be on the frozen photo screen, so it moved to ticket 084.
- Round 2 (reduced scope, cover): claude 8 APPROVE, gemini 9 APPROVE, gpt 9 APPROVE. One minor problem, declined above. The gate opened.

## For the user

Check on device: the frame moves when dragged inside it, the corners still resize, VoiceOver offers the four move actions, and Crop looks and dismisses correctly as a cover. Zoom on library or cropped photos on the frozen screen stays until ticket 084.
