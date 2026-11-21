# Bundled fonts

Shippori Mincho Regular and Zen Kaku Gothic New Regular and Medium, from `google/fonts` under the SIL Open Font License (`OFL-*.txt`).
The files are subsets made with `pyftsubset --layout-features='*' --no-hinting --desubroutinize`.
Shippori Mincho keeps `glyphs-shippori.txt` (every character in the bundled dataset, kana and punctuation). Zen Kaku Gothic New keeps `glyphs-zen.txt` (Latin, kana and punctuation); kanji in interface text fall back to the Japanese-tagged system font.
Re-run the subset after a dataset change that adds characters.
