---
id: "092"
title: Honour the iPhone's Bold Text setting
type: task
mode: AFK
status: open
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

<Filled in at close: the decision and the reason for it.>
