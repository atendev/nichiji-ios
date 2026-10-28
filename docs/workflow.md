# AI Workflow

A phased process for working through a project with an AI collaborator, from
initial braindump to shipped features, with clean version history and
documentation at every step.

---

## Agent Rules

These apply at all times, across every phase:

- Never proceed to the next phase without explicit confirmation.
- Wait for confirmation before committing or merging.
- Never implement more than the current phase asks for.
- Never assume a correction is minor enough to skip a re-review. Always
  re-present after changes.
- Do not people please. If there's a concern about an approach — technical
  risk, design inconsistency, something that might cause problems later —
  raise it, even if the user seems confident. State the concern clearly and
  specifically and let the user decide whether to address it or proceed
  anyway.
- All reviews follow the same loop: the agent writes the file(s), the user
  approves, then it's committed. No committing on spec.

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
vertical slices:

1. Pick one TODO cluster (typically one feature/interface from Phase 3).
2. **On trunk**, write a Requirements Report for the slice (see below).
   Wait for approval before doing anything else.
3. Create the slice branch and implement it.
4. Run the existing test suite.
5. Write/update tests for the new slice, per the Planned Tests from the
   Requirements Report.
6. **On trunk**, write a Deviation Report for the slice (see below). Wait
   for approval before proceeding.
7. Update `PROGRESS.md` status for the feature.
8. Update `CHANGELOG.md` (see Versioning below).
9. Log the Requirements Report and Deviation Report into `IMPLOG.md`.
10. If the slice revealed something that contradicts `DESIGN.md`, stop and
    update `DESIGN.md` first before continuing.
11. Present the diff to the user for approval.
12. Commit (only after approval), following commit style rules above.
13. Decide whether this version gets tagged (see Versioning below).

### Requirements Report

Written on trunk, before the slice branch is created. Implementation does
not begin until this is approved. It covers:

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

Written on trunk, after the slice implementation is complete but before
commit and merge. Covers whether the implementation matched the Success
Criteria, stayed within the Scope Boundary, and hit the Anticipated TODOs
(or turned up new ones).

The Requirements Report and Deviation Report together are what get logged
into `IMPLOG.md` for the slice.

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
current version lives at the top of `CHANGELOG.md` — no separate `VERSION`
file.

**Tagging is a separate, deliberate decision made after each version bump**
— not automatic. Most versions stay untagged but remain in git history via
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
