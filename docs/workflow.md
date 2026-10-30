# AI Workflow

A phased process for working through a project with an AI collaborator, from
initial braindump to shipped features, with clean version history and
documentation at every step.

The process has two modes. Phases 0–4 are collaborative: the user and agent
work through design, data, interfaces, TODOs, and tests together, and the
user approves each phase. Phase 5 is autonomous: the user hands the agent a
Wayfinder ticket and the agent implements, audits, commits, and sees CI
through using subagents, returning only when something goes very wrong.

---

## Agent Rules

### Always

- Never implement more than the current phase or ticket asks for.
- Do not people please. If there's a concern about an approach — technical
  risk, design inconsistency, something that might cause problems later —
  raise it, even if the user seems confident. State the concern clearly and
  specifically and let the user decide whether to address it or proceed
  anyway. In Phase 5 the concern goes in the final report (or stops the run
  if it hits a stop condition below).
- Report outcomes faithfully. Failing tests, skipped steps, and unverified
  builds are stated plainly, never smoothed over.

### Phases 0–4: human in the loop

- Never proceed to the next phase without explicit confirmation.
- Wait for confirmation before committing or merging.
- Never assume a correction is minor enough to skip a re-review. Always
  re-present after changes.
- All reviews follow the same loop: the agent writes the file(s), the user
  approves, then it's committed. No committing on spec.

### Phase 5: autonomous ticket runs

- The user hands over a ticket. The agent runs it end to end without
  pausing for approval.
- Confirmation gates (the Requirements Report, the Deviation Report, the
  diff review) are handed to subagents, not the user. Each delegated gate is
  named in the final report so the user can review its output.
- Implementation is audited by an independent subagent before every commit.
  The audit gets the diff and the ticket's question, never the
  implementer's own verdict.
- Come back to the user only for a **stop condition**:
  - A command is held by a guard hook (ask the user whether to run it; never
    work around the hold).
  - The run is out of tokens.
  - The ticket is HITL (grilling, prototype, or a task needing the human).
    The agent never stands in for the user.
  - Two audit rounds pass without `APPROVE`.
  - Three CI fix attempts fail.
  - A failure the agent cannot explain after one reasonable attempt.
  - A slice contradicts a decision already closed in the map, so
    `DESIGN.md` cannot simply be updated to match.
  - The next step would force push, rewrite history, merge to `main`, push
    to `main`, delete data outside build/cache directories, or touch
    anything outside the repo. These need explicit permission each time.

### Comment Style

- One or two sentences per comment. More only for real gotchas or
  complicated TODOs.
- Plain English. No doc/section citations, no repeating what the code
  already says.
- TODO/spec comments for unimplemented features are a reference, not
  narration.
- Phase history notes are never inline — they go in `IMPLOG.md`.
- Section separators are block comments, label centered, 80 columns total,
  split evenly with dashes. Example:
  ```
  /*-----test-----*/
  ```

### Commit Style

- Short and sweet. Single-sentence main line beginning with a verb: `add`,
  `remove`, `refactor`, `fix`, `doc`, etc.
- Blank line separating the main line from the description.
- Short description explaining the change. No big prose — still short and
  sweet.
- No co-author clause.

---

## Documentation Set

All files live in `docs/`.

| File | Purpose | Updated |
|---|---|---|
| `DESIGN.md` | Purpose, feature overview, architecture, UI/UX, themes, constraints/non-goals, open questions | Phase 0, and whenever design changes |
| `IMPLEMENTATION.md` | Data structs/types/enums with rationale, function signatures with TODO comments, testing suite definition | Phases 1, 2, 4, and as they evolve |
| `CHANGELOG.md` | Version number at top; one entry per commit/version bump; tagged versions marked | Every commit |
| `PROGRESS.md` | Status table per feature: not started / in progress / done / tested | Every slice |
| `IMPLOG.md` | Single running implementation log; phase-history notes | As phases/slices complete |
| In-code TODOs | Granular, specific work items (Phase 3 output) | Phase 3, checked off during implementation |

---

## Phase 0: Design

The user starts with an initial braindump of everything they know about the
project. The agent then runs a grilling session to fill in the gaps —
purpose, feature overview, architecture (if applicable), data models,
UI/UX, themes, constraints and non-goals, and any open questions.

The agent does **not** just agree with everything the user states. If
something seems wrong or incomplete, the agent asks clarifying questions or
offers critiques and alternative approaches.

Output: `DESIGN.md`.

As the project evolves and things change, the agent always returns to
`DESIGN.md` and updates it accordingly — this file is alive for the life of
the project.

