---
id: "088"
title: Measure widget memory and the search index on a device
type: task
mode: HITL
status: open
blocked_by: []
claimed: false
---

## Question

Does the daily widget stay well under about 30 MB of peak memory, and does the Dictionary search index stay near its 20 MB budget, with the 6,407-kanji bundle?

## Notes

Surfaced by [Add the Jinmeiyō and Hyōgai levels to the app](../closed/087-add-the-jinmeiyo-and-hyogai-levels-to-the-app.md). No simulator was available when it was built, so neither number is measured.

- Widget: run the widget on a simulator or device and read its peak memory in Xcode's memory gauge or Instruments. The code reads index entries and decodes one record. If it goes over, the widget reads only the records it needs.
- Search index: `DictionarySearchIndexCostTests` prints `SEARCH-INDEX build: N ms, resident growth: X MB` in the CI log. Copy the figures here, and measure on a device if they look high.
- Record both numbers in the Resolution. Add them to `docs/PROGRESS.md` if it tracks budgets.

## Resolution
