---
id: "014"
title: "Implement Slice 3: SwiftData Learner Store"
type: task
mode: AFK
status: closed
blocked_by: ["013"]
claimed: false
---

## Question

Implement Slice 3 on feature branch `feat/slice-3-swiftdata-learner-store`: make LearnerModels public, implement `SwiftDataLearnerStore` with `@ModelActor`, write comprehensive tests in `LearnerStoreTests.swift` using an in-memory ModelContainer, and write the Deviation Report.

## Notes

Skills: `domain-modeling`, `apple`, `unslop`.
Source of truth: [Slice 3 Requirements Report](../closed/013-slice-3-swiftdata-learner-store-requirements.md).
Follow `docs/workflow.md` slice execution steps.

## Resolution

- Made `LearnerModels` (`KanjiProgress`, `DailyAssignment`, `CustomKanjiSelection`, `StudyLogEntry`, and associated enums) public.
- Implemented `SwiftDataLearnerStore` conforming to `LearnerStore` using `@ModelActor` in `Nichiji/Services/LearnerStore.swift`, projecting `DailyAssignmentSnapshot` across actor boundaries.
- Implemented rollover rule transitioning past unlearned rows to `.missed` while preserving `KanjiProgress.stage` as `.new`.
- Implemented `markLearned`, `forgetIt`, `setCustomSelection`, and `reassignToday`.
- Added comprehensive unit tests in `NichijiTests/Suites/LearnerStoreTests.swift` using in-memory `ModelContainer`.
- Updated `docs/PROGRESS.md` marking Slice 3 `done`, logged reports in `docs/IMPLOG.md`, and bumped version to `v0.0.9` in `docs/CHANGELOG.md`.