## Phase 1: Data

Define the structs, types, and enums necessary for a complete
implementation. No functions, logic, or implementation. If a struct implies
a function, comment it but don't write it yet.

Output: added to `IMPLEMENTATION.md`, with an overview of the structure and
why the choices were made. Initial files/structure are created to match with simple outlines and small documentation comments dictating the uses for data.

Wait for final user approval before moving on.

## Phase 2: Interfaces

Define function signatures that need to be created or changed — shape of
the API only, no implementation. Each gets a short TODO comment describing
what the function is supposed to do and, briefly, how — no full
pseudocode.

Output: added to `IMPLEMENTATION.md`, with an overview and any open choices
for the user to weigh in on. Initial files/structure are created to match with simple outlines and small documentation comments dictating the uses for data.

Wait for final user approval before moving on.

## Phase 3: TODOs

Annotate the actual codebase with TODO comments at every location required
to build a concrete map of the work before any real code is written. Be
specific.

`PROGRESS.md` is updated to reflect the rolled-up feature list from these
TODOs.

Wait for final user approval before moving on.

## Phase 4: Verification/Testing

Before any dry runs happen, define a repeatable way to prove the
implementation actually works — beyond "it compiles." This is a testing
suite that grows alongside features: each new feature gets tests, and
previous features stay covered.

Tests may need to be altered as new features land — that's expected.

Output: added to `IMPLEMENTATION.md`.

Wait for final user approval before moving on.

## Phase 5: Implementation Loop

With Phases 0–4 approved, implementation proceeds as a repeating loop of
vertical slices. Each slice is a Wayfinder ticket (see `.plan/`) and each
run resolves exactly one ticket. The user hands the agent a ticket (or
points it at the map and lets it take the first frontier ticket) and the
agent runs the whole loop below on its own, using subagents for every gate
that used to wait on the user.

1. **Check the branch.** Never work on the default branch, and never edit a
   file (including the claim) while on it. The user merges each slice back
   to `main` before the next ticket starts, so a run always starts from
   `main`. If on `main`, read `.plan/map.md` (read-only) to identify the
   named ticket or the first frontier ticket, then create a `feature/xxx`
   branch from that ticket's slug. If an earlier slice's branch is still
   unmerged (the map on `main` shows its ticket open), stop and tell the
   user. Only stay on an existing feature branch when resuming that same
   ticket.
2. **Pick and claim the ticket.** With the branch in place, take the named
   ticket or the first frontier ticket and claim it (`claimed: true`) before
   any work. A frontier ticket is open, unclaimed, and has every ticket in
   its `blocked_by` closed (see `.plan/README.md`); skip tickets with any
   open blocker. Refer to tickets by name, never by number. The map's
   `## Notes` are the standing instructions for how to implement. If the
   ticket is HITL, stop and tell the user.
3. **Requirements Report.** Spawn a subagent to write it from the ticket,
   the map, and the design docs (`DESIGN.md`, `IMPLEMENTATION.md`,
   `PROGRESS.md`). See "Requirements Report" below. Use its output as the
   requirements and carry on. There is no approval gate.
4. **Implement.** Use TDD where it fits. Run the linter, the build, and the
   relevant tests as you go.
5. **Tests.** Run the existing suite, then write/update tests for the slice
   per the Planned Tests from the Requirements Report.
6. **Docs.** Update `PROGRESS.md` and `CHANGELOG.md` (see Versioning
   below). If the slice contradicts `DESIGN.md`, update `DESIGN.md` first,
   unless it contradicts a decision already closed in the map — that is a
   stop condition.
7. **Record the resolution.** Write the `.plan/` changes now, before the
   audit, so they ride in the single audited commit: post the resolution in
   the ticket, close it (move it to `.plan/closed/`), add its line to the
   map's Decisions so far, update the Frontier, and add or graduate any
   newly surfaced tickets. CI has not run yet, so the resolution notes CI as
   "pending; see Final Report". The Final Report carries the real CI result.
8. **Deviation Report.** Spawn a subagent to write it from the diff, the
   ticket, and the Requirements Report (see below). Log the Requirements
   Report and Deviation Report into `IMPLOG.md`.
9. **Audit.** See "Audit" below. Commit only after `APPROVE`.
10. **Commit** to the current feature branch, following the commit style
    rules above. This is the one commit for the run (code, docs, and
    `.plan/` changes together). Merging to `main` or pushing to `main` needs
    explicit permission (see the stop conditions).
11. **CI.** Push the feature branch, trigger the run, and watch it (see
    "CI" below). There is no further commit after a green run.
