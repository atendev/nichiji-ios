Widgets keep the day's kanji on the home and lock screens: small, medium and lock screen only (no large widget in v1).

- Small: `kanji-widget` in `ink` with the main meaning in `caption` and `ink-muted`, on `surface-raised` with a 1px `hairline` border and `radius-lg`.
- Medium: kanji, readings, meaning and one example word, plus an interactive "Got it" button. This is the widget's only vermilion fill; after tapping, show the learned state.
- Lock screen: the kanji and meaning in a single ink. The system supplies tint and background, so do not add fills or colors.
- Tapping the widget opens that kanji in the app. Timelines refresh at local midnight and after any learned or known change.
- The consumer provides the kanji, main meaning, readings and one example word. Widgets use the dark theme tokens when the system appearance is dark.
