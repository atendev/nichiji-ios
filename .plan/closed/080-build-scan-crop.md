---
id: "080"
title: Build Crop for the scanned photo
type: task
mode: AFK
status: closed
blocked_by: ["078"]
claimed: false
---

## Question

Can the learner crop the frozen photo and rescan only that part?

## Notes

Skills: `apple`.
Design: `docs/ui-reference/camera/screens/8-crop.png`, `source/CameraCrop.dc.html`, and "Crop" in `camera-design-notes.md`.
The photo shows at full size with the rest dimmed, a crop frame with corner handles and thirds lines, the title "Crop", the hint "Drag the corners to choose the part to scan", and Cancel / Done (Done is the only vermilion fill). The handles really drag, unlike in the mockup. Done rescans per 075, and Cancel returns to the results. Corner targets are at least 44 pt.

## Resolution

Yes. A labelled Crop option on the frozen photo opens its own `PhotoCropView`: photo at full size, rest dimmed, thirds lines, four draggable corner handles with 44 pt targets (VoiceOver can nudge them), and Cancel / Done. Done crops the pixels (upright, JPEG), the crop becomes the photo, and the model reads it again with the sweep. Cancel returns to the results. Crop shows once the sweep ends, in found, no-kanji and failed states, and works again on a cropped photo. A frame still covering the whole photo closes like Cancel. The entry and hook sit in `PhotoCropView.swift`, so `PhotoLookupScreen.swift` stays at 390 lines. The model keeps no "is cropped" flag; the Save ticket adds what it needs. Report: `assets/080-build-scan-crop-report.md`. v0.29.0.

Timing: wall 23m, active 9m, user 0s, wait 13m, blocked 0s | implement 2m, audit 3m (2 rounds), fix 1m, gate 34s, ci 13m | tools 57 (12 subagent) | limits 0, compactions 0, handoffs 0 | ctx peak 152k | cost $2.05 sonnet-5-5 + $0.04 haiku-5-5
