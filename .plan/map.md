# Map: Nichiji v1.0

## Destination

Nichiji v1.0: every tab and sheet in `docs/ui-reference` runs on the real bundled KANJIDIC2, JMdict and KanjiVG dataset, and `DESIGN.md` describes the shipped app. Ticket "Fix the v1.0 scope" decides which deferred features count.

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

## Decisions so far

- [Find a licensable JLPT N5-N1 kanji list](closed/033-jlpt-kanji-list-source.md): Use Jonathan Waller's CC BY lists pinned through OpenJLPT commit `0d1d341`, labelled as an unofficial estimate; 172 Jōyō kanji lack a level, and the dataset ticket decides whether OpenJLPT's CC BY-SA supplements fill them.
- [Reconcile docs and stale TODOs with v0.6.0](closed/031-reconcile-docs-and-stale-todos.md): Marked Slices 1-11 `tested`, pointed the `DESIGN.md` status at v0.6.0 and this map, and retargeted stale TODOs to the tickets that replace them.

## Not yet specified

- Handwriting recognition for "Draw to search", stroke-order checking on the Practice sheet, the iPhone Duo / iPad two-pane layout, and configurable widgets. Each becomes tickets or moves to Out of scope once "Fix the v1.0 scope" closes.
- Release preparation (privacy manifest, App Store metadata, signing, TestFlight), if the scope ticket puts it in v1.0.
- Whether onboarding's Level step gets a "Customize your kanji" option (an open question in `docs/ui-reference/design-notes.md`).
- The UI test follow-up task, once "Keep or remove the UI test target" closes.
- A review reminder, daily review cap and furigana toggle, listed in the design notes as ideas not built. Revisit after "Decide the review scheduling and progress rules".

## Out of scope

- Accounts, sync, analytics and any backend service (`DESIGN.md` constraints).

## Frontier

- [Open Today from a widget tap](tickets/032-widget-deep-link-to-today.md) (task, AFK)
- [Fix the v1.0 scope](tickets/034-fix-the-v1-scope.md) (grilling, HITL)
- [Keep or remove the UI test target](tickets/035-ui-test-target.md) (grilling, HITL)
- [Decide the review scheduling and progress rules](tickets/039-review-scheduling-rules.md) (grilling, HITL)
- [Decide what the lock-screen widgets show](tickets/050-lock-screen-widget-design.md) (grilling, HITL)
