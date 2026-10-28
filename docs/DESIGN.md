# Design

Living document. Updated in Phase 0 and whenever the design changes.

Status: **Phase 0 approved (updated for Phase 2 service and dataset contracts)**

---

## Purpose

Nichiji is a local-first iOS app for learning kanji. It gives the learner one
kanji each day, with readings, meanings, example words, stroke information and
optional review. The app uses a quiet, book-like interface built around the
kanji rather than gamification.

The app does not require an account and does not collect analytics or personal
data. The initial implementation targets onboarding and the Today tab.

## Feature overview

The first implementation includes:

- Seven-screen onboarding: welcome, daily kanji, flashcards, level selection,
  reminder, widget introduction and ready.
- Today: the daily kanji, readings, meaning, details, example words, stroke
  order and the "Got it" action.
- Local learner settings for level, daily order, reminder time, appearance and
  romaji.
- Daily reminder notifications and the initial widget experience.
- Light, dark and system appearance modes.

The app is planned to grow with four main destinations: Today, Dictionary,
Review and You. Settings is a shared sheet available from the tab screens.
Practice opens as a sheet from a kanji and is not a tab.

The tagline is "One Kanji. One Day. Every Day."

## Architecture

The app uses SwiftUI with feature-oriented views, shared design-system
components, and five `Sendable` service protocols (`KanjiContentStore`,
`LearnerStore`, `DailyKanjiService`, `PronunciationService` and
`ReminderScheduler`) plus an injected `DayProvider` passed through a
`ServiceContainer` in the SwiftUI environment. The first pass implements
onboarding and Today without locking future Dictionary, Review or You screens
out of the navigation model.

Kanji content is bundled with the app from a version-pinned build-time dataset
generated from EDRDG KANJIDIC2 (CC BY-SA 4.0), EDRDG JMdict (CC BY-SA 4.0) and
KanjiVG (CC BY-SA 3.0), with upstream attribution and license metadata included
for the in-app Sources screen. Both the main app and widget extension bundle
`kanji-index.json` and per-character JSON records so either process can perform
daily rollover offline, while stroke-order SVGs are bundled only in the main
app and loaded lazily on demand. Runtime network access is not part of the
design.

A shared App Group (`group.com.aten.nichiji`) backs both SwiftData and
`UserDefaults` so the main app and WidgetKit extension operate on the same
local store. SwiftData stores learner-owned records (`KanjiProgress`,
`DailyAssignment`, `CustomKanjiSelection` and `StudyLogEntry`), with all writes
serialized through a `@ModelActor` `LearnerStore` and views reading via
`@Query`. `AppStorage` and `UserDefaults` store scalar learner preferences
(`hasCompletedOnboarding`, `appearanceMode`, `showsRomaji`,
`streakFreezeEnabled`, `reminderEnabled`, `reminderHour`, `reminderMinute`,
`levelSystem`, `selectedJLPTLevel`, `selectedJoyoGrade`, `dailyOrder` and
`isCustomPoolActive`).

Daily rollover is lazy and idempotent: whichever process asks for today's
assignment first marks any `.assigned` rows strictly before today as `.missed`
(never rewriting `.learned` or `.missed` rows and keeping `KanjiProgress.stage`
at `.new`), then returns or creates today's row from the active `.new` study
pool. When a level's `.new` pool is exhausted, Today shows a quiet "level
complete, pick another level" state rather than cycling automatically.

Reminder scheduling uses a rolling window of up to 7 pending local notification
requests. The next upcoming request uses specific copy: kanji-led (`"学 · Today's
kanji is ready"`) if today's kanji is learned, or missed-day copy (`"You missed
yesterday's kanji. That's okay, check it now."`) if today's assignment is still
`.assigned`. Days 2 through 7 use generic copy (`"Today's kanji is ready"`).
The window is rebuilt on launch, on foreground, after "Got it" from the app or
widget, and after any reminder, level, pool or time-zone change. When
notification permission is denied, the app preserves the reminder toggle state,
shows an inline "notifications are off" row linking to system Settings, and
cancels nothing silently. When `NSSystemTimeZoneDidChange` or
`significantTimeChange` fires, the app reruns rollover, rebuilds the 7-day
notification window and reloads widget timelines.

