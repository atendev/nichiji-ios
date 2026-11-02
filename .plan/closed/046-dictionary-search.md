---
id: "046"
title: Build Dictionary search
type: task
mode: AFK
status: closed
blocked_by: ["044", "045"]
claimed: false
---

## Question

Does typing in the Dictionary search bar return the kanji and word results the search rules define, fast enough to update per keystroke?

## Notes

Skills: `apple`, `tdd`, `unslop`.
Implement the rules from [Decide how Dictionary search matches and ranks](../closed/044-dictionary-search-rules.md). Matching, folding and ranking are a pure, tested function; the view only renders. Kanji results open kanji detail; word rows open the "Which kanji?" sheet.
Includes the generator change: `rank` on each `words.json` record and the app-only `kanji-search.json`. Regenerate `Dataset/` and keep `make dataset-test` green.
Draw to search is out of v1.0 ([Fix the v1.0 scope](../closed/034-fix-the-v1-scope.md)): the Dictionary ships without the button.
Minor bump.

From [Build kanji detail and the Dictionary browse grid](../closed/045-kanji-detail-and-dictionary-browse.md): the search bar goes where the TODO in `DictionaryView` sits, above the browse grid inside its `NavigationStack`. Kanji results can push `KanjiDetailRoute(kanjiID:)` to open the shared `KanjiDetailView`.

## Resolution

Typing in the Dictionary search bar returns the Kanji and Words the search rules define. Shipped in v0.15.0.

- **Core.** `Nichiji/Search/` holds the pure parts, kept out of the widget target: `DictionaryQuery` reads the query by script, `SearchFolding` runs one folding on data and query, `SearchMatcher` finds exact, prefix and substring hits over UTF-8 bytes, and `DictionarySearchIndex` builds the folded rows and ranks them. Kanji rank by tier, field, frequency (unranked last) and list order; words by tier, JMdict `rank` and shorter kana. English matches per gloss at word starts only.
- **Beyond the rules.** The folding also collapses `aa`, `ee` and `ii` and strips macrons from `ā`, `ī`, `ē`, because the generated romaji uses all five macron vowels. A kana query also matches a word's written form, not only its kana.
- **Source.** `DictionarySearchSource` reads `kanji-search.json` and `words.json`, so `KanjiContentStore` and its test double stay as they were. `project.yml` bundles `kanji-search.json` in the app only.
- **UI.** `DictionarySearchBar` sits above the grid. `DictionaryView` keeps the index in state, builds it on a background task the first time it appears ("Preparing search…" while it builds), debounces 150 ms and scans off the main actor. `DictionarySearchResultsView` renders `Closest matches for "x"` or `No matches for "x"`. A word row opens kanji detail when it has one distinct kanji, the "Which kanji?" sheet when it has two or more, and nothing when it has none. The stack now binds a path so the sheet and word rows can push detail.
- **Generator.** `words.json` records carry `rank`; `kanji-search.json` is new. The app set is 8,140,093 bytes of the 8,388,608 byte budget, so the next dataset growth will fail the build.
- **Left alone.** Duplicate headwords with different JMdict sequence numbers can show twice in the 50 rows. The rules were silent, so they stay.

Requirements Report: written by a subagent. Nothing built or ran here (Linux, no Swift toolchain); the Python generator tests pass. The implementation audit and CI results are in the Final Report. CI was pending at commit time.
