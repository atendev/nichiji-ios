# Changelog

## v0.4.1
- Fix onboarding back and forward slides overlapping, flashcard face pop and tilt, Today scroll reset after Control Center, Settings not repainting on theme change, and the Customize kanji grid spacing. Show the system notification prompt on the Reminder step with a status button, add the live notification permission scheduler, and simplify the final step to the logo and "You're all set".

## v0.4.0
- Implement the seven-step onboarding with an `OnboardingFlow` model, interactive flashcard demo, store-backed level rows, reminder permission request, widget preview, completion crossfade, and a replay that reassigns today on level change. Share the level-change and reminder-time controls with Settings.

## v0.3.0
- Implement the Settings sheet: appearance picker, level, order and custom kanji pool selection with Today reassignment, reminder settings with permission warning, widget guide, and privacy screens.

## v0.2.0
- Implement Today tab assignment loading, kanji details, pronunciation actions, stroke-order rendering, learned state, level completion, and retry handling.

## v0.1.0
- Add reusable core design-system components with Apple HIG sizing, accessibility, and motion-aware button feedback.

## v0.0.1 — Build Fix
- Fix test target compilation by aligning `WidgetTimelineTests` with the current `DailyKanjiWidgetSnapshot` schema and replacing the removed `canonicalIndex` sort key with `listIndex` in `TestKanjiContentStore`.

## v0.0.0
- Initial project setup.
