# Decision report: Build the scan entry and viewfinder

Ticket 076. Branch `t3/build-scan-entry-viewfinder`, continued from the `wip:` commit `45de314` on `t3/scan-entry-viewfinder`. Version bump: minor, v0.27.0 (a new user-visible entry and viewfinder). Tagging is the user's call.

The work was written in an earlier thread and handed off with no council round used. This thread audited it, wrote this report and committed. Nothing could be compiled here, because the machine has no Swift toolchain. CI is the first build.

## Gates

- The repo's `docs/workflow.md` and `AGENTS.md` define the Phase 5 loop. The master's brief says to commit without asking the user and to leave the merge to the master. This run follows that brief.
- The Jev audit and the grilling step were skipped. The parent session already ran the audit, and no grilling ticket is involved.
- The `map.md` file is not edited. The Decisions line goes back to the master.

## Decisions

Each row gives the question, the options, the choice and who chose.

1. **Present the scan as a push or a full-screen cover?**
   - Options: keep `fullScreenCover`, or push onto the Dictionary `NavigationStack`.
   - Choice: push. It follows the decision in ticket 075, which also gives kanji detail a "< Scan results" back label.
   - Chosen by: ticket 075 (user and grilling subagent). The implementer applied it.

2. **How does `path` hold both kanji routes and the scan route?**
   - Options: a heterogeneous `NavigationPath`, or an enum route type.
   - Choice: `NavigationPath`. Every use of `path` in `DictionaryView.swift` is `path.append`, so nothing else changes.
   - Chosen by: implementer. The claude seat asked whether array-only APIs were in use, and a grep showed none.

3. **How does `PhotoLookupPresentation` become `Hashable`?**
   - Options: hash the model, or hash an identity.
   - Choice: equality and hash use `ObjectIdentifier` of the model. Each open gets a fresh model, so each push is its own route.
   - Chosen by: implementer. A test covers it.

4. **Hide the tab bar for the whole scan screen, or only until the sheet is full?**
   - Choice: hide it for the whole screen in this ticket. The peek, half and full results states belong to ticket 079.
   - Chosen by: implementer. Logged as a known gap for ticket 079.

5. **How do the two entry buttons sit?**
   - Options: side by side always, or side by side with a stacked fallback.
   - Choice: side by side, stacked at accessibility text sizes so the labels do not truncate. Both keep the existing outline style and a 44 pt minimum height. The old `DrawSearchButton` and `PhotoLookupButton` are replaced by one `DictionaryActionButtons` view.
   - Chosen by: implementer, under the `apple` skill's tap target rule.

6. **Titles and hint copy.**
   - Choice: "Draw a kanji", "Scan a kanji", and the hint "Point at a kanji, then tap the shutter", all from the design. The old title "Draw a kanji to search" is gone from code, tests and docs.
   - Chosen by: ticket note and design.

7. **Overlay colors.**
   - Choice: `cameraInk`, `cameraOutline`, `cameraText` and `cameraBase` as fixed colors. They do not change between Light and Dark, because they sit over the live feed. The values are the ticket's tokens.
   - Chosen by: ticket note.

8. **Reticle shape and size.**
   - Choice: four corner brackets drawn as a `Shape`, 3 pt stroke, 34 pt arms, 10 pt corner radius. The box is 29 pt in from each side, at most 360 pt tall and at most 42% of the screen height, and starts at 160/844 of the screen height. These follow the 390 by 844 artboard in the design.
   - Chosen by: implementer from `CameraViewfinder.dc.html`.

9. **Shutter, library and flash controls.**
   - Choice: a 76 pt ring around a 58 pt disc, both in the light text color. The library button is a rounded square. The flash control uses the `bolt` symbols. Chrome buttons use the ink fill and outline.
   - Chosen by: implementer from the design. The old material backgrounds are removed.

10. **How does the white flash work, and what does Reduce Motion do?**
    - Options: keep the black blink, or use a white blink of about 0.2 s.
    - Choice: white, 0.9 opacity peak, two `easeOut` steps of 0.1 s each. When Reduce Motion is on, the flash view is not built.
    - Chosen by: ticket note.

11. **Start the camera on appear?**
    - Choice: `.task` starts the camera only when the screen is live. A pushed screen can reappear with a frozen shot, and starting then would waste the session.
    - Chosen by: implementer.

12. **Remove the appearance-mode workaround?**
    - Choice: remove it. It existed because a presented cover did not follow the root's live scheme change. A pushed screen inherits the scheme from the stack.
    - Chosen by: implementer. A grep shows other files keep their own `@AppStorage` copies for their own sheets.

13. **Pro gate.**
    - Choice: unchanged. A locked "Scan a kanji" opens the paywall and the button looks the same.
    - Chosen by: ticket 075.

## Audit

Council, round 1, with five rounds allowed. Verdict APPROVE. Scores: claude 8, gemini 10, gpt 9.

Problems raised, all by the claude seat and all minor:

- `NavigationPath` might break array-only uses of `path`. Rebutted. Every use is `path.append` or the stack binding (`DictionaryView.swift` lines 26, 59, 94, 110, 207 and 267).
- The removed symbols may still be referenced. Rebutted. A grep over the app, unit tests and UI tests found no references to `DrawSearchButton`, `PhotoLookupButton`, `CameraChromeIcon` or `buttonMinHeight`. The remaining `appearanceModeRaw` hits are other files with their own storage.
- The `copy` and `shutterMetrics` tests mostly repeat literals. Declined. They are cheap guards on the design's words and numbers, and one seat raised it.

## Left for later tickets

- Boxes, the sweep and the frozen photo: ticket 078.
- Results sheet states and the tab bar returning at full height: ticket 079.
- Crop: ticket 080. Save to Photos: ticket 081.
- Device check of the viewfinder layout on a real iPhone. It is not possible here.
