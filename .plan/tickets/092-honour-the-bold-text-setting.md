---
id: "092"
title: Honour the iPhone's Bold Text setting
type: task
mode: AFK
status: open
blocked_by: ["091"]
claimed: true
---

## Question

When the iPhone's Bold Text accessibility setting is on, can every interface font step one weight up (Regular to Medium, Medium to Bold), in the app and in the widgets?

## Notes

Skills: `apple`, `tdd`, `unslop`.
From [Decide the font style setting](../closed/090-decide-the-font-style-setting.md): deferred out of the font style build. Custom fonts ignore Bold Text today. Read the `legibilityWeight` environment value (widgets get it too) at the token layer built in [Build the font style setting and heavier English text](091-build-the-font-style-setting.md). Bold is the top bundled weight, so Bold stays Bold. Not a v1.0 blocker unless the release review says otherwise.
Output: the change, tests for the step-up, a green CI run.

## Resolution

<Filled in at close: the decision and the reason for it.>

## Handoff

Branch `t3/honour-bold-text-setting`, SHA in the commit after this section's parent: see `git log -2`. Attempt 2 of the master's escalation. Audit rounds used in attempt 2: 0 of 5 (attempt 1 stopped at round 5).

Done in attempt 2:
- `BoldTextStore` gained `lastSeenKey`, `recordSeen(in:)` and the pure `changed(from:to:)`. `NichijiApp.init` seeds the store from `UIAccessibility.isBoldTextEnabled`, then `reloadWidgetsIfBoldTextChanged()` reloads widget timelines when the value differs from the saved one. The app's `honoursBoldText { }` calls the same function on every `legibilityWeight` change.
- The modifier is split: `honoursBoldText(didUpdate:)` for the app (onChange only), `honoursBoldTextInWidget()` for the widget (sets the store in body, with a comment saying why).
- Tests: `withBoldText` helper pins the shared store in every face test, plus new `changedFromLastSeen` and `recordSeen` tests. CHANGELOG v0.40.0 and PROGRESS rewritten.

Left, in order:
1. Swift 6 concurrency re-read of the new lines (done once in my head: no issues found; confirm).
2. Council audit, Claude seat only, three Claude auditors on haiku, up to 5 rounds. Problems from attempt 1 that may come back: target membership (rebut with project.yml lines 92-97), "every interface font" (grep for ZenKakuGothicNew/InterfaceFace outside Tokens is empty; system fonts get Bold Text from iOS), `.serialized` suite (BundledFontsTests.swift:10).
3. Decision report at `.plan/assets/092-honour-the-bold-text-setting-report.md`, unslop it, resolution, Timing close, move ticket to `.plan/closed/`, push, PR against `wayfinder/nichiji-v1-master`.

Unverified until a device: no Swift toolchain here, nothing built or run. WidgetKit passing `legibilityWeight`, widget re-render after reload, `UIFontMetrics` keeping the face name.

Files to read first: `Nichiji/Models/BoldTextStore.swift`, `Nichiji/DesignSystem/Tokens/JapaneseTypesetting.swift`, `Nichiji/NichijiApp.swift` (init and `reloadWidgetsIfBoldTextChanged`), `NichijiTests/Suites/BundledFontsTests.swift`.
