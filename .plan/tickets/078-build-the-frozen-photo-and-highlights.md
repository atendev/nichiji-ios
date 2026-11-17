---
id: "078"
title: Build the frozen photo, scan sweep and highlights
type: task
mode: AFK
status: open
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

<Filled in at close.>
