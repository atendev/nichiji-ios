---
id: "032"
title: Open Today from a widget tap
type: task
mode: AFK
status: open
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

