# Design

Living document. Updated in Phase 0 and whenever the design changes.

Status: **v0.6.0 shipped (Onboarding, Today, Settings, reminders, widgets). v1.0 work is planned in `.plan/map.md`.**

---

## Purpose

Nichiji is a local-first iOS app for learning kanji. It gives the learner one
kanji each day, with readings, meanings, example words, stroke information and
optional review. The app uses a quiet, book-like interface built around the
kanji rather than gamification.

The app does not require an account and does not collect analytics or personal
data. The one exception under review is ML Kit, which handwriting search uses on
device: it downloads its Japanese model and makes a logging contact with Google.
"Find what ML Kit sends to Google" decides what that means for the privacy label
and the in-app privacy copy before release. The initial implementation targets onboarding and the Today tab.

## Feature overview

The first implementation includes:

- Eight-screen onboarding: welcome, daily kanji, flashcards, level selection,
  an optional step for kanji the learner already knows, reminder, widget
  introduction and ready.
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
components, and six `Sendable` service protocols (`KanjiContentStore`,
`LearnerStore`, `DailyKanjiService`, `PronunciationService`,
`ReminderScheduler` and `ReviewService`) plus an injected `DayProvider` passed through a
`ServiceContainer` in the SwiftUI environment. Handwriting search adds one more
seam outside that set: `OnDeviceHandwritingModel`, a `@MainActor` protocol in
`Nichiji/Handwriting/` that ML Kit implements on device. `HandwritingSearchModel`
gets it from `OnDeviceHandwritingModelFactory`, not from the `ServiceContainer`,
and the widget target compiles none of it. The first pass implements
onboarding and Today without locking future Dictionary, Review or You screens
out of the navigation model.

Kanji content is bundled with the app from a version-pinned build-time dataset
generated from EDRDG KANJIDIC2 (CC BY-SA 4.0), EDRDG JMdict (CC BY-SA 4.0) and
KanjiVG (CC BY-SA 3.0), with upstream attribution and license metadata included
for the in-app Sources screen. Both the main app and widget extension bundle
`kanji-index.json` and per-character JSON records so either process can perform
daily rollover offline, while stroke-order SVGs are bundled only in the main
app and loaded lazily on demand. Runtime network access is not part of the
design, with one exception: on device, ML Kit downloads its handwriting model
(about 20 MB) the first time a Pro learner opens handwriting search. The dataset is version-pinned per release and regenerated from
upstream at each release; there is no automated update process.

Dictionary opens on a browse grid of every bundled kanji, grouped by the
active level system: N5 to N1 for JLPT, or grade 1 to Secondary then a "Name
kanji" group for the jinmeiyō kanji with no Jōyō grade. The grid reads only
`kanji-index.json`. A tile pushes the shared kanji detail screen (hero,
Details, Example words, Stroke order with "Practice this kanji"). Detail and
Today end with a quiet Forget it control for kanji past `new`; it confirms,
resets the kanji through `ReviewService` and rebuilds reminders.

Dictionary search covers every bundled kanji and word, whatever the study
pool. The query's script picks what it searches: kanji search literals and
words containing them, kana search readings, and Latin searches romaji and
English meanings together. Romaji is folded on both sides (macrons and doubled
vowels collapse, common spelling pairs fold) and matches as exact, prefix or
substring; English matches only at word starts. Results come in a Kanji
section and a Words section, ranked by match quality, then frequency. A word
row opens a small "Which kanji?" sheet. The search index is built in memory
the first time Dictionary opens, from the app-only `words.json` and
`kanji-search.json`.

A full-width "Draw a kanji to search" button sits under the search bar. It
needs Pro; locked, it opens the paywall. The "Draw to search" sheet has a pad,
five matches refreshed after each finished stroke, Undo and Clear, and a match
tap puts that kanji in the search bar. On device, ML Kit Digital Ink (`ja`)
recognizes the drawing once its model has downloaded. The download starts the
first time a Pro learner opens the sheet, and a failed download is requested
again on the next open. Until then, and always in the Simulator and in tests, a
KanjiVG template matcher answers: it builds templates at runtime from the
bundled stroke SVGs and compares strokes in any order. ML Kit output is kept
only for single kanji the app ships, and an ML Kit error or an empty filtered
result falls back to the matcher. ML Kit comes through CocoaPods and is linked
and compiled for devices only, because its pods have no arm64 Simulator slice.

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
requests, never more than one a day. The next upcoming request uses specific
copy. If the reminder time is still ahead today and today's kanji is unlearned,
it is kanji-led (`"日 · Today's kanji is ready"`). If today is already learned,
today is skipped. If the next fire is tomorrow, it uses missed-day copy
(`"You missed yesterday's kanji. That's okay, check it now."`) when today is
still `.assigned`. When today is learned, it uses review-due copy
(`"3 kanji due for review"`) if kanji are due on that day, and generic copy
otherwise. The remaining
requests use generic copy (`"Today's kanji is ready"`). With no assignment
(level complete) nothing is scheduled.
The window is rebuilt on launch, on foreground, after "Got it" from the app or
widget, and after any reminder, level, pool or time-zone change. When
notification permission is denied, the app preserves the reminder toggle state,
shows an inline "notifications are off" row linking to system Settings, and
cancels nothing silently. When `NSSystemTimeZoneDidChange` or
`significantTimeChange` fires, the app reruns rollover, rebuilds the 7-day
notification window and reloads widget timelines.

