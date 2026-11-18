# Nichiji

Nichiji is a local-first iOS kanji learning application built around learning one kanji per day with optional flashcard review, dictionary browsing, and stroke practice.

## Language

### Content

**Kanji entry**:
An immutable bundled record describing a single kanji character, its readings, meanings, radical, level classifications, and example words. Stroke paths load separately and lazily. Level classifications are the unofficial JLPT level, the Jōyō grade and the kanji classification.
_Avoid_: Kanji model, card, character record

**Reading**:
A pronunciation of a kanji, categorized as either onyomi (Chinese-derived, rendered in katakana) or kunyomi (native Japanese, rendered in hiragana with okurigana separated by a hyphen), paired with its romaji transliteration.
_Avoid_: Pronunciation, furigana

**Example word**:
A Japanese vocabulary item containing a kanji entry, showing the written word, kana reading, romaji, and English gloss. Chosen at generation time from JMdict, at most three per kanji.
_Avoid_: Compound, vocab, sample sentence

**Bundled dataset**:
The generated, version-pinned content shipped in the app: `Dataset/Shared/` (`kanji-index.json`, `kanji/<hex>.json`, `DATA-SOURCES.md`) for both targets and `Dataset/AppOnly/` (`stroke-order/<hex>.svg`, `words.json`) for the app only.
_Avoid_: Database, content pack

**Dataset generator**:
The build-time script in `tools/dataset/` that builds the bundled dataset from pinned upstream files. It is not part of any app target.
_Avoid_: Importer, seeder

**Kanji index**:
The lightweight `kanji-index.json` of summary rows (`KanjiIndexEntry`) used for pools and ordering.
_Avoid_: Manifest, catalog

**Word index**:
The app-only `words.json` of common JMdict forms, each with a `rank`, that Dictionary search reads.
_Avoid_: Word database

**Search index**:
The folded in-memory `DictionarySearchIndex`, built once from `kanji-search.json`, `words.json` and the kanji index when Dictionary first opens.

**Jōyō kanji**:
The 2,136 kanji with a KANJIDIC2 grade of 1 to 6 or 8. Grades 9 and 10 (jinmeiyō) are not Jōyō and have no `joyoGrade`.
_Avoid_: Common-use kanji

**Kanji classification**:
Which list a bundled kanji belongs to, stored as `classification` on every record and index entry: `joyo` (2,136), `jinmeiyo` (806) or `hyogai` (3,465). Both the JLPT and Jōyō level ladders derive from it, and `joyoGrade` stays Jōyō-only.
_Avoid_: Kanji type, kanji tier

**Level ladder**:
The ordered rungs a learner studies through, one per level system. The JLPT ladder is N5 to N1, then Jinmeiyō ("Name kanji"), then Hyōgai ("Beyond the lists"); the Jōyō ladder is grade 1 to Secondary, then the same two. Every bundled kanji sits on exactly one rung per ladder. On the JLPT ladder the Jinmeiyō rung holds only the 559 jinmeiyō kanji with no N-level (the other 247 are N1); on the Jōyō ladder it holds all 806. Hyōgai holds all 3,465 on both.
_Avoid_: Level list, tier

**Jinmeiyō kanji** ("Name kanji"):
Every KANJIDIC2 kanji with grade 9 or 10, except the 57 compatibility ideographs that fold into a unified twin, 806 in all. 247 of them are Waller N1 kanji, and 559 have no N-level.
_Avoid_: Name kanji (as a stored value)

**Compatibility ideograph**:
A code point in U+F900–U+FAFF whose canonical (NFC) form is a unified ideograph. Swift compares `String`s by canonical equivalence, so one would equal its twin as a dictionary key, `Set` member or `Identifiable` id. The generator folds each into its twin and fails if the twin is not bundled. KANJIDIC2 lists 57 of them as jinmeiyō.
_Avoid_: Variant kanji

**Hyōgai kanji** ("Beyond the lists"):
Every JIS X 0208 kanji that is neither Jōyō nor jinmeiyō, 3,465 in all. Most have no KANJIDIC2 frequency rank, so list order falls to their JMdict common-word count. All have KanjiVG stroke order. The 32 jinmeiyō kanji with no KanjiVG file ship without it.
_Avoid_: Rare kanji, other kanji

**JLPT level (unofficial)**:
The N5 to N1 value from Jonathan Waller's community lists. The JLPT publishes no official kanji lists.
_Avoid_: Official level

**Estimated JLPT level**:
A level OpenJLPT assigned to a Jōyō kanji that Waller's lists omit. It is flagged and shown as "(est.)".
_Avoid_: Guessed level

