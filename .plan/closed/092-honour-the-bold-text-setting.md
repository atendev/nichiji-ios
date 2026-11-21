---
id: "092"
title: Honour the iPhone's Bold Text setting
type: task
mode: AFK
status: closed
blocked_by: ["091"]
claimed: false
---

## Question

When the iPhone's Bold Text accessibility setting is on, can every interface font step one weight up (Regular to Medium, Medium to Bold), in the app and in the widgets?

## Notes

Skills: `apple`, `tdd`, `unslop`.
From [Decide the font style setting](../closed/090-decide-the-font-style-setting.md): deferred out of the font style build. Custom fonts ignore Bold Text today. Read the `legibilityWeight` environment value (widgets get it too) at the token layer built in [Build the font style setting and heavier English text](091-build-the-font-style-setting.md). Bold is the top bundled weight, so Bold stays Bold. Not a v1.0 blocker unless the release review says otherwise.
Output: the change, tests for the step-up, a green CI run.

## Resolution

With Bold Text on, every interface font steps one weight up in the app and the widget: Regular to Medium, Medium to Bold. Bold stays Bold because it is the heaviest bundled file. The tokens read `BoldTextStore`, an `@Observable` store, so views re-render when the setting changes. The app seeds the store from `UIAccessibility.isBoldTextEnabled` at launch and `honoursBoldText()` follows `legibilityWeight`. The widget root's `honoursBoldTextInWidget()` sets the store in its body, before the views inside it read the tokens. The app saves the last value it saw in the App Group `UserDefaults` and reloads widget timelines when the value changes. Typed search text steps from Regular to Medium. The kanji fonts do not change. Version v0.40.0, not tagged.

Nothing was compiled or run on the Linux host, and master CI is the first compile. A device check still has to confirm that WidgetKit passes `legibilityWeight`, that the widget redraws after a reload, and that Dynamic Type scaling holds with the heavier faces. Audit: Claude seat only (Gemini and GPT out of quota), three haiku auditors, round 4 APPROVE 8, 8, 9, three minor problems declined. Attempt 1 stopped at round 5. Report: [decision report](../assets/092-honour-the-bold-text-setting-report.md).

Timing: wall 21m, active 20m, user 0s, wait 0s, blocked 0s | implement 4m, audit 14m (5 rounds), fix 1m, gate 37s | tools 154 (67 subagent) | limits 0, compactions 0, handoffs 1 | ctx peak 158k | cost $1.44 sonnet-5-5 + $4.12 opus-5-5 + $0.26 haiku-5-5
