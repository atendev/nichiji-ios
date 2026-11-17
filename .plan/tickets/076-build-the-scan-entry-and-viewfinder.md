---
id: "076"
title: Build the scan entry and viewfinder
type: task
mode: AFK
status: open
blocked_by: ["075"]
claimed: true
---

## Question

Can the Dictionary open the designed viewfinder from a "Scan a kanji" button?

## Notes

Skills: `apple`.
Design: `docs/ui-reference/camera/screens/0-entry-dictionary-scan-button.png`, `1-viewfinder.png`, `source/CameraViewfinder.dc.html`, `source/Camera.dc.html`, and `docs/ui-reference/source/Dictionary.dc.html`.
"Draw a kanji" and "Scan a kanji" sit side by side under the search bar. The viewfinder has Close top left, flash top right, a corner-bracket reticle, the hint pill "Point at a kanji, then tap the shutter", library bottom left and a neutral shutter (light ring and disc). It uses the dark overlay tokens: ink `rgba(21,19,15,.55)`, outline `rgba(239,232,216,.25)`, text `#efe8d8`. The shutter flashes white for about 0.2 s. Reuse `CameraSession` from 074. Presentation follows the decision in 075. Reduced motion turns off the flash animation.

## Resolution

<Filled in at close.>
