---
id: "050"
title: Decide what the lock-screen widgets show
type: grilling
mode: HITL
status: closed
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

Ship all three accessory families. Content uses the Shippori Mincho kanji glyph as the `widgetAccentable` element; everything else renders vibrant monochrome:

- **Circular**: assigned shows the kanji glyph alone; learned adds a small checkmark; level complete is a quiet checkmark glyph; before onboarding shows the app seal mark.
- **Rectangular**: assigned shows the kanji glyph leading with the primary meaning and a second line of featured word plus kana; learned adds a "Learned" check row; level complete shows "Level complete" with one short line; before onboarding shows "Open Nichiji to start learning".
- **Inline**: assigned shows `学 study, learning`; learned shows `学 learned`; level complete shows `Level complete`; before onboarding shows `Nichiji`.

No interactivity: every state is a full-surface tap that opens Today through the existing `nichiji://today` link. A lock-screen Got-it was rejected — it would let a kanji be marked learned without seeing readings or examples, and the home-screen medium widget already carries that action.

Rendering reuses the existing single-entry midnight timeline and the `today` / `levelComplete` / `openApp` content states unchanged.

The Settings widget guide's lock-screen placeholder (`SettingsSupportViews.swift:188`) becomes a real lock-screen section: rendered previews of all three families using the shared `学` sample and the Add Widget step list adapted to lock-screen steps.

Graduates the requirements for "Build the lock-screen widgets".

