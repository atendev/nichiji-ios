# Tokens and measurements beyond tokens.json

`tokens.json` is the Nichiji design system (light "Washi" and dark "Sumi night" values for color, type, spacing, radius, shadow). The mockups use it plus the items below. Only the light theme is shown in the screenshots; the dark theme is defined but the app does not switch to it in the mockup.

## Colors added in the app (not in the design system)

| Use | Value |
|-----|-------|
| Mustard, "Forgot it" icon and accents | `#a67300` |
| Mustard wash (background) | `#f6e8bd` |
| Mustard text on the wash | `#6b4a00` |
| Matcha mid / lighter tints (progress, activity grid) | `#a9bf98`, `#6f9468` |

## Layout

- Screen: 390 x 844 pt (iPhone). Content starts 56px from the top (status bar). Side margin 16px (24px on onboarding).
- Tab bar: 83px tall including a 34px bottom safe area, 4 equal tabs, 24px icons, 11px labels. Active tab uses vermilion with a filled icon.
- Minimum touch target 44 x 44. Primary buttons 48 to 52px tall, radius 8.
- Cards and sheets: radius 20, fill `surface-raised`, 1px `hairline` outline. Bottom sheets round the top corners only and use `shadow-sheet`; a 36 x 4px handle sits 8px from the top. Scrim is `rgba(31,27,22,.4)`.
- Kanji grid: 5 columns, 8px gap, square tiles, 28px Shippori Mincho kanji, 8px radius, 1px `border-control` outline. Selected tiles use `vermilion-wash` with a vermilion outline and a small check.
- Today hero kanji is 260px (larger than the `kanji-hero` token). Header: kanji, 1.5px vertical divider, English title (28/34).
- Dashed outline button ("Practice this kanji"): 2px dashed `border-control`, no fill, 9px dashes with 6px gaps, pencil icon on the left. Drawn as an SVG rect because CSS cannot size dashes.

## Motion

| Interaction | Timing |
|-------------|--------|
| Screen enter | 320ms ease-out, fade up 10px |
| Bottom sheet in / out | 320ms `cubic-bezier(.2,.8,.2,1)` / 220ms ease-in |
| Sub-screen push in / out | 300ms `cubic-bezier(.2,.8,.2,1)` / 240ms ease-in, from the right |
| Card flip | 3D rotate (preserve-3d) |
| Swipe off | translateX +-400px and rotate +-16deg over 420ms; next card fades up |
| Press | scale .97 (.95 on kanji tiles), 120ms; hover tint `#eae2d1` |
| Focus ring | 2px `indigo` (`#2f4a6b`), offset 2px |

All animation is removed under `prefers-reduced-motion`.

## Fonts

Shippori Mincho (kanji, 400 and 500) and Zen Kaku Gothic New (UI, 400 and 500), both from Google Fonts. No weight above 500. The screenshots were rendered with these fonts.
