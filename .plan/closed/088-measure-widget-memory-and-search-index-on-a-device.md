---
id: "088"
title: Measure widget memory and the search index on a device
type: task
mode: HITL
status: closed
blocked_by: []
claimed: false
---

## Question

Does the daily widget stay well under about 30 MB of peak memory, and does the Dictionary search index stay near its 20 MB budget, with the 6,407-kanji bundle?

## Notes

Surfaced by [Add the Jinmeiyō and Hyōgai levels to the app](../closed/087-add-the-jinmeiyo-and-hyogai-levels-to-the-app.md). No simulator was available when it was built, so neither number is measured.

- Widget: run the widget on a simulator or device and read its peak memory in Xcode's memory gauge or Instruments. The code reads index entries and decodes one record. If it goes over, the widget reads only the records it needs.
- Search index: `DictionarySearchIndexCostTests` prints `SEARCH-INDEX build: N ms, resident growth: X MB` in the CI log. CI run 44265245188 on a macOS runner reported `SEARCH-INDEX build: 853 ms, resident growth: 0.9 MB, kanji: 6407`. The growth figure looks low against the 20 MB budget, so confirm it on a device.
- Record both numbers in the Resolution. Add them to `docs/PROGRESS.md` if it tracks budgets.

## Resolution

Both numbers are over budget. Measured on a device with the 6,407-kanji bundle through the throwaway probe on `measure/widget-memory` (commit 197448f0):

- Widget: peak 35.5 MB resident, last run 26.1 MB. The peak is about 5.5 MB over the ~30 MB target, so the answer to "well under" is no. The last run sits under it, so the spike happens inside a run, not at rest.
- Search index: build 292 ms, memory +24.1 MB. That is about 4 MB over the 20 MB budget. The CI figure (853 ms, +0.9 MB) understated memory, so do not trust the macOS runner number for this budget. Build time is faster on the device than on CI.
- Caveat: the probe reads `resident_size`, not `phys_footprint`, which is what the system's memory limit counts. Treat both figures as close, not exact.

Follow-ups: [Bring the widget peak memory under 30 MB](../tickets/095-bring-the-widget-peak-memory-under-30-mb.md) and [Decide what to do about the search index memory](../closed/096-decide-what-to-do-about-the-search-index-memory.md). The probe stays on `main` for now, compiled only under `DEBUG || DEV_UNLOCK` (so TestFlight Internal builds have it and App Store Release builds do not). Removal steps are in the header of `Nichiji/Widget/WidgetMemoryProbe.swift`; find every spot with `grep -rn MEASURE-PROBE Nichiji NichijiWidget`.
