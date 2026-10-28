The KanjiCard presents one kanji with everything needed at a glance: level, stroke count, meaning, on and kun readings, and three example words.

- Place it on `surface`; the card is `surface-raised` with a 1px `hairline` border and `radius-lg`. No shadow.
- The kanji is `kanji-hero` in `ink`, centered. The meaning is `body`; readings are `body` with the kana in `ink` and labels in `ink-muted`.
- Example words use `word` (Mincho) with kana and gloss in `caption`. Show three, preferring words whose other kanji are at or below the learner's level.
- One primary "Got it" button at the bottom. Once learned, it becomes the `Button` learned state.
- Tapping a reading or word speaks it with system Japanese text-to-speech.
- The consumer provides the kanji, level label, stroke count, readings, meaning and three words. Show romaji beneath the kana only when the setting is on.
- On the Duo inner screen, move the example list into the right pane instead of stretching the card.
