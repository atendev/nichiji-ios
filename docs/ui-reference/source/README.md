# About the source files

Each `*.dc.html` file is one screen (artboard) in a custom "Design Component" format. It is plain HTML and CSS with a small template layer, so the styles are inline and exact:

- `<x-dc> ... </x-dc>` holds the screen's markup. All sizes, colors and fonts are in `style="..."` attributes.
- `{{ name }}` is a value filled in by the script at the bottom of the file. Lookups are dotted only (`{{ item.label }}`).
- `<sc-if value="{{ x }}">` shows content conditionally. `<sc-for list="{{ items }}" as="item">` repeats it.
- `<dc-import name="Other" ...>` mounts another screen or component inside this one. Wrapper files such as `TodayPractice.dc.html` just mount a component in a particular state.
- The `<script type="text/x-dc">` block at the end is a class with `renderVals()` (computes everything the template needs) and event handlers (taps, swipes, drag).
- `<helmet>` holds the font links and the CSS rules (hover, press, keyframes).

Where to look:

| File | Role |
|------|------|
| `App.dc.html` | Router and shared state (tab, level, order, settings). The live preview. |
| `Today`, `Dictionary`, `Review`, `You` | The four tabs. |
| `SettingsSheet`, `Settings*` | The settings sheet and its sub-screens. |
| `KanjiDetail`, `StrokeGrid`, `PracticeSheet`, `DrawSearchSheet`, `ReviewSession` | Shared components. |
| `Welcome`, `Daily`, `Flashcards`, `Level`, `Reminder`, `Widget`, `Ready`, `Main` | Onboarding. |
| `canvas.json` | Where each screen sits on the design canvas, plus notes. |

These files need the design canvas runtime to render, so use `../screens/` for what they look like and these files for exact values. Stroke diagrams are rough placeholders for 13 kanji; use real stroke data in production.