12. **Report back.** See "Final Report" below.

### Requirements Report

Written by a subagent before implementation begins. It covers:

- **Success Criteria** — plain description of the end state/behavior of
  the slice. What does "this slice works" look like?
- **Scope Boundary** — which specific piece of the plan this slice covers,
  and what it doesn't. This is what keeps a slice narrow.
- **Anticipated TODOs** — call out ahead of time what parts are known not
  to be implemented in this slice, so they can be marked in code rather
  than silently skipped. Cross-check these against other slices' scope
  boundaries — if an anticipated TODO here is actually something another
  slice was supposed to deliver, flag that dependency explicitly rather
  than guessing.
- **Planned Tests** — the fixtures/scenarios that would prove the slice
  works, checked against the Phase 4 testing suite.

### Deviation Report

Written by a subagent after the slice implementation is complete but before
the audit. Covers whether the implementation matched the Success Criteria,
stayed within the Scope Boundary, and hit the Anticipated TODOs (or turned
up new ones).

The Requirements Report and Deviation Report together are what get logged
into `IMPLOG.md` for the slice.

### Audit

Spawn a fresh subagent on `haiku` (Agent tool, `model: "haiku"`). If haiku
is unavailable, use `deepseek-v4.1-flash` through `delegate_task`. Give it
the diff, the ticket's question, and the Requirements Report — not the
implementer's own verdict. It answers `APPROVE` or a list of concrete
problems.

- On problems, fix them and re-audit with a fresh subagent.
- After two rounds with no `APPROVE`, stop and report.

### CI

If the repo has remote CI (`.github/workflows/ci.yml`), push the feature
branch (never force). CI starts automatically only on push to `main` or on
a version tag, or manually through `workflow_dispatch`, so a branch push
alone starts nothing. The agent has standing permission to trigger the run
for the feature branch with `gh workflow run ci.yml --ref <branch>`. Then
find the run with `gh run list --workflow ci.yml --branch <branch> --limit 1`
and watch it with `gh run watch <id> --exit-status` until it finishes.
Never trigger runs for `main`.

On CI failure, spawn a subagent with the failing job logs and the branch
diff. It finds the cause and fixes it. The fix goes through the audit,
then commit, push, and watch again. CI-fix commits share the run's version
entry (see Versioning). After three failed attempts, stop and report. If the
run ends with CI red, the Final Report says so plainly, since the ticket was
already closed in the audited commit and the user may need to reopen it.

### Final Report

Written when the run ends, whether it finished or stopped. It lists:

- the ticket name and branch,
- commit SHAs and the version bump,
- the audit verdict and number of rounds,
- the CI result,
- every delegated gate (Requirements Report, Deviation Report, audit) so
  the user can review its output,
- any concerns raised, and anything left for the user.

If the next step is a merge to `main`, or a version tag, ask. Merging and
tagging stay the user's decision.

---

## Versioning

Semver (`MAJOR.MINOR.PATCH`), pre-1.0 conventions:

- **PATCH** — a slice that fixes or refines something already working: bug
  fixes, small tweaks, test additions, doc corrections. No new capability.
- **MINOR** — a slice that completes a new feature/interface from the
  Phase 2/3 map. Expected to be the most common bump.
- **MAJOR** — stays `0` until the project is feature-complete per
  `DESIGN.md` and considered stable. `1.0.0` marks that milestone
  specifically, not just a large feature.

**Every commit gets a version bump, recorded in `CHANGELOG.md`.** The
current version lives at the top of `docs/CHANGELOG.md` — no separate `VERSION`
file. In Phase 5 the agent picks the bump from the rules above and records
it without asking. CI-fix commits within the same ticket run share that
run's version entry instead of bumping again.

**Tagging is a separate, deliberate decision made after each version bump**
— not automatic, and always the user's call. The agent never tags on its
own; it raises the question in the Final Report. Most versions stay untagged but remain in git history via
commits and the changelog. A version gets tagged when it represents a real
checkpoint (e.g., a full feature cluster is done and passing the test
suite, or the design has been stable for a while).

`CHANGELOG.md` entries for tagged versions are visually distinguished from
untagged ones with a separator and a "Released" flag, e.g.:

```
## v0.2.5 — ✅ Released
---
- Full inventory system: pickup, stacking, drop

## v0.2.4
- Fix stacking bug on rapid pickup

## v0.2.3
- Add item stacking logic
```

Tags themselves should be annotated (`git tag -a v0.2.5 -m "..."`) with a
short summary of everything since the last tag, so the tag is useful on
its own without opening `CHANGELOG.md`.
