---
id: "041"
title: Build the Review settings screen
type: task
mode: AFK
status: closed
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

Yes. The LEARNING group in Settings has a Review row between Daily reminder and Show romaji, replacing the TODO. Its subtitle is "Card types, order, audio." and its value is the live summary (`10 cards · Due first`, or `All due · <order>`). The row pushes `ReviewSettingsView` with the mock's four sections:

- Card types: multi-select. The last one on cannot be turned off.
- Order: four single-select cards.
- Session: 5 / 10 / 20 / All due chips, plus the example word and repeat forgotten toggles.
- Audio: the autoplay toggle and the Reading / Reading and word chips.

The screen holds a `ReviewPreferencesSnapshot` loaded from shared `UserDefaults` and saves it on every change. `ReviewService.startSession(preferences:)` takes the same snapshot. Option cards and chips use `selectableCard`. The toggle rows, section headers and dividers reuse the Settings helpers, and chips stack vertically at accessibility text sizes. The defaults come from the scheduling decision.

`SettingsPreferencesTests` covers the full round trip, the summary, the chip labels, the last-card-type rule through save and load, and a saved order and size driving `ReviewScheduler.dueQueue`.

The engine reads only order and session size today. The other fields get their first reader in "Build the Review tab and session", whose Notes now say so. v0.9.0. CI is pending; see the Final Report.

