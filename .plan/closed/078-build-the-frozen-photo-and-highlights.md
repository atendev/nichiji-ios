---
id: "078"
title: Build the frozen photo, scan sweep and highlights
type: task
mode: AFK
status: closed
blocked_by: ["076", "077"]
claimed: false
---

## Question

Does the frozen shot show the scan sweep and a red or green box on each kanji, with Crop, Save and Highlights options?

## Notes

Skills: `apple`.
Design: `docs/ui-reference/camera/screens/2-photo-frozen-scanning.png`, `3-photo-with-highlights.png`, `source/CameraScanning.dc.html`, `source/CameraScene.dc.html`.
The scan line sweeps down for about 1.6 s with the pill "Scanning for kanji…" (sweep timing per 075). Boxes are new `#e8603f` and learned `#8db483`, each with about 22% fill. The options top right are Crop, Save and Highlights, each with a text label: Highlights toggles the boxes, and Crop and Save open their tickets' work (hidden until those land). X at top left goes back to the camera. A tap on a box opens that kanji's detail. Boxes map from image to view coordinates under aspect-fill. Reduced motion skips the sweep.

## Resolution

Yes. The frozen shot now shows the scan sweep and a red or green box on each kanji, with a Highlights option (full record in `assets/078-build-the-frozen-photo-and-highlights-report.md`; council APPROVE in round 2 after a VoiceOver tap guard fix; CI green):

- **Sweep.** The shot freezes full screen at the shutter. A vermilion line loops down it, 1.6 s a pass, with the pill "Scanning for kanji…". When results land the pass in progress finishes: each box fades in as the line reaches it, and the line goes at the bottom. Reduce Motion drops the line and crossfades the boxes together.
- **Boxes.** One per Vision box: new `#e8603f`, started `#8db483`, about 22% fill, mapped from image to view under aspect-fill (`PhotoFit`). Boxes are not filtered by "New to you".
- **Taps.** A tap opens that kanji's detail. Each box has a tap region of at least 44 x 44 pt, the nearest box wins on overlap, and taps (touch and VoiceOver) wait until the sweep settles.
- **Options.** X at top left removes the photo and returns to the camera. A labelled Highlights option toggles the boxes and shows only after a Vision read with boxes. Crop and Save are not built; a code comment in `topBar` marks where they join.
- **Results panel.** The old panel stays, up to 55% of the photo, until the results sheet ticket.
- **Tests.** Geometry, box colors, tap regions, the hit test and the sweep clock are unit-tested in `PhotoHighlightsTests`. The look, the fade and taps on real Vision boxes need a device check.
- **Version.** v0.28.0 (MINOR); tagging stays with the user.

Timing: wall 56m, active 10m, user 0s, wait 45m, blocked 0s | implement 6m, audit 3m (2 rounds), ci 45m | tools 73 (5 subagent) | limits 0, compactions 0, handoffs 1 | ctx peak 154k | cost $2.76 sonnet-5-5 + $0.02 haiku-5-5
