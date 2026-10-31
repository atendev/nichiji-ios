# Dataset generator

Builds the committed `Dataset/` bundle from KANJIDIC2, JMdict, KanjiVG and the pinned N-level lists. Standard-library Python 3.10 or newer, no dependencies. Not part of any app target.

- `make dataset-fetch` downloads the inputs into untracked `.cache/` and rewrites `sources.lock.json` (URL, SHA-256, upstream version). KanjiVG r20260714 and the Waller and OpenJLPT files at commit `0d1d341` are hash-enforced. The EDRDG files roll, so their hash and version are recorded but not enforced.
- `make dataset` runs offline from `.cache/` and is deterministic. It fails if a cached file does not match `sources.lock.json`, a KanjiVG stroke count differs from KANJIDIC2 outside `strokecount-allowlist.json`, or the output passes 3 MB (Shared) or 8 MB (Shared plus AppOnly).
- `make dataset-test` runs the unit tests on small inline fixtures.

Output: `Dataset/Shared/` (`kanji-index.json`, `kanji/<hex>.json`, `DATA-SOURCES.md`) goes to both targets, `Dataset/AppOnly/` (`stroke-order/<hex>.svg`, `words.json`) to the app only. SVGs keep only the ordered stroke paths; the licence and attribution live in `DATA-SOURCES.md`.

Refresh for every App Store release: run `make dataset-fetch`, `make dataset`, review the diff, and commit. Ship a data-only patch if the EDRDG snapshot is older than 6 months.

Selection rules: the 2,136 Joyo kanji plus Waller's 247 non-Joyo kanji (all N1). Up to 3 JMdict examples per kanji, ranked by priority tier, then same-or-easier Waller vocabulary level, then `nf` band, then sequence number. Headwords with digits, Latin letters or `sK/iK/oK/rK` forms are dropped, and every kanji in a word must be in the bundle. `words.json` holds the same words restricted to the common tier (`news1`, `ichi1`, `spec1`, `gai1`).
