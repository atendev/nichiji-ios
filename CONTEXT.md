# Nichiji

Nichiji is a local-first iOS kanji learning application built around learning one kanji per day with optional flashcard review, dictionary browsing, and stroke practice.

## Language

### Content

**Kanji entry**:
An immutable bundled record describing a single kanji character, its readings, meanings, radical, stroke paths, level classifications, and example words.
_Avoid_: Kanji model, card, character record

**Reading**:
A pronunciation of a kanji, categorized as either onyomi (Chinese-derived, rendered in katakana) or kunyomi (native Japanese, rendered in hiragana with okurigana separated by a hyphen), paired with its romaji transliteration.
_Avoid_: Pronunciation, furigana

**Example word**:
A Japanese vocabulary item containing a kanji entry, showing the written word, kana reading, romaji, and English gloss.
_Avoid_: Compound, vocab, sample sentence

### Study pool and daily assignment

**Study pool**:
The active set of kanji entries eligible for daily assignment, determined either by a selected JLPT level, a selected Joyo grade, or a custom selection.
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

**Kanji progress**:
The mutable learner state for a specific kanji entry, tracking its study stage, review schedule, and answer counts.
_Avoid_: User kanji, card state

**Study stage**:
The learner's familiarity tier for a kanji entry: `new`, `learning`, `familiar`, or `known`.
_Avoid_: Mastery level, SRS stage, rank

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
