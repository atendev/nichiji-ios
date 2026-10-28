The TabBar holds the app's four destinations: Today, Dictionary, Review and You. Practice is not a tab; it opens as a bottom sheet from a kanji. Settings is a sliders button in each tab's header, not here.

- Sits on `surface-raised` with a 1px `hairline` top border. Labels are `caption`.
- The active tab uses `vermilion` for icon and label with a `vermilion-wash` icon fill; inactive tabs use `ink-subtle`. Always show labels.
- In the app use SF Symbols (regular weight, outline; filled when active); the icons in this preview are stand-ins drawn with 1.6px strokes.
- On iOS 27, the system draws the Liquid Glass bar: keep the tint tokens above and avoid custom backgrounds there. On the Duo inner screen, the bar may move to a sidebar with the same four items.
