import json
import unittest

import build
import jmdict
import kanjidic
import radicals

SVG = (
    '<svg viewBox="0 0 109 109"><g id="kvg:{h}"><path id="kvg:{h}-s1" d="M1,1"/>'
    '<path id="kvg:{h}-s2" d="M2,2"/></g></svg>'
)


def kanji(literal, grade, strokes=2, freq=None, radical=72):
    return kanjidic.KanjidicEntry(literal, grade, strokes, freq, radical, ["オン"], ["く.る"], [f"meaning of {literal}"])


def word(sequence, headword, tags=(), kana="かな"):
    return jmdict.Word(sequence, headword, kana, "gloss", list(tags))


def make_inputs(**overrides):
    entries = {
        "日": kanji("日", 1, freq=1),
        "月": kanji("月", 1, freq=2),
        "学": kanji("学", 8, freq=300),
        "鬱": kanji("鬱", None),
    }
    svgs = {c: SVG.format(h=f"{ord(c):05x}") for c in entries}
    inputs = build.Inputs(
        kanji=entries,
        waller_levels={"日": "n5", "鬱": "n1"},
        supplement_levels={"月": "n4", "学": "n3"},
        vocabulary_levels={"毎日": "n5"},
        words=[word(1, "毎日", ["ichi1"]), word(2, "日月", ["news2"]), word(3, "日蝕"), word(4, "月日", ["ichi1"])],
        svgs=svgs,
    )
    for key, value in overrides.items():
        setattr(inputs, key, value)
    return inputs


LOCK = {"a.json": {"version": "1", "licence": "L", "sha256": "abc", "url": "http://x"}}


class SelectionTests(unittest.TestCase):
    def test_joyo_plus_n1_extras_are_selected(self):
        self.assertEqual(sorted(build.select_literals(make_inputs())), sorted(["日", "月", "学", "鬱"]))

    def test_extra_outside_n1_fails(self):
        inputs = make_inputs(waller_levels={"日": "n5", "鬱": "n2"})
        with self.assertRaises(build.BuildError):
            build.select_literals(inputs)

    def test_levels_flag_the_supplement(self):
        inputs = make_inputs()
        self.assertEqual(build.assign_level("日", inputs), ("n5", False))
        self.assertEqual(build.assign_level("月", inputs), ("n4", True))
        self.assertEqual(build.assign_level("鬱", inputs), ("n1", False))

    def test_list_order_is_grade_frequency_strokes_codepoint(self):
        inputs = make_inputs()
        order = build.list_order(build.select_literals(inputs), inputs.kanji)
        self.assertEqual(sorted(order, key=order.get), ["日", "月", "学", "鬱"])


class KanjiRangeTests(unittest.TestCase):
    def test_all_han_blocks_and_the_zero_numeral_count(self):
        for char in "日\u3400\ufa11\U00020b9f\u3007":
            self.assertTrue(build.is_kanji(char), char)
        for char in "あアaα々ー":
            self.assertFalse(build.is_kanji(char), char)

    def test_words_with_unbundled_extension_kanji_are_dropped(self):
        words = [word(1, "日𠮟"), word(2, "日〇"), word(3, "日月")]
        self.assertEqual([w.headword for w in build.usable_words(words, {"日", "月"})], ["日月"])


class ExampleTests(unittest.TestCase):
    def test_ranking_caps_at_three_and_prefers_tier_then_level(self):
        words = [word(i, f"日{c}", tags, ) for i, (c, tags) in enumerate([("a", []), ("b", ["news2"]), ("c", ["ichi1"]), ("d", ["ichi1", "nf01"]), ("e", ["ichi1"])], 1)]
        picked = build.pick_examples("日", "n5", {"日": words}, {"日e": "n5"})
        self.assertEqual([w.headword for w in picked], ["日e", "日d", "日c"])

    def test_no_words_gives_empty_list(self):
        self.assertEqual(build.pick_examples("日", "n5", {}, {}), [])

    def test_words_with_unbundled_kanji_are_dropped(self):
        words = [word(1, "日猫"), word(2, "日月")]
        self.assertEqual([w.headword for w in build.usable_words(words, {"日", "月"})], ["日月"])


