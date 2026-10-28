# Nichiji UI reference

An iOS kanji-learning app: one kanji a day, plus review, dictionary and practice. This bundle is meant to give an AI (or a developer) as accurate a picture of the UI as possible.

## Read in this order

1. `overview.png`: every main screen on one sheet. Start here for the big picture.
2. `design-notes.md`: the decisions and the reasoning behind them (navigation, flows, what is mocked, what is still open). It is the source of truth where it disagrees with a screenshot.
3. `INDEX.md`: each screenshot, what it shows and how you get to it.
4. `screens/`: the full-size screenshots (390 x 844 pt at 2x), numbered in flow order. Screens that scroll are shown in several frames.
5. `tokens/tokens.json` and `tokens/ADDITIONS.md`: exact colors, type, spacing, radius, shadow, motion and layout numbers.
6. `source/`: the screen source files, for exact styles. See `source/README.md`.

## Things to know

- Everything shown is sample data. Kanji lists, Jōyō grade placement, counts and stroke diagrams are placeholders. Search and handwriting recognition are mocked.
- Only the light theme is rendered. The dark theme exists in the tokens but is not applied in the mockup.
- Interactions (flip, swipe, sheets, drag to dismiss) cannot be seen in a still. They are described in `design-notes.md` and the Motion table in `tokens/ADDITIONS.md`.
- Fonts: Shippori Mincho for kanji, Zen Kaku Gothic New for the interface.
