---
id: "051"
title: Build the lock-screen widgets
type: task
mode: AFK
status: open
blocked_by: ["038", "050"]
claimed: false
---

## Question

Do the chosen accessory widgets render every state on the lock screen and refresh on the same triggers as the home-screen widgets?

## Notes

Skills: `apple`, `tdd`, `unslop`.
Reuse `DailyKanjiTimeline` and `WidgetRefresher`. Use `widgetRenderingMode` / `widgetAccentable` for the vibrant lock-screen style. Replace the Settings guide placeholder and both TODOs. Extend `WidgetTimelineTests`.
Minor bump.

## Resolution

