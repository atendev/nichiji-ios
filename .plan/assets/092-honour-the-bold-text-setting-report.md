# Decision report: Honour the iPhone's Bold Text setting

Ticket: `092-honour-the-bold-text-setting`. Branch `t3/honour-bold-text-setting-2`, started from the handoff commit `9f11d086`. This is attempt 2 under wayfinder-master. Attempt 1 stopped at audit round 5. Attempt 2 approved at round 4.

## Answer

Yes. With Bold Text on, every interface font steps one weight up in the app and the widget: Regular to Medium, Medium to Bold. Bold stays Bold because it is the heaviest bundled Zen Kaku Gothic New file. The big kanji fonts do not change. Text in the system font already follows Bold Text through iOS.

## Decisions

Each entry gives the question, the options, the choice, and who made it.

1. **Where the setting is read.** The options were to pass `legibilityWeight` into every token call, or to keep the static tokens and have them read a shared `@Observable` store. The implementer chose the store (`BoldTextStore`). It copies the `KanjiFontStyleStore` pattern from the font style build, so no view signature changes, and Observation re-renders any view whose body reads a token.
2. **How weights step.** `InterfaceFace.steppedUp` maps Regular to Medium, Medium to Bold and Bold to Bold, and `resolved(boldText:)` applies it. Every interface token (`nichijiTitle` through `nichijiCaption`, `uiText`, and the typed search text `nichijiTypedBody`) goes through one function, `Font.interface`. The implementer made this choice, following the ticket's "Bold stays Bold".
3. **Feeding the store in the app.** `NichijiApp.init` seeds the store from `UIAccessibility.isBoldTextEnabled` before the first frame. `honoursBoldText()` at the app root then follows `legibilityWeight` through `onChange(initial: true)`. The implementer made this choice.
4. **Feeding the store in the widget.** The options were `onChange` or `onAppear` as in the app, or a write inside the modifier's body. The implementer chose the body write in a separate modifier, `honoursBoldTextInWidget()`, because a widget renders each entry as a snapshot, so the app's `onChange` hook cannot be counted on there. `update` returns early when the value is unchanged, so the write cannot loop.
5. **Redrawing widgets after a change.** The app saves the last Bold Text value it saw in the App Group `UserDefaults` (`boldTextLastSeen`). At launch and on each change, it reloads widget timelines if the value differs. No saved value counts as a change, so the first launch after the update redraws widgets drawn before it. The implementer made this choice.
6. **Test isolation for the shared store.** Every test that writes or compares token faces runs in the serialized `BundledFontsTests` suite and pins the store with `withBoldText`. The implementer made this choice.
7. **Audit council.** The council used the Claude seat only, as three haiku auditors (A, B, C). The Gemini and GPT seats were out of quota. The master's brief set this, not the user directly.
8. **Version.** The CHANGELOG entry is v0.40.0, a minor bump for a new user-facing feature. Untagged. Tagging is the user's call.

## Audit

| Round | A | B | C | Result |
| --- | --- | --- | --- | --- |
| 1 | 7 DISAPPROVE | 7 DISAPPROVE | 7 DISAPPROVE | All three asked whether other widgets miss the modifier |
| 2 | 8 APPROVE | 8 APPROVE | 8 APPROVE | All three asked for evidence of the widget modifier's ordering |
| 3 | 8 APPROVE | 8 APPROVE | 8 APPROVE | Seat C flagged an overstated CHANGELOG sentence |
| 4 | 8 APPROVE | 8 APPROVE | 9 APPROVE | Gate open |

Problems fixed or rebutted:

- Widget coverage (blocking, all seats, round 1). Rebutted. `NichijiWidgetBundle.swift:9-11` lists only `DailyKanjiWidget`, which serves all five families (`DailyKanjiWidget.swift:20`). Its entry view draws every family and the locked view under the root that carries the modifier.
- Widget ordering had no evidence (minor, all seats, round 2). Fixed. The new test `widgetModifierSetsStoreFirst` renders a probe view under the widget modifier with `legibilityWeight` set to `.bold` through `ImageRenderer`. It expects the probe's first body run to see the store already on. The modifier comment now makes only that narrower claim.
- No "nothing built or run" note (minor, B and C). Fixed in PROGRESS and the CHANGELOG.
- PROGRESS said the reload was unit tested (minor, A). Fixed. The row now names the tested parts (`changed`, `recordSeen`) and says the reload call itself has no test.
- The CHANGELOG made a toggle while the app was closed sound instant (minor, C). Fixed. The widget picks it up at its next timeline render, or at the next app launch if that comes first.
- The typed search font goes stale (minor, A). Rebutted. Its only caller, `DictionarySearchBar.swift:20`, reads it inside a SwiftUI body, so Observation tracks it.
- `.serialized` does not cover other suites (minor, B). Rebutted. The only other suite that touches tokens, `DesignTokensTests.swift:32-38`, reads them and asserts nothing about the face.
- The store is written with no isolation guard (minor, B). Rebutted. Every writer runs on the main actor: `App.init`, `ViewModifier.body`, and `onChange`.

Minor problems declined:

- The test-host font assertions assume the faces register (A). The same suite's "Every design-token face is registered" test already asserts this.
- `changedFromLastSeen` is a tautology (C). The test pins the rule that a missing saved value counts as a change.
- The ordering test reads the store, not the resolved face (B). `interfaceTokensWithBoldText` covers the step from store to face.

One limit stayed open. The `ImageRenderer` test does not run WidgetKit. Seats A and B raised it, and both called it disclosed by the device-check notes.

## Unverified until a device check

This Linux host has no Swift toolchain. Nothing was compiled, built or run, and the new tests have not run. Master CI is the first compile. These points need an iPhone or a simulator:

- WidgetKit passes `legibilityWeight` to widget views.
- The widget redraws with the stepped-up face after a timeline reload.
- `Font.custom(_:size:relativeTo:)` with the Medium and Bold faces scales with Dynamic Type while Bold Text is on.
- The app re-renders open screens when Bold Text changes while the app is in the foreground.
