# Bundled fonts

Shippori Mincho Regular and Zen Kaku Gothic New Regular, Medium and Bold, from `google/fonts` under the SIL Open Font License (`OFL-*.txt`).
The files are subsets made with `pyftsubset --layout-features='*' --no-hinting --desubroutinize`.
Shippori Mincho keeps `glyphs-shippori.txt` (every character in the bundled dataset, kana and punctuation) and draws the serif kanji style. Zen Kaku Gothic New keeps `glyphs-zen.txt` (Latin, kana and punctuation) in all three weights and draws interface text only; kanji in interface text fall back to the Japanese-tagged system font.
The gothic kanji style uses the system Japanese font (Hiragino Sans W3), not a bundled file. Zen Kaku Gothic New with every dataset character is about 2.09 MB per weight, which would put the widget bundle at 11.1 MiB against its 8 MiB budget.
Re-run the subset after a dataset change that adds characters.
