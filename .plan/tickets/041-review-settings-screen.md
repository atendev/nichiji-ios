---
id: "041"
title: Build the Review settings screen
type: task
mode: AFK
status: open
blocked_by: ["040"]
claimed: false
---

## Question

Can the learner change every review setting from Settings, with the choices persisted and read by the review engine?

## Notes

Skills: `apple`, `unslop`.
Design: screens 30-31 and `docs/ui-reference/source/SettingsReview.dc.html`.
Replace the TODO at `Nichiji/Views/Settings/SettingsSheet.swift:187` with the Review row. Adopt the mock defaults from [the scheduling decision](../closed/039-review-scheduling-rules.md) and keep at least one card type on. Reuse `SelectableCardModifier` and the existing settings row styles.
Extend `SettingsPreferencesTests`. Minor bump.

## Resolution

