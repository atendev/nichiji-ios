---
id: "095"
title: Bring the widget peak memory under 30 MB
type: task
mode: HITL
status: open
blocked_by: []
claimed: false
---

## Question

What drives the widget's 35.5 MB peak, and what change brings it under about 30 MB?

## Notes

Skills: `tdd`, `unslop`. Surfaced by [Measure widget memory and the search index on a device](../closed/088-measure-widget-memory-and-search-index-on-a-device.md): peak 35.5 MB, last run 26.1 MB, on a device with the 6,407-kanji bundle. The widget reads index entries and decodes one record; the ticket 087 fallback is to read only the records it needs. Find the spike first (fonts, index load, record decode), then cut it. Re-measure with the memory probe (on `main`, gated to `DEBUG || DEV_UNLOCK`; Settings > MEASURE in a TestFlight Internal build) and record the new peak. When this ticket closes, remove the probe: follow the REMOVE note in `Nichiji/Widget/WidgetMemoryProbe.swift` (`grep -rn MEASURE-PROBE Nichiji NichijiWidget`). Also informs [Decide whether the Shared size budget counts fonts](094-decide-whether-the-shared-size-budget-counts-fonts.md).

## Progress

Open, waiting on an overnight device reading. Three on-device readings with the 088 probe (resident size, sampled once at the end of a run): peak 35.5 MB, then 39.9 MB over 333 runs across five days, last run 24.5 MB. The widget sits near 25 MB and only sometimes jumps 10 to 15 MB.

Working theory, not yet confirmed: the first widget run after midnight finds no assignment for the day, so it opens the shared store and decodes the whole 948 KB index (6,407 records) through `DefaultDailyKanjiService.activePool`. Every later run finds the assignment and skips the index. The learner has the small, medium and lock-screen widgets placed, so several timeline requests may hit that run at once, each with its own `ModelContainer` and its own index decode.

The probe now records `phys_footprint` after each stage (`environment`, `rollover`, `assignment-lookup`, `progress-ids`, `index`, `pool`, `assignment`, `record`), the true in-run peak from a 2 ms sampler, and how many runs overlapped. It is in the TestFlight Internal build from CI run 45500054963 (Settings > MEASURE, "Peak run" and "Last run" lines). Next: read that trace, then pick from serializing the day's assignment creation behind one in-process gate, sharing one `ModelContainer` per widget process, or slimming the index read. No fix is written yet. Remove the probe when this closes (see the REMOVE note in `WidgetMemoryProbe.swift`).

## Resolution

<Filled in at close: the decision and the reason for it.>
