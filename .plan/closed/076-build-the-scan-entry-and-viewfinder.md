---
id: "076"
title: Build the scan entry and viewfinder
type: task
mode: AFK
status: closed
blocked_by: ["075"]
claimed: false
---

## Question

Can the Dictionary open the designed viewfinder from a "Scan a kanji" button?

## Notes

Skills: `apple`.
Design: `docs/ui-reference/camera/screens/0-entry-dictionary-scan-button.png`, `1-viewfinder.png`, `source/CameraViewfinder.dc.html`, `source/Camera.dc.html`, and `docs/ui-reference/source/Dictionary.dc.html`.
"Draw a kanji" and "Scan a kanji" sit side by side under the search bar. The viewfinder has Close top left, flash top right, a corner-bracket reticle, the hint pill "Point at a kanji, then tap the shutter", library bottom left and a neutral shutter (light ring and disc). It uses the dark overlay tokens: ink `rgba(21,19,15,.55)`, outline `rgba(239,232,216,.25)`, text `#efe8d8`. The shutter flashes white for about 0.2 s. Reuse `CameraSession` from 074. Presentation follows the decision in 075. Reduced motion turns off the flash animation.

## Resolution

Yes. "Scan a kanji" sits beside "Draw a kanji" under the Dictionary search bar (stacked at accessibility text sizes) and pushes the designed viewfinder onto the Dictionary stack with the nav and tab bars hidden (full record in `assets/076-build-the-scan-entry-and-viewfinder-report.md`):

- **Entry.** One `DictionaryActionButtons` view replaces `DrawSearchButton` and `PhotoLookupButton`. Titles are "Draw a kanji" and "Scan a kanji". Both keep the Pro gate and the outline style, with a 44 pt minimum height.
- **Route.** `path` is a `NavigationPath`. `PhotoLookupPresentation` is `Hashable` by the model's identity, so each push is its own route. The full-screen cover and the appearance-mode workaround are gone. Detail opened from a result keeps "Scan results" as its back label.
- **Viewfinder.** Corner-bracket reticle, hint pill "Point at a kanji, then tap the shutter", Close and flash (bolt) buttons on the ink and outline overlay colors, a rounded-square library button and a neutral 76 pt ring with a 58 pt disc. The camera starts only when the screen is live.
- **Flash.** A white blink of about 0.2 s on each shot, not built when Reduce Motion is on.
- **Still open for later tickets.** The tab bar stays hidden for the whole scan screen until the results sheet (079) brings it back at full height. A device check of the layout on a real iPhone has not been done.
- **Audit and CI.** Council approved in round 1 (claude 8, gemini 10, gpt 9) and again in round 2 on the CI fix (9, 10, 10). The first CI run failed because a test still read the removed `buttonMinHeight`. After the fix, build-test (429 tests) and unsigned-ipa passed.

Timing: wall 1h09m, active 8m, user 0s, wait 1h00m, blocked 0s | setup 55m, ci-fix 12m | tools 73 (4 subagent) | limits 0, compactions 0, handoffs 1 | ctx peak 146k | cost $2.56 sonnet-5-5 + $0.02 haiku-5-5
