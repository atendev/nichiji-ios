# Decision report: Check the new fonts on a device

Ticket type: task, HITL. Outcome: pass, no fixes.

## Build checked

The TestFlight build from CI run 45536104929 (commit 5520004b, Nov 25). It has the font style work from "Build the font style setting and heavier English text" and the Bold Text work from "Honour the iPhone's Bold Text setting". Since that commit, `main` has removed the widget memory probe and added a size line to `build.py` that never fails the build. Neither change touches fonts or text, so the build matches current `main` for this check. The phone had English as its only language, as the ticket requires.

## How the check ran

The user did every on-phone check. The main thread asked 13 questions in five groups through AskUserQuestion (rows 1-12 and 14 below). Each offered pass, too heavy, too light, broken, or a free-text answer. The main thread checked the size budgets from the repo. No subagent took part except the council seat.

## Decisions

| # | Question | Options | Choice | Made by |
|---|----------|---------|--------|---------|
| 1 | You tab numbers (streak, totals, stats), Bold Text off | pass / too heavy / too light / broken | Pass | User on device |
| 2 | Review tab due count and session count | same | Pass | User on device |
| 3 | Body text (Medium) and headings (Bold) on Today, kanji detail, Settings | same | Pass | User on device |
| 4 | Serif and gothic, switched in Settings, on Today, kanji detail, tiles, Review cards | same | Pass | User on device |
| 5 | Practice guide and stroke diagram in both styles; 直, 骨, 角 match their diagrams | same | Pass | User on device |
| 6 | Onboarding style step after Welcome: both choices preview right and the pick carries into the app | same | Pass | User on device |
| 7 | Home and lock screen widgets follow the chosen style and draw right | same | Pass | User on device |
| 8 | Search field keeps the Zen face in both styles | same | Pass | User on device |
| 9 | Gothic fallback: 每 and 黃 draw in the system Japanese font (Hiragino), and gothic as a whole (also Hiragino) looks acceptable | same | Pass; the user checked 每 and 黃 | User on device |
| 10 | Bold Text on, toggled with the app closed: app text steps one weight up | same | Pass | User on device |
| 11 | Bold Text on: widgets redraw bold on the home screen. Only a device can show this; `WidgetBoldTextModifier` has no unit test. | same | Pass | User on device |
| 12 | Bold Text on with larger Dynamic Type: text scales with the heavier faces and the search field keeps its Zen face | same | Pass | User on device |
| 13 | Size totals within budgets | in / over | In: Shared dataset 5.09 of 8 MiB, app dataset 16.80 of 24 MiB. Fonts add 4.09 MiB (widget 9.18 MiB, app 20.90 MiB), which is reported but not budgeted, per "Decide whether the Shared size budget counts fonts" | Main thread, from the repo |
| 14 | Anything else off with fonts | none / heavy / light / broken | Nothing else | User on device |
| 15 | Fix or record a pass | fix in code / record pass | Record a pass, since no check failed | Main thread |

## Audit

Council audit in single mode (Claude seat on `haiku`), on the run context from the master.

- Round 1: APPROVE, score 8, two minor problems, both fixed. This report claimed the verdict was in the ticket resolution, which it was not, so the verdict now lives here. The question count did not match the table, so the count is now 13, the rows those questions fill are named, and the table marks rows 13 and 15 as the main thread's.
- Round 2: APPROVE, score 8, no problems. No minor problems were declined.

## Gates

- Commit gate: commit with no question to the user, per the master's brief. The master merges.
- CI: skipped per the brief. No code changed, so there is nothing to build.
- The workflow says a HITL ticket stops the run. The master's brief overrode that and made this run the HITL session with the user.
