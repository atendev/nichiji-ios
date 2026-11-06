---
id: "066"
title: Fix known kanji levels and the blank draw sheet
type: task
mode: AFK
status: closed
blocked_by: []
claimed: false
---

## Question

Two fixes from trying the v0.23.0 build. Which groups should the Known kanji picker list, and why does "Draw a kanji to search" open an empty sheet once Pro is unlocked?

## Notes

Skills: `diagnosing-bugs` for the sheet, `tdd` for the scope rule, `apple` for UI, `unslop` for all prose.
From the user after trying the build:
- The picker lists the learner's level and every easier level below it, in onboarding and in Settings. JLPT runs N5 (easiest) to N1, so N3 shows N5, N4 and N3. Jōyō grade 3 shows grades 1 to 3, and Secondary sits after grade 6. Typed search still reaches every level.
- With the dev unlock on, tapping "Draw a kanji to search" in Dictionary opens an empty dark sheet.

## Resolution

Fixed in v0.24.0.

- The Known kanji picker lists the learner's level and every easier one, in onboarding and in Settings alike. JLPT N3 lists N5, N4 and N3; Jōyō grade 3 lists grades 1 to 3, and Secondary lists grades 1 to 6 plus Secondary. "Other kanji" and name kanji are left out because they are not easier levels. With the custom pool active the picker lists every group, since Settings then shows "Custom · N kanji" and no level. Typed search still reaches every level.
- The blank sheet came, most likely, from `.sheet(isPresented:)` wrapping `if let handwriting`. That optional was set in the same update that presented the sheet and was read nowhere else in `body`. Until the dev unlock, the locked path opened the paywall, so this code had never run on a device. The sheet now uses `.sheet(item:)` over `DrawSearchPresentation`, so the model arrives as the closure's argument. No automated test opens the sheet; the first-tap check is listed in [Prepare the v1.0 release build](../tickets/054-prepare-the-v1-release-build.md).
- At the merge question the user asked for two more changes. The draw pad now clears when the sheet closes. And a level pick marks every still-new kanji in the easier levels as known. The user chose a separate `wasHandKnown` flag so a later pick can remove automatic marks and keep hand marks. The flag defaults to true, so marks made in v0.23 migrate as hand marks. Level picks are the onboarding step, Settings level or system changes, and Start on level-complete. A daily order change or a custom pool edit is not a level pick. Unmarking a kanji in an easier level by hand leaves no trace, so the next level pick marks it again.
- CI: pending; see Final Report.
