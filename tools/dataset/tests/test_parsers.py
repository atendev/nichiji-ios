import gzip
import tempfile
import unittest
from pathlib import Path

import jlpt
import jmdict
import kanjidic
import kanjivg

KANJIDIC = """<?xml version="1.0"?>
<kanjidic2>
<header><database_version>2026-001</database_version></header>
<character><literal>日</literal><radical><rad_value rad_type="classical">72</rad_value></radical>
<misc><grade>1</grade><stroke_count>4</stroke_count><freq>1</freq><jlpt>4</jlpt></misc>
<reading_meaning><rmgroup><reading r_type="ja_on">ニチ</reading><reading r_type="ja_kun">ひ</reading>
<meaning>day</meaning><meaning m_lang="fr">jour</meaning></rmgroup><nanori>あ</nanori></reading_meaning></character>
<character><literal>鬱</literal><radical><rad_value rad_type="classical">192</rad_value></radical>
<misc><grade>9</grade><stroke_count>29</stroke_count></misc></character>
<character><literal>学</literal><radical><rad_value rad_type="classical">39</rad_value></radical>
<misc><grade>8</grade><stroke_count>8</stroke_count></misc></character>
</kanjidic2>""".encode()

JMDICT = """<?xml version="1.0"?>
<!DOCTYPE JMdict [
<!ENTITY sK "search-only kanji form">
<!ENTITY iK "word containing irregular kanji usage">
<!ENTITY oK "word containing out-dated kanji or kanji usage">
<!ENTITY rK "rarely-used kanji form">
<!ENTITY n "noun (common) (futsuumeishi)">
]>
<JMdict>
<entry><ent_seq>100</ent_seq>
<k_ele><keb>毎日</keb><ke_pri>ichi1</ke_pri><ke_pri>nf02</ke_pri></k_ele>
<k_ele><keb>每日</keb><ke_inf>&oK;</ke_inf></k_ele>
<k_ele><keb>日1</keb></k_ele>
<k_ele><keb>α日</keb></k_ele>
<r_ele><reb>まいにち</reb><re_pri>ichi1</re_pri></r_ele>
<sense><pos>&n;</pos><gloss>every day</gloss><gloss>daily</gloss><gloss>each day</gloss><gloss>extra</gloss></sense></entry>
<entry><ent_seq>200</ent_seq>
<k_ele><keb>日向</keb><ke_inf>&sK;</ke_inf></k_ele><k_ele><keb>陽向</keb></k_ele>
<r_ele><reb>ひなた</reb></r_ele><r_ele><reb>ひむかい</reb><re_restr>日向</re_restr></r_ele>
<sense><gloss>sunny place</gloss></sense></entry>
<entry><ent_seq>300</ent_seq><r_ele><reb>ありがとう</reb></r_ele><sense><gloss>thanks</gloss></sense></entry>
</JMdict>""".encode()

SVG = """<?xml version="1.0"?>
<!-- licence header -->
<svg xmlns="http://www.w3.org/2000/svg" width="109" height="109" viewBox="0 0 109 109">
<g id="kvg:StrokePaths_065e5"><g id="kvg:065e5" kvg:element="日">
<path id="kvg:065e5-s1" kvg:type="㇑" d="M1,1c1,1"/>
<path id="kvg:065e5-s2" kvg:type="㇐" d="M2,2c2,2"/>
</g></g><g id="kvg:StrokeNumbers_065e5"><text>1</text></g></svg>"""


class KanjidicTests(unittest.TestCase):
    def test_fields_and_grades(self):
        version, entries = kanjidic.parse(KANJIDIC)
        self.assertEqual(version, "2026-001")
        day = entries["日"]
        self.assertEqual((day.grade, day.stroke_count, day.frequency, day.radical), (1, 4, 1, 72))
        self.assertEqual(day.onyomi, ["ニチ"])
        self.assertEqual(day.kunyomi, ["ひ"])
        self.assertEqual(day.meanings, ["day"])
        self.assertIsNone(entries["鬱"].frequency)
        self.assertEqual(kanjidic.GRADE_NAMES[entries["学"].grade], "secondary")
        self.assertNotIn(entries["鬱"].grade, kanjidic.GRADE_NAMES)

    def test_reads_gzip(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "k.gz"
            path.write_bytes(gzip.compress(KANJIDIC))
            self.assertEqual(kanjidic.read_text(path), KANJIDIC)


class JMdictTests(unittest.TestCase):
    def setUp(self):
        self.words = list(jmdict.parse(JMDICT))

    def test_excluded_and_latin_forms_are_skipped(self):
        self.assertEqual(sorted(w.headword for w in self.words), ["毎日", "陽向"])

    def test_priority_tiers_and_nf_band(self):
        word = next(w for w in self.words if w.headword == "毎日")
        self.assertEqual((word.tier, word.nf_band, word.sequence), (0, 2, 100))
        self.assertEqual(next(w for w in self.words if w.headword == "陽向").tier, 2)

    def test_gloss_cap_and_reading_restriction(self):
        word = next(w for w in self.words if w.headword == "毎日")
        self.assertEqual(word.meaning, "every day, daily, each day")
        other = next(w for w in self.words if w.headword == "陽向")
        self.assertEqual(other.kana, "ひなた")

    def test_kana_only_entries_are_skipped(self):
        self.assertFalse(any(w.sequence == 300 for w in self.words))


class KanjiVGTests(unittest.TestCase):
    def test_minify_keeps_ordered_paths_only(self):
        out = kanjivg.minify(SVG)
        self.assertIn('<path d="M1,1c1,1"/><path d="M2,2c2,2"/>', out)
        self.assertNotIn("licence", out)
        self.assertNotIn("<text", out)

    def test_validate_flags_bad_files(self):
        self.assertEqual(kanjivg.validate("日", SVG.replace("065e5", "065e5")), [])
        self.assertTrue(kanjivg.validate("月", SVG))
        self.assertTrue(kanjivg.validate("日", "<svg/>"))

    def test_stroke_count(self):
        self.assertEqual(kanjivg.stroke_count(SVG), 2)


class JLPTTests(unittest.TestCase):
    def test_levels(self):
        files = {
            "waller-kanji-n5.json": [{"front": "日", "back": "day"}],
            "waller-kanji-n1.json": [{"front": "鬱", "back": "gloom"}],
            "openjlpt-kanji-n3.json": [{"character": "分", "supplementary": True}, {"character": "日"}],
            "waller-vocab-n5.json": [{"front": "毎日/まいにち", "back": "daily"}],
        }
        read = lambda name: files.get(name, [])
        self.assertEqual(jlpt.load_waller_kanji(read), {"日": "n5", "鬱": "n1"})
        self.assertEqual(jlpt.load_supplement(read), {"分": "n3"})
        self.assertEqual(jlpt.load_vocabulary_levels(read)["毎日"], "n5")


if __name__ == "__main__":
    unittest.main()
