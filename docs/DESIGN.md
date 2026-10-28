# Design

Living document. Updated in Phase 0 and whenever the design changes.

Status: **Phase 0 approved**

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

The app uses SwiftUI with feature-oriented views and shared design-system
components. The first pass implements onboarding and Today without locking
future Dictionary, Review or You screens out of the navigation model.

Kanji content is bundled with the app so the core learning flow works without
network access. We will gather verified kanji, reading, meaning, level,
example-word and stroke data before implementation uses those records. Each
source must have a compatible license and a recorded version or release date.
The app may later use an API only if a required dataset cannot be bundled
legally and completely. Runtime network access is not part of the initial
design.

A shared App Group (`group.com.aten.nichiji`) backs both SwiftData and
`UserDefaults` so the main app and WidgetKit extension operate on the same
local store. SwiftData stores learner-owned records (`KanjiProgress`,
`DailyAssignment`, `CustomKanjiSelection` and `StudyLogEntry`). `AppStorage`
and `UserDefaults` store scalar learner preferences (`hasCompletedOnboarding`,
`appearanceMode`, `showsRomaji`, `streakFreezeEnabled`, `reminderEnabled`,
`reminderHour`, `reminderMinute`, `levelSystem`, `selectedLevel` and
`dailyOrder`).

Reminder scheduling uses the system notification framework. When today's kanji
is ready on a normal day, the notification leads with the kanji (`"学 · Today's
kanji is ready"`). If yesterday's assigned kanji was not marked "Got it", the
kanji stays in the `new` unlearned study pool so the learner still gets to see
it on Today later, and the reminder uses the missed-day copy (`"You missed
yesterday's kanji. That's okay, check it now."`). Widgets use WidgetKit and
read and mutate the shared App Group store directly. Audio uses the system
Japanese speech synthesizer. Handwriting recognition is deferred.

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
- `DailyAssignment`: the SwiftData record assigning one kanji per local
  calendar day (`yyyy-MM-dd`) with status `assigned`, `learned` or `missed`.
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

- Which verified, redistributable sources will provide the final kanji,
  readings, meanings, example words and stroke data?
- Which widget sizes and update schedule should the first WidgetKit slice
  support?
- Which daily reminder behavior should apply when notification permission is
  denied or the learner changes time zones?
