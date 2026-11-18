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

- **Fit bug.** A square or landscape photo (from the library, or a cropped photo) zooms in to fill the height on the Crop screen instead of fitting inside it, so part of the photo is cut off. Crop should letterbox the photo to its own aspect ratio, centred, with the frame and handles placed on the visible photo. Start at `PhotoCropView.canvas(in:)` and `PhotoFit.fittedFrame`, and check whether the frozen photo screen behind it has the same problem. Add a unit test on the fit geometry for portrait, square and landscape sizes.
- **Drag the frame.** Dragging inside the frame moves the whole frame without resizing it, clamped to the photo's edges. The corner handles keep resizing. Use plain SwiftUI gestures. If a whole-frame drag conflicts with the corner handles in a way that needs workarounds, keep the corners working, skip the frame drag and say why in the report. The user is fine without it. VoiceOver gets a matching move action if that's cheap.
- Keep the 44 pt corner targets. `PhotoLookupScreen.swift` is near SwiftLint's 400-line `file_length` limit, so keep the changes in `PhotoCropView.swift` and the photo lookup geometry files.

## Resolution

<Filled in at close.>

## Handoff

Branch `t3/fix-crop-fit-drag-frame`, wip commit on top of `b40917d`. Context hit 148k of 150k, so this is a handoff, not a stop. Tag `wfm-nichiji-v1-082-1794967719`.

**Done:** Frame drag (`PhotoCrop.translate`, `nudge(_:toward:)`, `Direction`, `frameRect`; `moveArea` in `PhotoCropView.swift`, corners sit above it; VoiceOver `accessibilityActions`). Copy hint changed. Crop now presents as `fullScreenCover` (was an `.overlay`). Tests in `PhotoCropTests.swift` (fit portrait/square/landscape, frame move, nudge). Docs v0.32.0: CHANGELOG, DESIGN, PROGRESS, IMPLOG.

**Fit bug is undiagnosed.** The old canvas math (`PhotoFit.fittedFrame`, min-scale) was already right and the Crop screen background is opaque. Gemini's theory: the overlay inherits an oversized width from the scan screen, so the photo fits by height and the sides are cut off. The cover removes that dependency. Say plainly in the report that this is hardening, not a reproduced root cause (no Swift toolchain). The frozen photo (`FrozenPhotoView`, aspect-fill by design for camera shots, ticket 078) cuts off square and landscape library photos and cropped photos. Not touched, because sibling 083 reworks it. Surface a ticket: "Fit library and cropped photos on the frozen photo screen", blocked by Pan and zoom the frozen photo.

**Council round 1** (saw the overlay version with no-op `.scaledToFit()`, since removed): claude 7 DISAPPROVE, gemini 6 DISAPPROVE, gpt 9 APPROVE. Both dissenters have one blocking problem: the zoom cause is undiagnosed and `.scaledToFit()/.clipped()` is a no-op. Fixes: no-ops removed, cover added, tests pin `frameRect` on the fitted photo. Minor declined so far: none.

**Left, in order:**
1. Round 2 council on the new diff (`git diff -- Nichiji NichijiTests > /tmp/082-diff.patch`). Send all three seats, because the fix makes gpt's approval stale. Each gets its own ledger row and the fix above. Seats: claude Agent `haiku`; gemini `delegate_task` antigravity `gemini-4-argon-high`; gpt `delegate_task` acpRegistry_github_copilot `gpt-6.1-sol` (role review, async, shared). Briefs are in `/tmp/082-brief.txt`.
2. `delegate_task` completion does not wake this thread. Start a `sleep` in the background, call `t3_background_wait` on it, then `task_status` each seat.
3. After APPROVE, write `.plan/assets/082-fix-crop-fit-and-drag-the-frame-report.md`, run unslop, commit. Push without forcing, open a PR against `wayfinder/nichiji-v1-master` if the repo uses PRs, link it, return PUSHED.
4. On CI green, run the Timing close and record the Resolution in this ticket (delete this section), commit, push, return DONE.

**Read first:** `Nichiji/Views/Dictionary/PhotoCropView.swift`, `Nichiji/PhotoLookup/PhotoCrop.swift`, `NichijiTests/Suites/PhotoCropTests.swift`.

