---
id: "050"
title: Decide what the lock-screen widgets show
type: grilling
mode: HITL
status: open
blocked_by: []
claimed: false
---

## Question

Which accessory widget families does the app ship, and what does each one show in each state?

## Notes

Skills: `grilling`, `apple`, `unslop`.
There is no design reference for these. `DESIGN.md` calls them post-MVP, and `NichijiWidget/NichijiWidgetBundle.swift:8` and `Nichiji/Views/Settings/SettingsSupportViews.swift:188` hold TODOs for them.
Decide per family (`accessoryCircular`, `accessoryRectangular`, `accessoryInline`): content when assigned, learned, level complete and before onboarding; whether any is interactive; and what replaces the Settings placeholder.
Answers become the requirements for "Build the lock-screen widgets".

## Resolution