**Featured word**:
The first example word of a kanji, used by the lock-screen widgets and the flashcard answer.
_Avoid_: Top word, main example

### Study pool and daily assignment

**Study pool**:
The active set of kanji entries eligible for daily assignment, determined either by a selected JLPT level, a selected Joyo grade, or a custom selection. The JLPT and Jōyō ladders include the Jinmeiyō and Hyōgai rungs, so any bundled kanji can be a study pool member.
_Avoid_: Deck, curriculum, syllabus

**Daily assignment**:
The single kanji entry assigned to the learner for a specific local calendar day, with status `assigned`, `learned`, or `missed`.
_Avoid_: Daily card, kanji of the day record

**Missed daily assignment**:
A daily assignment whose local calendar day ended without the learner marking it "Got it"; its kanji entry stays in the `new` study stage so it returns to the unlearned study pool, and the next day's reminder uses the missed-day copy ("You missed yesterday's kanji. That's okay, check it now.").
_Avoid_: Failed card, expired card

**Day provider**:
The injected clock and calendar boundary (`DayProvider`) that supplies the current instant, local calendar, `yyyy-MM-dd` day string, and next local midnight calculation.
_Avoid_: Clock singleton, Date helper

**Rollover**:
The lazy, idempotent day-transition check run whenever the app, widget, or reminder scheduler requests a day's assignment: it marks any `.assigned` rows strictly before today as `.missed` without rewriting `.learned` or `.missed` rows, then returns or creates today's assignment.
_Avoid_: Midnight cron, background reset

**Reminder window**:
The rolling queue of up to 7 pending daily notification requests where the next upcoming fire uses specific copy (kanji-led or missed-day) and days 2 through 7 use generic copy ("Today's kanji is ready").
_Avoid_: Repeating notification, push campaign

### Learner progress and review

**Learner**:
A person who reads English and is learning to read and write Japanese kanji. A native Japanese reader is not a learner in this sense, since every meaning and gloss is English.
_Avoid_: User, student

**Kanji progress**:
The mutable learner state for a specific kanji entry, tracking its study stage, review schedule, and answer counts.
_Avoid_: User kanji, card state

**Study stage**:
The learner's familiarity tier for a kanji entry: `new`, `learning`, `familiar`, or `known`. The `known` tier graduates: the kanji leaves the due queue entirely and only returns through Forget it.
_Avoid_: Mastery level, SRS stage, rank

**Due**:
A kanji whose next review day is today or earlier; only due kanji fill a review session.
_Avoid_: Overdue card, pending review

**Review session**:
A bounded run of flashcards drawn from the due kanji under the learner's review settings. The first answer to each kanji in a session decides its stage and next due day; a repeated forgotten card is practice that only logs.
_Avoid_: Drill, quiz, round

**Learned**:
The state of a daily assignment or kanji entry after the learner taps "Got it" on Today or the widget, moving its study stage out of `new`.
_Avoid_: Mastered, completed, finished

**Got it**:
The learner action confirming recall or completion of a kanji on Today, the widget, or a review flashcard.
_Avoid_: Correct, pass, easy

**Forgot it**:
The learner action on a review flashcard indicating the kanji was not recalled and needs further study.
_Avoid_: Wrong, fail, missed

**Forget it**:
The explicit learner action that resets a learned kanji back to the `new` study stage and returns it to the study pool.
_Avoid_: Reset, unlearn, delete progress

### Access

**Pro**:
The one-time, non-consumable unlock that adds lock-screen widgets, CSV export, photo lookup and handwriting search. Everything else in the app is free, including the full You tab, Review, Practice, Dictionary and Custom pools.
_Avoid_: Premium, subscription, paid version, plan

### Stats

**Study day**:
A local calendar day with at least one learned daily kanji or review answer (Got it or Forgot it). Forget it does not make a study day.
_Avoid_: Active day, streak day

**Day streak**:
The run of consecutive study days ending yesterday, plus today once today is a study day. Today never breaks it before it ends.
_Avoid_: Chain, combo

**Streak freeze**:
The optional rule that forgives one missed day per locale calendar week, refilling each week. A forgiven day keeps the day streak alive without adding to it. It is recomputed from history, never stored.
_Avoid_: Streak shield, skip token

**Milestone**:
A lifetime achievement on the You tab computed from history, so once earned it stays earned after Forget it or a broken streak.
_Avoid_: Badge, trophy, award

**Needs attention**:
Up to three kanji past `new` with at least one Forgot it answer, most forgotten first.
_Avoid_: Weak kanji, leeches