Widgets use WidgetKit and support `systemSmall` (kanji and primary meaning) and
`systemMedium` (kanji, meaning, readings and a featured word) in the first
pass. Only the medium widget has the interactive "Got it" button, shown while
today's assignment is `.assigned`. Widget timelines emit a single entry refreshed `.after(nextMidnight)`
and reload explicitly after "Got it" or any level, pool, order or time-zone
change. Before onboarding finishes the widget asks the learner to open the app,
and a finished level shows a quiet placeholder. Tapping the widget outside
the Got it button opens the app on Today (`nichiji://today`) and closes the
Settings sheet. Lock-screen widgets ship in all three accessory families: the
circular family shows the kanji glyph (with a small checkmark once learned),
the rectangular family adds the primary meaning and featured word, and the
inline family shows one line of kanji and meaning. All are read-only; a tap
opens Today. They need Pro. Without it each family shows a locked placeholder
("Nichiji Pro", "Tap to unlock"), and a tap opens `nichiji://pro`, which closes
Settings and shows the paywall over Today. The home-screen widgets stay free. Audio uses `AVSpeechSynthesizer` on `@MainActor` with `ja-JP`, speaking
kana readings when available and disabling speaker buttons with a footnote when
no Japanese voice is installed.

Pro is a one-time "Nichiji Pro" non-consumable bought through StoreKit 2, with
no server and no third-party purchase SDK. ML Kit, for handwriting search, is
the app's one third-party SDK. It unlocks lock-screen widgets, CSV export,
photo lookup and handwriting search (`ProFeature`); everything else is free.
`StoreKitPurchaseService` reads the device's entitlements, accepting only
verified, unrevoked transactions, purchased or family shared. It caches the
result in App Group `UserDefaults`, so gating works offline and the widget
extension reads the same value. `ProAccessModel` restores on every launch,
follows transaction updates and reloads widget timelines when access changes.
A Debug-only dev unlock sits on its own key.

The paywall is a sheet that opens only when a locked Pro feature is tapped: a
locked lock-screen widget, History's "Export history", the widget guide's
"Unlock lock screen widgets" button, and later the photo and handwriting entry
points. It never appears on Today, during onboarding, on a timer or when
Settings opens. It names the tapped feature first, lists all four, says the
rest of the app stays free, and offers "Unlock for <price>" with the StoreKit
price, "Restore purchases" and a Family Sharing note. Pending (Ask to Buy), an
unavailable product, an unverified transaction and other failures each get a
one-line note; a cancelled purchase shows nothing. The sheet closes once Pro
unlocks. Settings has a Nichiji Pro section with the status, "Restore
purchases" and, in Debug builds only, a "Developer unlock" toggle. It shows
status only and never opens the paywall.

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
  `learning`, `familiar`, `known`), review timestamps and answer counts. A kanji
  the learner marked as already known is stage `known` with a `declaredKnownAt`
  date, no review date and no log row, and counts apart from Learned.
  `wasHandKnown` is false only on a mark the app made: a level pick marks every
  new kanji in the easier levels, and the next pick removes those automatic marks
  outside its own easier levels. Hand marks stay.
- `CustomKanjiSelection` and `StudyLogEntry`: SwiftData records for custom
  study-pool picks and day-by-day study activity.
- `ProAccess`: the `Sendable` Pro state (purchased, Debug dev unlock) cached in
  shared `UserDefaults` and checked per `ProFeature`.

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
marks the kanji as learned. "Practice this kanji" at the bottom of the stroke
card opens the Practice sheet: a tracing pad over a faint guide kanji, with
Undo, Clear and a stroke counter, and the stroke order grid at the full
detent. The pad records strokes and gives no handwriting feedback.

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
- The app must not require authentication, analytics, or a backend. ML Kit's
  model download and its Google logging are the one exception, pending "Find
  what ML Kit sends to Google".
- Dynamic Type and accessibility labels are required for interface controls.
- The app must respect the system Reduce Motion setting.
- The generated Xcode project remains uncommitted and is created with
  XcodeGen.

## Non-goals

Version 1.0 ships the single-column phone layout and does not include
stroke-order checking on the Practice pad (the pad records strokes only),
configurable widgets, a daily review cap, a furigana toggle, account sync or
backend services. It does not implement the iPhone Duo or iPad two-pane
layout, but the architecture must leave room for it.

## Open questions

_None at this stage. Dataset sources, widget families and refresh policy, and
notification permission / time-zone behavior are resolved in `.plan/closed/002`
and `.plan/closed/003`._