Widgets use WidgetKit and support `systemSmall` (kanji and primary meaning) and
`systemMedium` (kanji, meaning, readings and a featured word) in the first
pass, each with an interactive "Got it" button while today's assignment is
`.assigned`. Widget timelines emit a single entry refreshed `.after(nextMidnight)`
and reload explicitly after "Got it" or any level, pool, order or time-zone
change. Audio uses `AVSpeechSynthesizer` on `@MainActor` with `ja-JP`, speaking
kana readings when available and disabling speaker buttons with a footnote when
no Japanese voice is installed. Handwriting recognition is deferred.

The data and navigation model leaves room for an iPhone Duo or iPad two-pane
layout. The first pass implements the standard single-column phone layout.

## Data models

The app separates immutable bundled content from mutable learner state:

- `KanjiEntry`: an immutable, `Codable`, `Sendable` record decoded from the app
  bundle and keyed by the single-character kanji literal (`id: String`), with
  readings, meanings, example words, radical, stroke count, SVG stroke paths,
  JLPT level, Joyo grade, frequency rank and canonical list index.
- `LearnerPreferences`: scalar preferences persisted in shared App Group
  `UserDefaults` for level system, selected level, daily order, reminder
  schedule, streak freeze, appearance and romaji visibility.
- `DailyAssignment` and `DailyAssignmentSnapshot`: the SwiftData record (and its
  `Sendable` value projection across actor boundaries) assigning one kanji per
  local calendar day (`yyyy-MM-dd`) with status `assigned`, `learned` or
  `missed`.
- `KanjiProgress`: the SwiftData record tracking a kanji's study stage (`new`,
  `learning`, `familiar`, `known`), review timestamps and answer counts.
- `CustomKanjiSelection` and `StudyLogEntry`: SwiftData records for custom
  study-pool picks and day-by-day study activity.

## UI/UX

The visual source of truth is the exported design system and the UI reference
bundle in `docs/design-system` and `docs/ui-reference`. The reference screens
use sample content, but their layout, copy, navigation and interaction notes
define the intended first-pass experience.

The interface uses sentence case, no emoji and no celebratory effects. Kanji
use Shippori Mincho. Interface text uses Zen Kaku Gothic New. SF Symbols
provide navigation and action icons.

Onboarding leads into Today. Today places the daily kanji first, followed by
readings, the details card, example words and stroke order. The primary action
marks the kanji as learned. Practice and handwriting feedback are not part of
the first implementation.

The settings sheet is shared across tabs in the planned navigation. Its
appearance control is functional from the first implementation. Reminder
settings schedule or cancel the daily notification. The widget introduction
must describe the widget without making the learner create an account.

## Themes

The app supports System, Light and Dark appearance choices. Light uses the
Washi paper palette and dark uses the Sumi night palette from the design
tokens. Screens use semantic color tokens rather than branching on theme.

The design keeps vermilion as the primary accent, matcha for learned and
progress states, and mustard for forgotten states in later review flows. The
first implementation must keep sufficient contrast in both themes and must
respect Reduce Motion.

## Constraints

- Minimum deployment target is iOS 27.0.
- Duo-specific APIs require the iOS 27.1 SDK and must be guarded with
  availability checks.
- The core onboarding and Today experience must work offline.
- Bundled data must be verified and legally redistributable.
- The app must not require authentication, analytics, or a backend.
- Dynamic Type and accessibility labels are required for interface controls.
- The app must respect the system Reduce Motion setting.
- The generated Xcode project remains uncommitted and is created with
  XcodeGen.

## Non-goals

The first implementation does not include Dictionary, Review, You, real
handwriting recognition, stroke-order checking, fuzzy search, account sync or
backend services. It also does not implement the Duo split-pane layout, but
the architecture must leave room for it.

## Open questions

_None at this stage. Dataset sources, widget families and refresh policy, and
notification permission / time-zone behavior are resolved in `.plan/closed/002`
and `.plan/closed/003`._
