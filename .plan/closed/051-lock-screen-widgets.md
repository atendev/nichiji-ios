---
id: "051"
title: Build the lock-screen widgets
type: task
mode: AFK
status: closed
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

The three accessory families render every state and refresh on the home-screen widgets' triggers. Shipped in v0.16.0.

- **Views.** `Nichiji/Widget/AccessoryWidgetViews.swift` holds the circular, rectangular and inline views plus `AccessoryWidgetCopy`, the pure text per state that tests pin. The kanji is `widgetAccentable`; the rest is vibrant monochrome.
- **Registration.** The families join `DailyKanjiWidget`, so they reuse `DailyKanjiProvider`, the midnight timeline and `WidgetRefresher`. The widget-wide `.widgetURL` makes every tap open Today.
- **Settings guide.** The placeholder is now previews of all three families and `AddWidgetCopy.lockScreenSteps`.
- **Not verified.** Nothing built or ran here (Linux, no Swift toolchain), so layout and the vibrant rendering are unchecked until CI and a device. The circular open-app cell shows a plain 日 because the brand seal asset is not in the project and the design system forbids redrawing it.

Requirements Report: written by the main agent. The implementation audit and CI result are in the Final Report; CI was pending at commit time.

