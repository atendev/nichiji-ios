---
id: "052"
title: Build the Sources screen
type: task
mode: AFK
status: open
blocked_by: ["038"]
claimed: false
---

## Question

Can the learner open a Sources screen from Settings that shows the attribution and license text the bundled data requires?

## Notes

Skills: `apple`, `unslop`.
No such screen exists yet. The CC BY-SA licenses on KANJIDIC2, JMdict, KanjiVG and OpenJLPT, and the CC BY license on Jonathan Waller's lists, require attribution reachable from the app (see [Verified kanji and stroke dataset sources](../closed/002-verified-kanji-dataset-sources.md) and [Find a licensable JLPT N5-N1 kanji list](../closed/033-jlpt-kanji-list-source.md)).
Render the generated `DATA-SOURCES.md` bundled by the dataset tickets, with tappable license links. Add the row to the About group in `SettingsSheet`, next to Privacy.
Patch bump. Must ship before any release build.

## Resolution

