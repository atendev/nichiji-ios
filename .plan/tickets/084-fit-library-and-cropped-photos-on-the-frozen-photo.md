---
id: "084"
title: Fit library and cropped photos on the frozen photo screen
type: task
mode: AFK
status: open
blocked_by: ["083"]
claimed: false
---

## Question

Does the frozen photo screen show a library or cropped photo whole, at its own aspect ratio, while camera shots still fill the screen?

## Notes

Skills: `apple`.
The user found this on device. After Crop's Done, or with a square or landscape library photo, the frozen photo behind the results sheet zooms in to fill the height and cuts off the sides. On 2026-11-17 the user confirmed the zoom is on this screen, not the Crop screen. The cause is that `FrozenPhotoView` aspect-fills by design for camera shots ([Build the frozen photo, scan sweep and highlights](../closed/078-build-the-frozen-photo-and-highlights.md)).

- Camera shots keep aspect-fill. Library photos and crops aspect-fit, centred on the camera base colour. The screen already knows the photo's origin (`PhotoSaveModel.origin`: `.camera`, `.library`, `.cropped`), and the frozen view can take a fill or fit mode from it. A camera shot that was cropped counts as cropped.
- The kanji boxes, their tap targets, the sweep and the Highlights layer use the same fitted rect, so the boxes stay on their kanji in both modes. Put the fill/fit rect in pure geometry with unit tests for portrait, square and landscape photos in both modes.
- Pan and zoom ([Pan and zoom the frozen photo](../closed/083-pan-and-zoom-the-frozen-photo.md)) lands first. Its 1x is the fitted rect, and its pan clamp uses the fitted photo's bounds, so a letterboxed photo can't be panned into the bars at 1x. This also settles 083's open note that aspect-fill's cut-off edges can't be zoomed into.
- The sheet's peek/half/full pose still scales and lifts the photo.
- `PhotoLookupScreen.swift` is near SwiftLint's 400-line `file_length` limit, so keep the work in the frozen photo and geometry files.

## Resolution

<Filled in at close.>
