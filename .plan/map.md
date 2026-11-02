# Map: Nichiji v1.0

## Destination

Nichiji v1.0: every tab and sheet in `docs/ui-reference` runs on the real bundled KANJIDIC2, JMdict and KanjiVG dataset, release work carries the app to TestFlight, and `DESIGN.md` describes the shipped app. "Fix the v1.0 scope" set the feature boundary.

## Notes

Domain: local-first iOS kanji learning app (Swift 6, SwiftUI, SwiftData, WidgetKit, iOS 27.0). Glossary in `CONTEXT.md`.
Skills to consult: `grilling` and `domain-modeling` for grilling tickets, `apple` for any UI, `tdd` for services, `unslop` for all prose.
Follow `docs/workflow.md` and `AGENTS.md`. Every task ticket is a Phase 5 run: requirements report, implementation, audit, one commit, CI. Grilling tickets need you; the runner stops on them.
The previous map (Phases 0-4 and the 11 MVP slices, v0.6.0) is in `archive/map-v0.6.0-mvp.md`. Its closed tickets stay in `closed/`.

Work runs in this order. Ticket numbers follow it, so the runner's "first frontier ticket" walks the stages in turn.

1. Housekeeping: docs and TODO drift, the widget deep link, the UI test target.
2. Scope and content: fix the v1.0 scope, license a JLPT list, settle the dataset, generate it, load it. The Sources screen follows loading.
3. Review and Practice: scheduling rules, review engine, Review settings, Practice sheet, Review tab and session.
4. Dictionary: search rules, kanji detail and browse, search.
5. You: stats rules, study log and stats service, You tab.
6. Lock-screen widgets: design, then build.
7. Release: App Store metadata, then the signed TestFlight build.

## Decisions so far

