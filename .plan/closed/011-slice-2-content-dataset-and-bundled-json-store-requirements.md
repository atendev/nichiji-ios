---
id: "011"
title: "Slice 2 Requirements Report: Content Dataset & Bundled JSON Store"
type: grilling
mode: HITL
status: closed
blocked_by: ["010"]
claimed: false
---

## Question

What are the Success Criteria, Scope Boundary, Anticipated TODOs, and Planned Tests for Slice 2 (Content Dataset & Bundled JSON Store) before creating the feature branch?

## Notes

Skills: `domain-modeling`, `apple`, `unslop`.
Reference files: `docs/workflow.md`, `docs/PROGRESS.md`, `docs/IMPLEMENTATION.md`, `Nichiji/Services/KanjiContentStore.swift`.

## Resolution

- **Slice Name**: `slice-2-content-dataset-and-bundled-json-store`.
- **Success Criteria**:
  1. `BundledKanjiContentStore` conforming to `KanjiContentStore` with thread-safe in-memory caching.
  2. Bundled seed dataset with complete `KanjiEntry` models (meanings, readings, radical, stroke paths, example words).
  3. Stable retrieval by ID and filtering by JLPT level and Joyo grade in canonical list order.
  4. Proper error mapping using `NichijiError.contentMissing` and `NichijiError.contentCorrupted`.
  5. Comprehensive Swift Testing suite covering lookups, filtering, stroke paths, and error scenarios.
- **Approved**: User approved Requirements Report on trunk; proceeding to feature branch implementation.
