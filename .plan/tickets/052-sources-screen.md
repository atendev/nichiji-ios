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

From [Settle the bundled dataset scope and schema](../closed/036-bundled-dataset-scope-and-schema.md): the screen lists Waller (CC BY), the OpenJLPT supplement (CC BY-SA 4.0), KANJIDIC2, JMdict and KanjiVG, shows the snapshot dates, and carries the sentence "The JLPT has not published official kanji lists since 2010. Levels follow Jonathan Waller's community lists." Estimated levels get the extra OpenJLPT line from ticket 033, which also names Tatoeba as an upstream of OpenJLPT. The Waller licence-version fog on the map is revisited here. The Level-screen footer links here.

## Resolution

