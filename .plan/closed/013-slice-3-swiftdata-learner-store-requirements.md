---
id: "013"
title: "Slice 3 Requirements Report: SwiftData Learner Store"
type: grilling
mode: HITL
status: closed
blocked_by: ["012"]
claimed: false
---

## Question

What are the Success Criteria, Scope Boundary, Anticipated TODOs, and Planned Tests for Slice 3 (SwiftData Learner Store) before creating the feature branch?

## Notes

Skills: `domain-modeling`, `apple`, `unslop`.
Reference files: `docs/workflow.md`, `docs/PROGRESS.md`, `docs/IMPLEMENTATION.md`, `Nichiji/Services/LearnerStore.swift`.

## Resolution

- **Slice Name**: `slice-3-swiftdata-learner-store`.
- **Success Criteria**:
  1. `SwiftDataLearnerStore` implementing `LearnerStore` using SwiftData's `@ModelActor` macro for background context writes.
  2. Sendable `DailyAssignmentSnapshot` carrying assignment state across actor boundaries.
  3. Strict adherence to rollover invariants: past unlearned assignments become `.missed` while `KanjiProgress.stage` remains `.new`.
  4. Complete mutation methods: `markLearned`, `forgetIt`, `reassignToday`, `setCustomSelection`.
  5. In-memory SwiftData container unit tests in `LearnerStoreTests.swift`.
- **Approved**: User approved Requirements Report on trunk; proceeding to feature branch implementation.