- [Decide the streak and stats rules](closed/047-streak-and-stats-rules.md): A study day is any learned kanji or review answer; streaks, the activity grid and the Review tab's This week dots all use it. The freeze forgives one miss per locale week and is recomputed, never stored. Time studying becomes Days studied. Milestones are sticky through lifetime counts. Needs attention ranks forgets (min 1). History and CSV list every log entry. Level-complete gets level figures and a "Start <next level>" button.
- [Build the lock-screen widgets](closed/051-lock-screen-widgets.md): The circular, rectangular and inline accessory families join the daily kanji widget, sharing its provider, midnight timeline and refresh triggers; `AccessoryWidgetCopy` pins the text per state, taps open Today, and the Settings guide previews the three families with lock-screen steps.
- [Build Dictionary search](closed/046-dictionary-search.md): A search bar above the browse grid reads the query by script, folds both sides with one function and ranks Kanji and Words from an in-memory index built on first open; word rows open detail or a "Which kanji?" sheet, `words.json` gains `rank`, and the generator writes `kanji-search.json`. The app set is within 3% of its budget.
- [Build kanji detail and the Dictionary browse grid](closed/045-kanji-detail-and-dictionary-browse.md): Dictionary browses all 2,383 kanji from the index by level system (Jōyō ends with a "Name kanji" group for the 247 jinmeiyō kanji) on a shared `KanjiGridTile`; a tile pushes the shared `KanjiDetailView`; Forget it sits on detail and Today, confirms, resets and rebuilds reminders.
- [Decide how Dictionary search matches and ranks](closed/044-dictionary-search-rules.md): Script picks the mode (kanji, then kana, then Latin as romaji plus English); one Swift folding for romaji; exact, prefix and substring tiers with English at word starts only; Kanji and Words sections ranked by tier, field and frequency, with a new JMdict `rank` on words; word rows open a "Which kanji?" sheet; the generator adds an app-only `kanji-search.json`, and the index builds in memory on first Dictionary open (about 20 MB). Draw to search is hidden.
- [Build the Review tab and session](closed/043-review-tab-and-session.md): The Review tab shows due count, tiles, estimate, stage counts, Coming up and review-day dots; the full-screen session runs a `ReviewDeck` (rotating card types, forgotten cards repeated once) on a shared `SwipeFlashcard` with audio, Practice, an in-session settings button and a summary, and rebuilds reminders when it ends.
- [Build the Practice sheet](closed/042-practice-sheet.md): Today's "Practice this kanji" opens `PracticeSheet` through the shared `practiceSheet(target:)` presenter; a `Canvas` recorder (not PencilKit) over a `PracticePad` value type gives one stroke per drag, Undo, Clear and the counter, with a Guide toggle and the stroke order grid at the large detent.
- [Load the generated dataset in the app and widget](closed/038-load-the-generated-bundle.md): The store reads the index once, decodes records on demand and reads SVGs lazily in the app, throwing `contentMissing` for any missing file; models drop `strokePaths` and the `max*` fields, counts come from a new `count(for:)`, the seed moved to tests, and the Level footer and "(est.)" label are in.
- [Build the dataset generator and pin its first output](closed/037-build-the-dataset-generator.md): `tools/dataset/` (stdlib Python, `make dataset-fetch` / `dataset` / `dataset-test`) builds the committed `Dataset/` offline and deterministically: 2,383 kanji matching every pinned grade and N-level count, stroke-path-only SVGs, 2.2 MB shared and 7.0 MB app; 18,195 common words and 11 kanji with no example differ from the dataset ticket's figures.
- [Settle the bundled dataset scope and schema](closed/036-bundled-dataset-scope-and-schema.md): Ship 2,383 kanji (2,136 Jōyō plus 247 Waller N1 jinmeiyō; 172 estimated levels flagged); `KanjiEntry` drops `strokePaths` and gains `isJLPTLevelEstimated`; up to 3 JMdict examples each plus an app-only 17.7k-word index; stdlib-Python generator in `tools/dataset/` with output committed to `Dataset/`; budgets 3 MB widget and 8 MB app; refresh every release; Jōyō counts verified.
- [Register the nichiji URL scheme](closed/053-register-the-nichiji-url-scheme.md): `project.yml` adds an `info:` block on the Nichiji target (`Config/Nichiji-Info.plist`, `CFBundleURLTypes`) that Xcode merges with the generated keys, so Safari and Shortcuts reach `nichiji://today` through the existing `onOpenURL`; a device check is still due.
- [Build the UI launch smoke test](closed/056-build-the-ui-launch-smoke-test.md): `testLaunchShowsPrimaryAction` waits 15 s for `primaryButton` or Today's "Learned today" seal, and the `Nichiji` scheme now runs `NichijiUITests` under `make test` and CI.
- [Build the Review settings screen](closed/041-review-settings-screen.md): Settings gets a Review row (`10 cards · Due first`) that opens `ReviewSettingsView`, which saves a `ReviewPreferencesSnapshot` to shared `UserDefaults` on every change and keeps one card type on; the engine reads order and size now, and the Review session ticket is the first reader of the rest.
- [Build the review engine](closed/040-review-engine.md): `ReviewService` over a pure Leitner `ReviewScheduler`; sessions log under their start day, Got it from Today or the widget schedules tomorrow's first review, Forget it clears the schedule, review preferences live in shared `UserDefaults`, and reminders gain review-due copy.
- [Decide what the lock-screen widgets show](closed/050-lock-screen-widget-design.md): All three accessory families — circular kanji glyph, rectangular adds meaning and featured word, inline one line — read-only with taps opening Today; the Settings guide gets lock-screen previews and steps.
- [Decide the review scheduling and progress rules](closed/039-review-scheduling-rules.md): Leitner table (learning +1d, familiar +3d, known graduates out of the queue), day-granular due, first answer per session decides, Forget it lives on kanji detail, reminder's specific slot gains "N kanji due for review" copy; widgets stay today-only.
- [Keep or remove the UI test target](closed/035-ui-test-target.md): Keep as a state-independent launch smoke test (assert the shared primary button on any first screen), wired into the scheme so `make test` and CI run it. Graduates "Build the UI launch smoke test".
- [Fix the v1.0 scope](closed/034-fix-the-v1-scope.md): In: release work (metadata, signing, TestFlight), per-release dataset regeneration, the `nichiji` URL scheme, You CSV export. Out: handwriting recognition, stroke-order checking, Duo/two-pane, configurable widgets, the onboarding Custom option, review cap, furigana toggle.
- [Find a licensable JLPT N5-N1 kanji list](closed/033-jlpt-kanji-list-source.md): Use Jonathan Waller's CC BY lists pinned through OpenJLPT commit `0d1d341`, labelled as an unofficial estimate; 172 Jōyō kanji lack a level, and the dataset ticket decides whether OpenJLPT's CC BY-SA supplements fill them.
- [Reconcile docs and stale TODOs with v0.6.0](closed/031-reconcile-docs-and-stale-todos.md): Marked Slices 1-11 `tested`, pointed the `DESIGN.md` status at v0.6.0 and this map, and retargeted stale TODOs to the tickets that replace them.
- [Open Today from a widget tap](closed/032-widget-deep-link-to-today.md): Both widgets open `nichiji://today` through `.widgetURL`; the app selects Today and closes Settings, with no URL scheme registration needed.

## Not yet specified

- Waller's list licence version: the tanos.co.uk page was only reachable through a Wayback copy and states no licence version. Revisit when the Sources screen is built.

## Out of scope

- Accounts, sync, analytics and any backend service (`DESIGN.md` constraints).
- Handwriting recognition for "Draw to search" and stroke-order checking on the Practice pad: both need a stroke-matching core tuned on a corpus of drawn strokes that does not exist — the only unknown-quality item on the map ([Fix the v1.0 scope](closed/034-fix-the-v1-scope.md)). Dictionary ships without the draw button; the pad records only.
- iPhone Duo / iPad two-pane layout and configurable widgets: v1.0 ships the single-column phone layout and today-mirroring widgets; the architecture still leaves room for both ([Fix the v1.0 scope](closed/034-fix-the-v1-scope.md)).
- "Customize your kanji" in onboarding, the daily review cap and the furigana toggle: the Settings Custom path and the existing reminder window cover them ([Fix the v1.0 scope](closed/034-fix-the-v1-scope.md)).

## Frontier

- [Build the study log and stats service](tickets/048-study-log-and-stats-service.md) (task, AFK)
- [Build the Sources screen](tickets/052-sources-screen.md) (task, AFK)
