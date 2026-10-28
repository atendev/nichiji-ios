---
id: "003"
title: Phase 2 service interfaces and reminder-widget contracts
type: grilling
mode: HITL
status: closed
blocked_by: ["001"]
claimed: false
---

## Question

What are the Phase 2 function signatures and service boundaries for daily kanji selection, audio playback, notification scheduling, widget timeline updates, and learner state mutations?

## Notes

Skills: `grilling`, `domain-modeling`, `apple`, `unslop`.
Reference files: `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`.

## Resolution

- **Services**: five `Sendable` protocols, each with one live implementation, passed through a `ServiceContainer` in the SwiftUI environment. No singletons, so every service can be faked in Phase 4 tests.
  - `KanjiContentStore`: loads bundled `KanjiEntry` values.
  - `LearnerStore`: owns every SwiftData read and write.
  - `DailyKanjiService`: pool resolution, selection, rollover.
  - `PronunciationService`: speech.
  - `ReminderScheduler`: notifications.
  - Widgets are a thin layer over these, not a service.
- **Store isolation**: `LearnerStore` is a `@ModelActor`. The app and the widget extension each build their own `ModelContainer` on the shared App Group store, and every write goes through the actor. Views read with `@Query` and never call `context.save()`.
- **Time**: an injected `DayProvider` (`now`, `calendar`, `calendarDay(for:)`, `nextMidnight(after:)`) is the only source of the current time and the only place `yyyy-MM-dd` is formatted.
- **Daily selection and rollover**: `DailyKanjiService.assignment(for:)` is lazy and idempotent. It marks past `.assigned` rows `.missed`, then returns or creates the day's row. Whichever process asks first does the work. Selection is a pure function of pool, `DailyOrder`, excluded IDs and the day string, with `.random` seeded by the day string so app and widget agree. The pool is the kanji of the current level or custom set at stage `.new`. An empty pool returns `nil`, and Today shows a quiet "level complete, pick another level" state with no automatic cycling.
- **Learner mutations** (all on `LearnerStore`): `markLearned(day:)` (assignment to `.learned`, stage `new` to `learning`, `firstLearnedAt`, a `StudyLogEntry`), `forgetIt(kanjiID:)`, `setCustomSelection(_:levelSystem:)`, `reassignToday(from:)` (swaps an unlearned assignment after a pool change, leaves a learned one alone). Review answer mutations are deferred with Review, and `StudyAction` already covers them so no schema change follows.
- **Audio**: `PronunciationService` is `@MainActor`, wraps `AVSpeechSynthesizer` with `ja-JP`, and exposes `speak(_:reading:)`, `stop()` and observable `isSpeaking`. It speaks the kana string when one exists and falls back to kanji text. It stops when the screen disappears. With no `ja-JP` voice installed, the speaker buttons are disabled with a footnote and no alert.
- **Notifications**: `ReminderScheduler` keeps a rolling window of up to 7 pending requests. The first is specific: kanji-led if today is learned, missed-day copy if today is still `.assigned`. The rest use generic copy ("Today's kanji is ready"). The window is rebuilt on launch, on foreground, after "Got it" from the app or widget, and after any reminder, level or time-zone change. Denied permission keeps the toggle state, shows an inline "notifications are off" row linking to Settings, and cancels nothing silently. A learner who stays away for days gets generic copy, not the exact missed-day line.
- **Widgets**: `systemSmall` (kanji and primary meaning) and `systemMedium` (adds readings and a featured word), each with an interactive "Got it" button while the assignment is `.assigned`. No lock screen or large sizes in the first pass. One timeline entry built from `DailyKanjiWidgetSnapshot`, refreshed `.after(nextMidnight)`, with explicit `reloadTimelines` after "Got it" and any level, pool, order or time-zone change. The widget reads through `DailyKanjiService`, so it does the same lazy rollover as the app.
- **Widget content access**: the generated kanji JSON is added to both the app and extension targets, with stroke SVGs excluded from the extension since they load lazily. A snapshot-only design was rejected because it goes stale when the app hasn't run since midnight.
- **Errors**: services throw a typed `NichijiError` (`storeUnavailable`, `contentMissing(kanjiID)`, `notificationsDenied`, `speechUnavailable`). The app shows one inline retry state for store or content failures, and the widget falls back to a placeholder snapshot. Missing content for an assigned ID is a bug, so it logs and picks the next kanji with no user-facing error.
- **Time zone and clock changes**: the app observes `NSSystemTimeZoneDidChange` and `significantTimeChange`, then reruns rollover, rebuilds the notification window and reloads widget timelines. Rollover only marks days strictly before today `.missed` and never rewrites a `.learned` or `.missed` row.
- **Deliverable**: the Phase 2 write-up (`docs/IMPLEMENTATION.md` signatures and `Nichiji/Services/` stubs with TODO comments) is a separate follow-up step, ticket 004, so the Phase 2 approval loop stays apart from this decision record.

Closes two open questions in `docs/DESIGN.md` (widget sizes and update schedule, notification behavior on denied permission and time-zone changes). `DESIGN.md` is updated in ticket 004.
