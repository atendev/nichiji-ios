# Nichiji: design notes and decisions

iOS kanji-learning app. One kanji a day, plus review, dictionary and practice.
Design source: the Nichiji design canvas (Onboarding page and App page), built on the Nichiji design system.
All numbers, kanji lists and stroke diagrams in the mockups are sample data unless noted.

## Design system rules followed

- Sentence case. No emoji. No bounce or confetti.
- One vermilion fill per view (the primary action). No font weights above 500.
- Kanji in Shippori Mincho, UI in Zen Kaku Gothic New.
- Surfaces: warm paper tones, with a dark theme defined.
- Extra colors: matcha green for "got it" and progress. Mustard yellow (#a67300, wash #f6e8bd) for "forgot it". The yellow is not in the design system, so it needs formalizing.
- Animation and UI feedback matter: press states, flips, swipes, sheet slides, fade-ups. All motion is disabled under reduced-motion.
- Scrollbars are hidden everywhere.
- Header pattern is kanji, divider, English (今日 | Today, 辞書 | Dictionary, 復習 | Review, 私 | You).

## Navigation

- Bottom tabs: **Today, Dictionary, Review, You**.
- Search was renamed to Dictionary (book icon). Practice is not a tab. You is the fourth tab.
- Practice is only reached from a kanji (see Practice).
- Settings button (sliders icon, top right) is on Today, Dictionary, Review and You. It always opens the same bottom sheet. It is not on the full-screen review session or the kanji detail screen.

## Onboarding (7 screens plus a live preview)

1. Welcome: seal, 日字, "Nichiji", tagline **"One Kanji. One Day. Every Day."** (open to workshopping), Get started, "No account needed. Nichiji does not collect any data."
2. One kanji a day: "Each day you get a new kanji to learn with readings and example words to help you learn." (no exclamation mark)
3. Flashcards: interactive.
   - Tap to flip (3D flip animation).
   - Swipe right for **Got it** (green check, card tilts and flies off).
   - Swipe left for **Forgot it** (yellow icon, same motion left).
   - Wording is "Forgot it", not "Forget it".
4. Choose your level. A **JLPT / Jōyō grade** switch at the top picks the system: N5 to N1, or Jōyō 1st to 6th grade plus Secondary school. Rows show kanji counts. A note points to Settings for the daily order. There is no Custom option or order control in onboarding.
5. Daily reminder.
6. Home screen widget.
7. You're all set, which leads into Today.
- The progress bar has 6 segments and excludes the welcome screen. The welcome screen is still reachable by going back.

## Today (main screen)

- The big kanji (260px) takes most of the first screen, with only a sliver of the Details card peeking at the bottom to signal scrolling.
- Space between the kanji and the readings was increased to 32px.
- Below the hero: Details card (meaning, onyomi, kunyomi, strokes, radical, JLPT, grade), Example words card, Stroke order card.
  - Dividers sit between rows only, never after the last row.
  - Example words have no divider under the last word.
- Stroke order card: 2-column grid, one cell per stroke in order (numbered), with the current stroke bold and earlier strokes dimmer.
- The practice button sits at the bottom of the stroke card and reads **"Practice this kanji"** with the pencil on the left.
- "Got it / Learned" button under the kanji marks it learned and shows the seal stamp.

## Settings (bottom sheet)

- **Appearance is at the top**: System / Light / Dark as mini phone previews, modeled on the Kita app's picker. System is shown as a diagonal light/dark split.
- Learning group: Level, Daily reminder, **Review** (new), Show romaji, **Streak freeze** (new).
- Help: Add a widget, Replay introduction. About: Privacy ("Data not collected"), Version.
- Sub-screens push in from the right: Level, Customize your kanji, Daily reminder, Widgets, Privacy, **Review**.

## Level, daily order and custom kanji

- The Level screen starts with a **JLPT / Jōyō grade** switch ("Levels based on"). Switching picks the first level of the new system (N5 or 1st grade).
  - JLPT rows: N5 to N1.
  - Jōyō rows: 1st to 6th grade and Secondary school, with sample counts of 80, 160, 200, 202, 193, 191 and 1,110 kanji. The counts need verifying.
- **Daily order** (three radio rows): **Most common** (default), **List order**, **Random**.
- Below that is a **CUSTOM** row, "Customize your kanji".
- The settings sheet and Today's header follow the system: "3rd grade · Jōyō" and "GRADE 3" for Jōyō, "N5" for JLPT, "CUSTOM" when custom is active.
- **Custom screen follows the chosen system.** Under JLPT its groups are N5 to N1. Under Jōyō they are 1st to 6th grade and Secondary school. Switching systems drops picks that are not in the new list.
  - Sticky header per group (name, "N kanji · M on"), a small right-aligned Select all / Clear all button, and a 5-column grid of kanji toggles (on = vermilion wash and border with a tiny check). The bottom bar shows "N on of M kanji" and a Done button.
  - When Custom is active it is highlighted and the levels are not.
- Open question: add "Customize your kanji" to the onboarding Level screen too. Not built.
- The kanji lists in the picker are samples, not verified. The Jōyō grade placement was done from memory.

## Dictionary

- Search bar at the top, a **"Draw a kanji to search"** button under it, then a grid of kanji buttons grouped by level (same grid as the custom picker). Tapping a kanji opens its detail screen.
- Searching is meant to be fuzzy: a word returns the word, or the individual kanji. This is mocked only: a static results artboard, and the live preview shows the same static results for any text.
- **Draw to search**: the button under the search bar opens a bottom sheet ("Draw to search") with a drawing pad, a row of five **matches** that updates as strokes are added, Undo and Clear. Tapping a match puts that kanji in the search bar. The sheet dismisses like the practice sheet. An earlier pen icon inside the search field was replaced by the explicit button because it was not obvious. The matches are sample sets only; real handwriting recognition is not built.
- Detail screen: big kanji, readings, meaning, Details card, Example words, then a Stroke order card with the practice button inside it.
- Stroke diagrams exist for only 13 kanji, as rough hand-drawn placeholders. The card says so for the rest. Use real stroke data (e.g. KanjiVG) in production.

## Review

- **Review home**: "kanji due today" count with kanji tiles, a Start review button, and a "Session options" link. Below that: Your kanji (stages New / Learning / Familiar / Known), Coming up, and This week (streak dots).
- **Session (flashcards)**:
  - Tap to flip. After flipping, **swipe right = Got it, left = Forgot it** (same tilt, badges and colors as onboarding), or use the two buttons. Swiping and the buttons are disabled until the card is flipped.
  - The next card **fades up**.
  - Progress bar and counter at the top, close button at top left.
  - **Audio button** (speaker) on every card, top right. It plays the reading. The mockup only animates it.
  - Answer side has a **"Practice this kanji"** button at the bottom: thick dashed outline, no fill, pencil on the left.
  - Ends with a "Review complete" summary: reviewed, got it, forgot.
  - "Forgot" cards come back (see settings).
- **Review settings** (reachable from the settings sheet and from Session options on the Review tab):
  - Card types (any mix): Kanji to meaning, Kanji to reading, Meaning to kanji. At least one stays on.
  - Order: Due first, Hardest first, Newest first, Random.
  - Cards per session: 5 / 10 / 20 / All due.
  - Show example word on the answer side.
  - Repeat forgotten cards at the end of the session.
  - Play audio automatically on flip. Audio plays: Reading, or Reading and word.
  - Ideas not built: daily review cap, furigana toggle, review reminder.

## Practice

- Not a tab. It opens as a **bottom sheet over whatever the user is doing**, like settings. It can be dismissed by swiping down from the handle, tapping the dimmed area, or pressing Done.
- Entry points: "Practice this kanji" on Today, on the Dictionary detail screen, and on the flashcard answer side.
- Contents: a writing pad you draw on, a faint guide kanji behind it (Guide toggle), Undo, Clear, and a stroke counter.
- **The sheet opens partway and expands to near full screen** (scroll it, or drag the handle up) to reveal the Stroke order grid below the pad, the same grid as the main screen.
- The pad only records strokes. It does not check them against stroke order yet.

## You

- Stat tiles: day streak, longest streak, kanji learned, reviews done, got-it rate, time studying.
- Streak freeze status row (follows the setting).
- Activity: 12-week grid, darker squares on busier days.
- By level: progress bars for N5 to N1. (Not yet switched to Jōyō grades.)
- **Milestones**: earned ones show the seal, locked ones show a lock and a progress bar (first kanji, 10 and 25 kanji, 100 reviews, 7 and 30 day streaks, finish N5).
- Needs attention: the three most-forgotten kanji.
- Your kanji: switch between **Learned** (grid of learned kanji) and **History** (day-by-day list of learned and reviewed kanji). Tapping any kanji opens its detail.
- **Streak freeze**: setting in the settings sheet. Miss one day a week and keep the streak.
- **Export history** button at the bottom of History saves a CSV. Mocked.

## Not built or still open

- Real audio, real fuzzy search, real handwriting recognition for draw-to-search, real stroke data and stroke checking.
- Theme switching is a preview only (choosing Dark doesn't re-theme the app).
- A You-page layout pass, a review-session settings button, and a formal home for the mustard yellow.
- The onboarding Level screen's custom option (see above).
- Kanji lists, Jōyō grade placement, grade counts and example words are from memory and need verification.
- The Dictionary browse grid and You "By level" bars still group by JLPT only.
