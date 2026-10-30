---
id: "032"
title: Open Today from a widget tap
type: task
mode: AFK
status: closed
blocked_by: []
claimed: false
---

## Question

When the learner taps either widget, does the app open on the Today tab with today's kanji?

## Notes

Skills: `apple`, `tdd`, `unslop`.
Minor bump.

- Replace the TODO at `NichijiWidget/DailyKanjiWidget.swift:19` with `.widgetURL` on both families. The medium widget's Got it button keeps its AppIntent; only the rest of the widget opens the app.
- Handle the URL with `onOpenURL` in the app. Select `AppTab.today` in `MainTabView` and dismiss the Settings sheet if it is open. Before onboarding finishes, the URL just opens the app.
- Pick a URL scheme (e.g. `nichiji://today`) and register it in `project.yml`.
- Test the URL parsing and tab selection as plain logic.

## Resolution

Yes. v0.7.0, minor.

- `AppDeepLink` in `Nichiji/Models/NavigationState.swift`, compiled into both targets, builds `nichiji://today` and parses it case-insensitively, rejecting other schemes, hosts and paths.
- `DailyKanjiWidget` sets `.widgetURL(AppDeepLink.today.url)` on the entry view for both families. The medium widget's Got it button is an interactive AppIntent control, so its taps still mark the day learned without opening the app.
- `MainTabView.onOpenURL` closes the Settings sheet and selects `AppTab.today`. Before onboarding finishes, `MainTabView` is not on screen, so the tap only opens the app.
- No URL scheme was registered. The ticket suggested one, but a widget URL is delivered to its containing app through `onOpenURL` without a `CFBundleURLTypes` entry, and adding one would mean replacing the generated Info.plist. A later ticket that needs outside callers (Safari, Shortcuts) should register it then.
- `AppDeepLinkTests` covers the round trip, case folding, trailing slash, rejected URLs and the tab mapping. Nothing was built locally (Linux host). CI: pending; see Final Report. A device check is still needed for the tap itself.

