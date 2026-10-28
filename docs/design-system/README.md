Nichiji is a calm, book-like kanji app. Paper, ink, and one stamp of red. Build every screen so the kanji is the loudest thing on it.

## Content fundamentals

- Write in sentence case. Labels and buttons never end in a period; helper text does. "Got it", not "Got It!".
- Speak plainly and quietly, like a good teacher. No exclamation marks, no cheering, no guilt. Show streaks as plain numbers and dots, never as a threat: a missed day is just a gap, and the streak freeze (one missed day a week) is a setting, not a reward.
- Buttons are verb first, one to three words: "Got it", "Start review", "Practice this kanji", "Mark as known". Review cards are answered with "Got it" or "Forgot it" (past tense: what happened); "Forget it" is the separate action that returns a learned kanji to the pool.
- Show readings in kana by default (ガク, まな-ぶ). Romaji only when the setting is on, as secondary text in `ink-muted`.
- Notification copy names the kanji first: "学 · Today's kanji is ready" and, after a missed day, "You haven't checked today's kanji yet". Add "12 reviews due" when there are cards; never send a second notification.
- Say "kanji" for both singular and plural. Say "learned" and "known", never "mastered".
- No emoji anywhere in the interface.

## Visual foundations

**Color.** Two themes, one personality. Light is *Washi*: `surface` paper, `ink` text. Dark is *Sumi night*: warm near-black, not blue, with `ink` flipped to paper. Dark is a re-lit version of the same page, so every token exists in both themes and screens never branch on theme.

- Put one `vermilion` fill on any screen: the primary action (usually "Got it") or the active progress mark, not both competing. Elsewhere, vermilion appears as text, the active tab, ring progress and check-in dots.
- Text on a vermilion fill is always `on-vermilion`.
- `matcha` means got it, progress, known or complete. `mustard` means forgot it, and is the only warm second color: use `mustard-text` for words and `mustard` for icons and borders. `indigo` means information and focus. Always pair a status color with a word or icon.
- Set kanji in `ink`, never in an accent color. Use `vermilion-wash` only for the learned state and selected rows.

**Type.** Mincho for kanji and example words, Gothic for everything else. The families are `mincho` (Shippori Mincho) and `gothic` (Zen Kaku Gothic New), both SIL Open Font License and bundled in the app; fall back to Hiragino Mincho ProN and Hiragino Sans.

- The daily kanji uses `kanji-hero`. Search results and flashcards use `kanji-large`. Widgets use `kanji-widget`.
- Example words use `word`. Everything interface-level uses `title`, `heading`, `body`, `callout`, `caption` or `label`.
- Never set body copy in Mincho. Never use weights above 500.
- Support Dynamic Type for Interface styles. The kanji styles scale but never below the size that keeps strokes legible.

**Space and shape.** Spacing is a 4px scale (`space-1` to `space-7`); the screen margin is `space-4` and card padding is `space-5`. Corners are small and seal-like: `radius-sm` for tags, `radius-md` for buttons and groups, `radius-lg` for cards and widgets.

**Borders over shadows.** Cards are `surface-raised` with a 1px `hairline` border. Use `shadow-card` only when a card floats over content, and `shadow-sheet` only for sheets. Interactive controls outlined by a border use `border-control`, which keeps 3:1 against the surface.

**The stamp.** The brand mark is a hanko-style vermilion seal containing 日. On "Got it" the learned state may press a small vermilion seal beside the kanji. This is the only celebratory moment; keep it still, with no confetti or bounce.

**Motion.** Motion confirms an action and never decorates: press states, the 3D card flip, swipe tilt-and-fly-off, sheet slides, fade-ups for the next card, and stroke-order drawing at an even pace. No bounce, no confetti. Under Reduce Motion, turn all of it off: cards swap instantly and strokes step on tap.

**States.** Pressed vermilion uses `vermilion-hover`. Focus is a solid 2px `focus-ring`, offset 2px. Disabled controls are avoided; leave them enabled and respond with a short explanation.

**Navigation and headers.** Four tabs: Today, Dictionary, Review, You. Practice is not a tab; it opens as a bottom sheet from "Practice this kanji" on Today, kanji detail and the review answer side. A sliders button at the top right of each tab opens one shared Settings sheet (not on the full-screen review session or kanji detail). Every tab header pairs the kanji with the English word, split by a divider: 今日 | Today, 辞書 | Dictionary, 復習 | Review, 私 | You. Hide scrollbars everywhere.

**Layout.** Content sits in a single column on phones. On the iPhone Duo's inner 4:3 screen, split into two panes: the kanji, readings and stroke order on the left; example words, history or practice on the right. The same two-pane arrangement becomes the iPad layout later. Keep the hero kanji centered in its pane.

## Iconography

Use SF Symbols, regular weight, outline variants, in `ink-muted`; the active tab is filled and `vermilion`. Do not use emoji, and do not draw kanji or kana as icons. The app icon and seal mark are in the Brand asset group; use them as supplied and never redraw them.

## Widgets and notifications

- Small and lock screen: the kanji in `kanji-widget` with its main meaning in `caption`.
- Medium: kanji, readings, meaning and one example word, with a "Got it" button. This is the one vermilion fill.
- Dark widgets use `surface-raised` from the dark theme; the lock screen inherits system tint, so draw the kanji in a single ink.

## Accessibility

Text holds 4.5:1 on the surfaces named in each token's usage note, in both themes; borders and focus rings hold 3:1. Never rely on color alone: learned shows a check and the word "Learned", known shows "Known".
