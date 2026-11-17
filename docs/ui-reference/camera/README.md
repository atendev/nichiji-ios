# Nichiji camera scan package

The camera flow for Nichiji: take a photo of a kanji, see the kanji it finds, open any of them.

Read in this order:

1. `overview.png`: all the screens on one sheet.
2. `camera-design-notes.md`: the flow, the gestures, the states, the look, what is mocked and what is not designed.
3. `screens/`: full-size screenshots (390 x 844 pt at 2x), numbered in flow order. `0-` is the entry point in the Dictionary.
4. `source/`: the screen source files. They are plain HTML and CSS with a small template layer (`{{ }}` values, `<sc-if>`, `<sc-for>`, `<dc-import>`) and need the design canvas runtime to render, so use the screenshots for how it looks and the source for exact styles. The two existing screens it edited, `Dictionary.dc.html` (adds the Scan button) and `KanjiDetail.dc.html` (adds sample data for 語 入 口 受 付), replaced the copies in `../source/`.

This package covers only the camera. Colors, type and spacing come from the Nichiji design system (light "Washi" and dark "Sumi night"); the camera overlays use the dark values.
