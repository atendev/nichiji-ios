---
id: "081"
title: Build Save to Photos for the scanned photo
type: task
mode: AFK
status: open
blocked_by: ["078"]
claimed: false
---

## Question

Can the learner save the frozen photo to Photos, if 075 keeps Save?

## Notes

Skills: `apple`.
Design: "Save" in `docs/ui-reference/camera/camera-design-notes.md`. A "Saved to Photos" toast with a green check shows for about 1.8 s. It uses add-only Photos access (`NSPhotoLibraryAddUsageDescription`, `PHPhotoLibrary` `.addOnly`), with a note when access is denied. Update `DESIGN.md`, the in-app privacy lines and `assets/app-store-listing.md` to match 075's wording. If 075 drops Save, close this ticket unbuilt.

## Resolution

<Filled in at close.>
