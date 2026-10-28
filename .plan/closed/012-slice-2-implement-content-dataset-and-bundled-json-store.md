---
id: "012"
title: "Implement Slice 2: Content Dataset & Bundled JSON Store"
type: task
mode: AFK
status: closed
blocked_by: ["011"]
claimed: false
---

## Question

Implement Slice 2 on feature branch `feat/slice-2-content-dataset-and-bundled-json-store`: implement `BundledKanjiContentStore` with caching, seed verified offline kanji records and index, update `TestKanjiContentStore`, write comprehensive tests in `KanjiContentStoreTests.swift`, and write the Deviation Report.

## Notes

Skills: `domain-modeling`, `apple`, `unslop`.
Source of truth: [Slice 2 Requirements Report](../closed/011-slice-2-content-dataset-and-bundled-json-store-requirements.md).
Follow `docs/workflow.md` slice execution steps.

## Resolution

- Implemented `BundledKanjiContentStore` in `Nichiji/Services/KanjiContentStore.swift` with thread-safe `NSLock` caching, bundle lookup, and embedded `SeedKanjiDataset` for core N5 and Grade 1 kanji (`日`, `一`, `二`, `三`, `山`, `川`, `学`).
- Added `KanjiIndexEntry` summary model to `Nichiji/Models/KanjiContent.swift`.
- Synchronized `TestKanjiContentStore` double in `NichijiTests/TestDoubles/TestKanjiContentStore.swift` with protocol contracts.
- Added comprehensive unit tests in `NichijiTests/Suites/KanjiContentStoreTests.swift` covering lookups, JLPT/Joyo filtering, SVG stroke paths, and error scenarios.
- Updated `docs/PROGRESS.md` marking Slice 2 `done`, recorded logs in `docs/IMPLOG.md`, and bumped version to `v0.0.8` in `docs/CHANGELOG.md`.
