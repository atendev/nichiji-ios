# Build the font style setting and heavier English text: decision report

Gates used: the repo's `docs/workflow.md` Phase 5 loop, with the wayfinder-runner child rules from the master. The commit gate was answered by the master's brief (commit every time, no question). CI was skipped by the brief. The council ran Claude auditors only, because the Gemini and GPT seats are out of quota. The three seat scores below come from three Claude (haiku) auditors, each with a different angle, so they are not three providers.

## Size check

The earlier thread's note said fonts add about 6.3 MB to each bundle and the datasets are 5.3 MB of the 8 MB Shared budget, yet claimed it fits. It did not. Measured from the built files:

| Item | Bytes | MiB |
| --- | --- | --- |
| `Dataset/Shared` | 5,335,428 | 5.09 |
| `Dataset/AppOnly` | 12,284,163 | 11.72 |
| Dataset total (Shared plus AppOnly) | 17,619,591 | 16.80 |
| Fonts with the large Zen Kaku Gothic New Regular | 6,314,308 | 6.02 |
| Fonts after the fallback (Shippori 4,081,760, Zen Regular 70,576, Medium 70,072, Bold 69,476) | 4,291,884 | 4.09 |
| Fonts before this ticket | 4,222,408 | 4.03 |

Widget bundle (Shared data plus fonts) and app set (all data plus fonts):

| Option | Widget | App |
| --- | --- | --- |
| Large Zen file, as the earlier thread built it | 11.11 MiB | 22.83 MiB |
| Fallback, as shipped | 9.18 MiB | 20.90 MiB |
| Before this ticket | 9.12 MiB | 20.83 MiB |

Verdict:
- The budgets as `tools/dataset/build.py` enforces them count dataset files only. There the widget set is 5.09 MiB of 8 and the app set is 16.80 MiB of 24. Both hold, and fonts do not change them.
- With the fonts counted, which is how the ticket asks for the check, the 8 MiB Shared budget does not hold. The large Zen file puts the widget at 11.11 MiB. The 24 MiB app budget holds at 22.83 MiB, but only if the embedded widget extension is not counted.
- The ticket's fallback applies, so gothic draws in the system Japanese font. The fallback does not make the widget fit. It is 9.18 MiB with fonts counted, and it was already 9.12 MiB before this ticket, so the fonts-counted reading of the Shared budget had been over since Shippori Mincho went into the widget. These figures are hand arithmetic; nothing in CI checks them.
- The master may want to decide whether the 8 MiB Shared budget means data only (then nothing is wrong) or the whole widget bundle (then the widget is over, with or without this ticket).

## Decisions

1. **Gothic: bundled Zen Kaku Gothic New with kanji, or the system Japanese font.**
   Options: keep the large Zen Regular (2.09 MB in the app and again in the widget), or fall back to Hiragino Sans W3.
   Choice: the system font, per the ticket's rule and the master's brief, because the Shared budget fails with fonts counted. Made by the main thread. The 46 kanji the Zen file lacks no longer matter, so the test that pinned them was dropped.
   Consequence: `ZenKakuGothicNew-Regular.ttf` went back to the 70,576 B interface subset, `Fonts/README.md` says why, and `KanjiFontStyle.gothic.postScriptName` is `HiraginoSans-W3`. It scales with Dynamic Type through `Font.custom(... relativeTo:)`.
2. **How a style change re-renders screens.**
   Options: an environment value, a root `id`, or Observation.
   Choice: Observation. Tokens read `KanjiFontStyle.current`, which reads `KanjiFontStyleStore.shared.style`, inside view bodies. A root `id` would reset navigation. Made by the earlier implementer thread, kept here. A test checks that reading `Font.kanjiHero` is tracked.
3. **Font file by weight.** `InterfaceFace(weight:)` maps Medium to Medium, Semibold and heavier to Bold, anything lighter to Regular. Title and heading use Bold, body and callout Medium, caption Regular. The clamp is gone. Four call sites went to `.bold`: the You tiles (32 pt), the Review due count (64 pt), the level-complete figure and the scan sheet heading. Implementer's choice from the ticket.
4. **Preference storage.** The style is stored as `kanjiFontStyle` in the App Group `UserDefaults`, read by `LearnerPreferencesSnapshot` and by `KanjiFontStyleStore`. Existing learners have no value, so they get serif. The widget provider calls `reload()` before it builds an entry, and the app reloads timelines on change.
5. **Onboarding.** `OnboardingStep.kanjiStyle` sits after Welcome, so there are nine steps and eight progress segments. The step is not persisted anywhere, so shifting raw values is safe.
6. **Version.** MINOR, v0.38.1 to v0.39.0, not tagged.

## Audit

Round 1 (three Claude auditors): DISAPPROVE 5, DISAPPROVE 6, DISAPPROVE 7.
- Fixed: the docs said the size criterion was "Met" while the widget is still 9.18 MiB with fonts counted (all three seats, one blocking). They now say "partly met" with the figures. A `var` mutated in a `@Sendable` `onChange` closure would fail under Swift 6 strict concurrency (two seats, one blocking). It now uses a lock-backed `ChangeFlag`. The pre-ticket font figure was corrected to 4.03 MiB and 9.12 MiB. The changelog said "both widgets" but there is one widget with all families, so the wording changed. The README's unmeasured "46 kanji" claim was removed.
- Rebutted with evidence: a stale snapshot overwriting the style on `save(to:)` (two seats). The only caller outside the model is `LevelCompleteView.swift:161-162`, which loads and saves in the same call. `OnboardingStep` raw values shifting (two seats): `OnboardingStep(rawValue:)` appears only in `OnboardingFlow.swift:122` and `:128`, and no other use stores a step. The version bump being unverifiable: the version lives at the top of `docs/CHANGELOG.md`. The Bold file's existence: it is in `Fonts/` at 69,476 B and listed in both `UIAppFonts`.

Round 2 (same three angles): APPROVE 8, APPROVE 8, APPROVE 8. Three minor problems declined or fixed after approval:
- The changelog's "9.2 MiB, as before this change" misstated the baseline (all three seats). Fixed to 9.18 MiB, 9.12 MiB before.
- "2.09 MB per weight" implied all weights were measured (one seat). Fixed to "the Regular file alone".
- The fonts-counted figures are not checked by CI (one seat). Declined as a code change; the IMPLOG now says they are hand arithmetic.
- The shared-store write in `tokensAreObservable` (one seat, round 1) was declined: the suite is serialized and the test restores the original style in `defer`.

## Not verified

Swift is not compiled here. CI is the first compile and test run, and the master runs it on the merged batch. The 44 pt tap targets and Dynamic Type on the cards come from `.minTouchTarget()` and a stacked layout at accessibility sizes, and need the device check in [Check the new fonts on a device](../tickets/093-check-the-new-fonts-on-a-device.md).
