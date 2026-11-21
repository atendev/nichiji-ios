# Bundled fonts

Shippori Mincho Regular and Zen Kaku Gothic New Regular, Medium and Bold, from `google/fonts` under the SIL Open Font License (`OFL-*.txt`).
The files are subsets made with `pyftsubset --layout-features='*' --no-hinting --desubroutinize`.
Shippori Mincho and Zen Kaku Gothic New Regular keep `glyphs-shippori.txt` (every character in the bundled dataset, kana and punctuation), so both can draw the big kanji; the learner's kanji style picks one. Zen Kaku Gothic New has no glyph for 46 rare or old-form kanji in that list (`BundledFontsTests` pins them); they fall back to the Japanese-tagged system font.
Zen Kaku Gothic New Medium and Bold keep `glyphs-zen.txt` (Latin, kana and punctuation) and draw interface text only. Kanji in interface text fall back to the Japanese-tagged system font.
Two files cannot share a PostScript name, so the kanji-bearing Regular is also the interface Regular.
Re-run the subset after a dataset change that adds characters.
