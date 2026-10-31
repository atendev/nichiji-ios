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
Design per [the closed decision](../closed/050-lock-screen-widget-design.md): all three accessory families with the per-state content table, read-only taps to Today, kanji glyph `widgetAccentable`, everything else vibrant monochrome. Replace the Settings guide placeholder with lock-screen previews of the three families and the adapted step list.
Reuse `DailyKanjiTimeline` and `WidgetRefresher`. Use `widgetRenderingMode` / `widgetAccentable` for the vibrant lock-screen style. Replace the Settings guide placeholder and both TODOs. Extend `WidgetTimelineTests`.
Minor bump.

## Resolution

