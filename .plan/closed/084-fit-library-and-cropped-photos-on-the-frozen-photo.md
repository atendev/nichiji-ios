---
id: "084"
title: Fit library and cropped photos on the frozen photo screen
type: task
mode: AFK
status: closed
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

A camera shot still aspect-fills; a library photo and any crop (`PhotoOrigin.library` or `.cropped`, a cropped shot included) is aspect-fitted whole, centred on the camera base. `PhotoOrigin.fitMode` picks the `PhotoFitMode`, and `PhotoFit.photoFrame` is the one rect the image, the boxes, their tap targets, the sweep and the Highlights mask all use. Zoom's 1x is that rect: `PhotoZoom` takes an optional content size and clamps the pan to it, an axis the scaled photo does not fill stays centred (so a letterboxed photo cannot be panned into its bars), and a filled shot's cut-off sides can now be zoomed into, which settles the open note on [Pan and zoom the frozen photo](083-pan-and-zoom-the-frozen-photo.md). Version v0.34.0. Tests: `PhotoFitModeTests` (portrait, narrow, square and landscape in both modes, box mapping, zoom clamp with a content size).

Council approved in round 2 (Claude 8, Gemini 9, GPT 9). CI green on e3ec10b (lint, build, tests): https://github.com/atendev/nichiji-ios/actions/runs/44238457276. PR: https://github.com/atendev/nichiji-ios/pull/60. Decision report: `.plan/assets/084-fit-library-and-cropped-photos-on-the-frozen-photo-report.md`.

Timing: wall 26m, active 11m, user 0s, wait 14m, blocked 0s | implement 2m, audit 4m (1 round), fix 4m, ci 15m | tools 45 (10 subagent) | limits 0, compactions 0, handoffs 0 | ctx peak 138k | cost $1.46 sonnet-5-5 + $0.04 haiku-5-5
