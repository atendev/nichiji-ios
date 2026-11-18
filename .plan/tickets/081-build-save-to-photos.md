---
id: "081"
title: Build Save to Photos for the scanned photo
type: task
mode: AFK
status: open
blocked_by: ["078"]
claimed: true
---

## Question

Can the learner save the frozen photo to Photos, if 075 keeps Save?

## Notes

Skills: `apple`.
Design: "Save" in `docs/ui-reference/camera/camera-design-notes.md`. A "Saved to Photos" toast with a green check shows for about 1.8 s. It uses add-only Photos access (`NSPhotoLibraryAddUsageDescription`, `PHPhotoLibrary` `.addOnly`), with a note when access is denied. Update `DESIGN.md`, the in-app privacy lines and `assets/app-store-listing.md` to match 075's wording. If 075 drops Save, close this ticket unbuilt.

## Resolution

Yes. A labelled Save option joins Highlights at the top right of the frozen photo. It writes the current photo (`model.photoData`, the crop once Crop lands) to Photos with add-only access, asked for on the first tap, and shows a "Saved to Photos" toast with a green check for about 1.8 s. Denied or restricted access shows "Photos access is off" with Open Settings, and a write error shows "The photo couldn't be saved." Both stay 5 s. Save is hidden for an uncropped library photo through `PhotoSaveModel.origin`, which Crop sets to `.cropped`. `NSPhotoLibraryAddUsageDescription` is added, and the camera usage string, the Privacy screen, `DESIGN.md`, the listing and the policy draft now say the photo is saved only when the learner taps Save. The label stays Data Not Collected. `PhotoSaveTests` covers the model, and the Photos write needs a device check. The scan screen's camera-access message moved to `CameraAccessMessage` to keep the file under SwiftLint's 400-line limit. The full record is in `assets/081-build-save-to-photos-report.md` (v0.29.0, PR 55).

Timing: wall 37m, active 6m, user 1m, wait 29m, blocked 0s | implement 2m, audit 32m (2 rounds), gate 2m | tools 55 (6 subagent) | limits 0, compactions 0, handoffs 0 | ctx peak 153k | cost $2.01 sonnet-5-5 + $0.02 haiku-5-5
