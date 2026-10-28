---
id: "001"
title: Phase 1 data model and persistence split
type: grilling
mode: HITL
status: closed
blocked_by: []
claimed: false
---

## Question

How should Nichiji structure its Phase 1 data models across bundled immutable kanji content, SwiftData learner records, AppStorage preferences, daily assignment state, and widget/app-group sharing?

## Notes

Skills: `grilling`, `domain-modeling`, `apple`, `unslop`.
Reference files: `docs/DESIGN.md`, `docs/IMPLEMENTATION.md`, `docs/ui-reference/design-notes.md`.

## Resolution

- **Bundled content (`KanjiEntry`)**: Stored outside SwiftData as immutable `Codable`, `Sendable` value types decoded from the app bundle and keyed by the single-character kanji literal (`id: String`). Includes `meanings`, `onyomi`, `kunyomi`, `radical`, `strokeCount`, `strokePaths`, `jlptLevel`, `joyoGrade`, `frequencyRank`, `listIndex`, and `exampleWords`.
- **Persistence split**:
  - Shared App Group `UserDefaults` (`group.com.aten.nichiji`) backs scalar preferences (`hasCompletedOnboarding`, `appearanceMode`, `showsRomaji`, `streakFreezeEnabled`, `reminderEnabled`, `reminderHour`, `reminderMinute`, `levelSystem`, `selectedLevel`, `dailyOrder`).
  - Shared App Group SwiftData `ModelContainer` stores structured learner data:
    - `@Model final class KanjiProgress`: `@Attribute(.unique) var kanjiID: String`, `stageRaw: String` (`StudyStage`: `new`, `learning`, `familiar`, `known`), `firstLearnedAt: Date?`, `lastReviewedAt: Date?`, `nextReviewAt: Date?`, `gotItCount: Int`, `forgotItCount: Int`.
    - `@Model final class DailyAssignment`: `@Attribute(.unique) var calendarDay: String` (`yyyy-MM-dd`), `kanjiID: String`, `statusRaw: String` (`DailyAssignmentStatus`: `assigned`, `learned`, `missed`), `assignedAt: Date`, `completedAt: Date?`.
    - `@Model final class CustomKanjiSelection`: `@Attribute(.unique) var kanjiID: String`, `levelSystemRaw: String` (`jlpt` or `joyo`), `selectedAt: Date`.
    - `@Model final class StudyLogEntry`: `@Attribute(.unique) var id: UUID`, `kanjiID: String`, `actionRaw: String` (`StudyAction`: `learnedDaily`, `gotItReview`, `forgotItReview`, `resetToNew`), `timestamp: Date`, `calendarDay: String`.
- **Daily rollover and missed-day rule**: A kanji only moves out of `stage = .new` into `learning` when the learner marks it "Got it" (or answers a review card). If a day ends with its `DailyAssignment` still `.assigned`, rollover marks that `DailyAssignment` as `.missed` and leaves `KanjiProgress.stage` as `.new` so the kanji returns to the unlearned study pool to appear on Today again. After a missed day, the daily reminder notification uses the copy: `"You missed yesterday's kanji. That's okay, check it now."` If the user switches level or custom pool mid-day before marking today's kanji learned, today's assignment updates immediately from the new pool; if already learned, today's assignment stays unchanged.
- **Widget sharing**: Both the main app and widget extension share the `group.com.aten.nichiji` container so the widget timeline and interactive "Got it" `AppIntent` read and mutate `DailyAssignment` and `KanjiProgress` directly.