class GenerateTests(unittest.TestCase):
    def setUp(self):
        self.files = build.generate(make_inputs(), set(), LOCK)

    def test_layout(self):
        self.assertIn("Shared/kanji-index.json", self.files)
        self.assertIn("Shared/DATA-SOURCES.md", self.files)
        self.assertIn("Shared/kanji/065e5.json", self.files)
        self.assertIn("AppOnly/stroke-order/065e5.svg", self.files)
        self.assertIn("AppOnly/words.json", self.files)

    def test_record_keys_match_swift_names(self):
        record = json.loads(self.files["Shared/kanji/065e5.json"])
        self.assertEqual(
            set(record),
            {"id", "meanings", "onyomi", "kunyomi", "radical", "strokeCount", "isJLPTLevelEstimated", "listIndex",
             "exampleWords", "jlptLevel", "joyoGrade", "frequencyRank"},
        )
        self.assertNotIn("strokePaths", record)
        self.assertEqual(record["radical"], {"character": "日", "meaning": "sun"})
        self.assertEqual(record["onyomi"][0]["romaji"], "on")

    def test_nil_fields_are_omitted(self):
        record = json.loads(self.files[f"Shared/kanji/{ord('鬱'):05x}.json"])
        self.assertNotIn("joyoGrade", record)
        self.assertNotIn("frequencyRank", record)
        self.assertEqual(record["jlptLevel"], "n1")

    def test_index_is_ordered_and_carries_frequency(self):
        index = json.loads(self.files["Shared/kanji-index.json"])
        self.assertEqual(index["formatVersion"], 1)
        self.assertEqual([e["id"] for e in index["entries"]], ["日", "月", "学", "鬱"])
        self.assertEqual(index["entries"][0]["frequencyRank"], 1)
        self.assertEqual(index["entries"][0]["primaryReading"], "オン")

    def test_words_json_has_common_words_only(self):
        words = json.loads(self.files["AppOnly/words.json"])
        self.assertEqual(sorted(w["word"] for w in words), ["月日"])

    def test_generation_is_deterministic(self):
        again = build.generate(make_inputs(), set(), LOCK)
        self.assertEqual(self.files, again)

    def test_sources_file_lists_pins_and_attribution(self):
        text = self.files["Shared/DATA-SOURCES.md"]
        self.assertIn("`abc`", text)
        self.assertIn("Jonathan Waller", text)
        self.assertIn("KanjiVG", text)


class GuardTests(unittest.TestCase):
    def test_new_stroke_mismatch_fails_but_allow_listed_passes(self):
        inputs = make_inputs()
        inputs.kanji["日"].stroke_count = 3
        with self.assertRaises(build.BuildError):
            build.generate(inputs, set(), LOCK)
        build.generate(inputs, {"日"}, LOCK)

    def test_missing_svg_fails(self):
        inputs = make_inputs()
        del inputs.svgs["月"]
        with self.assertRaises(build.BuildError):
            build.generate(inputs, set(), LOCK)

    def test_budgets(self):
        build.check_budgets({"Shared/a": "x", "AppOnly/b": "y"})
        with self.assertRaises(build.BuildError):
            build.check_budgets({"Shared/a": "x" * (build.SHARED_BUDGET + 1)})
        with self.assertRaises(build.BuildError):
            build.check_budgets({"Shared/a": "x", "AppOnly/b": "y" * build.APP_BUDGET})


class RadicalTests(unittest.TestCase):
    def test_table_is_complete_and_unique(self):
        self.assertEqual(len(radicals.RADICALS), 214)
        self.assertEqual(len({c for c, _ in radicals.RADICALS}), 214)
        self.assertEqual(radicals.lookup(72), ("日", "sun"))
        self.assertEqual(radicals.lookup(214), ("龠", "flute"))


if __name__ == "__main__":
    unittest.main()
