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

## Handoff

Branch `t3/scan-entry-viewfinder`. The `wip:` commit holds all the code, tests and docs below. Audit round so far: 0 (no council dispatched).

Done:
- `DictionaryActionButtons.swift` (new): "Draw a kanji" and "Scan a kanji" side by side, stacked at accessibility sizes. `HandwritingSearchCopy.buttonTitle` is now "Draw a kanji"; the old `DrawSearchButton`, `PhotoLookupButton` and `buttonMinHeight` are gone.
- `CameraOverlayStyle.swift` (new): overlay colors (`cameraInk`, `cameraOutline`, `cameraText`, `cameraBase`), `ViewfinderReticle`, `ViewfinderShade`, `ViewfinderHint`.
- `PhotoLookupControls.swift`: ink/outline chrome buttons, `CameraLibraryIcon`, neutral 76/58 pt shutter.
- `PhotoLookupScreen.swift`: pushed screen, `.navigationTitle("Scan results")`, hidden nav and tab bars, reticle, white 0.2 s flash (off under Reduce Motion), bolt torch icon, `.task` starts the camera only when live, appearance-mode cover hack removed.
- `DictionaryView.swift`: `path` is a `NavigationPath`; `PhotoLookupPresentation` (now Hashable) is pushed; the full-screen cover is removed.
- Tests in `PhotoLookupTests.swift` (`ScanEntryTests`), `HandwritingSearchEntryTests` copy updated. Docs: DESIGN, PROGRESS, CHANGELOG (v0.27.0), IMPLOG.

Left, in order:
1. Run `council-audit` on the ticket question, the map's Notes and Decisions, and the diff against `main`. Rounds start at 1. Fix problems, up to five rounds.
2. Write `.plan/assets/076-build-the-scan-entry-and-viewfinder-report.md` (every decision, options, who chose, audit verdict, declined minor problems), run `unslop` on it, commit it with the work.
3. Push without forcing, open a PR against `wayfinder/nichiji-v1-master`, link it, return PUSHED.
4. On CI green, fill in Resolution, set `status: closed`, `claimed: false`, move the ticket to `closed/`, delete this section, commit, push, return DONE with the Decisions line.

Known risks for the audit: no Swift toolchain here, so nothing compiled; CI is the first build. Tab bar stays hidden for the whole scan screen (results states are ticket 079's). The `DictionaryView` `NavigationPath` change touches every `path.append` there.

Read first: `Nichiji/Views/Dictionary/PhotoLookupScreen.swift`, `CameraOverlayStyle.swift`, `DictionaryActionButtons.swift`, `DictionaryView.swift`.
