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

Skills: `tdd`, `unslop`. Surfaced by [Measure widget memory and the search index on a device](../closed/088-measure-widget-memory-and-search-index-on-a-device.md): peak 35.5 MB, last run 26.1 MB, on a device with the 6,407-kanji bundle. The widget reads index entries and decodes one record; the ticket 087 fallback is to read only the records it needs. Find the spike first (fonts, index load, record decode), then cut it. Re-measure with the memory probe (on `main`, gated to `DEBUG || DEV_UNLOCK`; Settings > MEASURE in a TestFlight Internal build) and record the new peak. When this ticket closes, remove the probe: follow the REMOVE note in `Nichiji/Widget/WidgetMemoryProbe.swift` (`grep -rn MEASURE-PROBE Nichiji NichijiWidget`). Also informs [Decide whether the Shared size budget counts fonts](../closed/094-decide-whether-the-shared-size-budget-counts-fonts.md).

## Progress

Open, waiting on an overnight device reading. Three on-device readings with the 088 probe (resident size, sampled once at the end of a run): peak 35.5 MB, then 39.9 MB over 333 runs across five days, last run 24.5 MB. The widget sits near 25 MB and only sometimes jumps 10 to 15 MB.

Working theory, not yet confirmed: the first widget run after midnight finds no assignment for the day, so it opens the shared store and decodes the whole 948 KB index (6,407 records) through `DefaultDailyKanjiService.activePool`. Every later run finds the assignment and skips the index. The learner has the small, medium and lock-screen widgets placed, so several timeline requests may hit that run at once, each with its own `ModelContainer` and its own index decode.

The probe now records `phys_footprint` after each stage (`environment`, `rollover`, `assignment-lookup`, `progress-ids`, `index`, `pool`, `assignment`, `record`), the true in-run peak from a 2 ms sampler, and how many runs overlapped. It is in the TestFlight Internal build from CI run 45500054963 (Settings > MEASURE, "Peak run" and "Last run" lines). Next: read that trace, then pick from serializing the day's assignment creation behind one in-process gate, sharing one `ModelContainer` per widget process, or slimming the index read. No fix is written yet. Remove the probe when this closes (see the REMOVE note in `WidgetMemoryProbe.swift`).

Reading with the stage probe (2026-11-26, Settings > MEASURE, 123 runs): resident peak 35.6 MB, last 32.6 MB. Peak run: in-run peak 11.7 MB at `start`, 1 overlapping, stages flat from 11.6 to 11.7 MB (`start`, `environment`, `rollover`, `assignment-lookup`, `assignment`, `record`, `end`). Last run: peak 8.2 MB at `start`, flat at 8.2 MB, 1 overlapping. Neither run reached `progress-ids`, `index` or `pool`, so neither decoded the index.

What it shows: the stage numbers (`phys_footprint`) stay near 12 MB, far below the 35.6 MB resident reading, so the two metrics disagree by about 24 MB and the in-run peak never moves. The peak run already sat at 11.6 MB before any stage ran, so the cost is in process startup (frameworks, fonts), not in the stages. The reading was taken after midnight, yet the peak run did not decode the index (no `progress-ids`, `index` or `pool` stage), so the first-run-after-midnight index theory is not supported. Stage growth is about 0.1 MB, so the 24 MB gap between the resident peak and the in-run peak is not coming from the stages. Still open: decide which metric the 30 MB target applies to, and find what the resident reading counts that `phys_footprint` does not.

## Resolution

<Filled in at close: the decision and the reason for it.>
