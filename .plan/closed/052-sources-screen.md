---
id: "052"
title: Build the Sources screen
type: task
mode: AFK
status: closed
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

Yes. Settings > About has a Sources row below Privacy, and the Level screen's JLPT footer is now a 44 pt row that opens the same `SourcesView`. The screen opens with "The JLPT has not published official kanji lists since 2010. Levels follow Jonathan Waller's community lists." It then reads the bundled `DATA-SOURCES.md` through a pure `DataSourcesDocument` parser and `SourcesState` loader. Each attribution is a card of plain text with one 44 pt link row per source or licence, followed by the dated Snapshots list. A missing or unreadable file shows "Sources could not be loaded."

The generator writes the links: EDRDG with CC BY-SA 4.0 and the EDRDG licence, KanjiVG with CC BY-SA 3.0, Waller with CC BY, and OpenJLPT with CC BY-SA 4.0. Waller's CC BY links to https://www.tanos.co.uk/jlpt/sharing/ because the Wayback copy of that page states no licence version. That decision is provisional until a live recheck before release. The Waller line also names the vocabulary lists, the OpenJLPT count (172) comes from the built records, the developer-facing `isJLPTLevelEstimated` sentence is gone, and Snapshots gives ISO dates: KANJIDIC2 2026-10-31, JMdict 2026-10-31, KanjiVG 2026-07-14, Waller and OpenJLPT 2026-10-02. `DATA-SOURCES.md` ships in both targets, as 036 decided.

Version v0.19.0, a minor bump because this adds a screen; the ticket's "patch bump" predates that call. CI: pending; see the Final Report. Not checked on a device or simulator: rendering, tap targets, Dynamic Type, contrast, and the live external links.

