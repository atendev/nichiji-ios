---
id: "037"
title: Build the dataset generator and pin its first output
type: task
mode: AFK
status: open
blocked_by: ["036"]
claimed: false
---

## Question

Does a repeatable generator turn pinned KANJIDIC2, JMdict, KanjiVG and N-level inputs into the bundle the app expects?

## Notes

Skills: `tdd`, `unslop`.
Follow the decisions in "Settle the bundled dataset scope and schema" and the format in [Verified kanji and stroke dataset sources](../closed/002-verified-kanji-dataset-sources.md): `kanji-index.json`, `kanji/<hex>.json`, `stroke-order/<hex>.svg`, and a generated `DATA-SOURCES.md` with versions, URLs, SHA-256 and licenses.
The generator lives outside the app targets. Add a `make dataset` target. Downloading upstream files is network access outside the app; if the generator needs it, record the exact URLs and checksums so the run is reproducible.
Tests cover the parsers and the join on small fixture files, not the full upstream dumps.
Minor bump. Runtime loading is the next ticket.

## Resolution

