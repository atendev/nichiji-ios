import json
import unittest

import build
import jmdict
import kanjidic
import radicals
import sources

SVG = (
    '<svg viewBox="0 0 109 109"><g id="kvg:{h}"><path id="kvg:{h}-s1" d="M1,1"/>'
    '<path id="kvg:{h}-s2" d="M2,2"/></g></svg>'
)


def kanji(literal, grade, strokes=2, freq=None, radical=72, jis208=False):
    return kanjidic.KanjidicEntry(literal, grade, strokes, freq, radical, ["オン"], ["く.る"], [f"meaning of {literal}"], jis208)


def word(sequence, headword, tags=(), kana="かな"):
    return jmdict.Word(sequence, headword, kana, "gloss", list(tags))


def make_inputs(**overrides):
    entries = {
        "日": kanji("日", 1, freq=1),
        "月": kanji("月", 1, freq=2),
        "学": kanji("学", 8, freq=300),
        "鬱": kanji("鬱", 9),
        "鮪": kanji("鮪", None, jis208=True),
        "鰯": kanji("鰯", None, strokes=2, freq=900, jis208=True),
        "𠮟": kanji("𠮟", None),
    }
    svgs = {c: SVG.format(h=f"{ord(c):05x}") for c in entries if c != "鰯"}
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


def lock_entry(version):
    return {"version": version, "licence": "L", "sha256": "abc", "url": "http://x"}


LOCK = {
    "kanjidic2.xml.gz": lock_entry("2026-304"),
    "JMdict_e.gz": lock_entry("2026-10-31"),
    "kanjivg-main.zip": lock_entry("r20260714"),
    "waller-kanji-n1.json": lock_entry("0d1d3410bec90bd4098a7c72de820543cb4f707c"),
}


class SelectionTests(unittest.TestCase):
    def test_joyo_jinmeiyo_and_jis_kanji_are_selected_and_others_left_out(self):
        self.assertEqual(sorted(build.select_literals(make_inputs())), sorted(["日", "月", "学", "鬱", "鮪", "鰯"]))

    def test_waller_listed_kanji_outside_the_sets_are_kept(self):
        inputs = make_inputs(waller_levels={"日": "n5", "鬱": "n1", "𠮟": "n1"})
        self.assertIn("𠮟", build.select_literals(inputs))

    def test_compatibility_ideographs_fold_into_their_unified_twin(self):
        inputs = make_inputs()
        inputs.kanji["\ufa30"] = kanji("\ufa30", 9)
        inputs.kanji["\u4fae"] = kanji("\u4fae", None, jis208=True)
        chosen = build.select_literals(inputs)
        self.assertIn("\u4fae", chosen)
        self.assertNotIn("\ufa30", chosen)

    def test_compatibility_ideograph_without_a_twin_fails(self):
        inputs = make_inputs()
        inputs.kanji["\ufa30"] = kanji("\ufa30", 9)
        with self.assertRaises(build.BuildError):
            build.select_literals(inputs)

    def test_waller_kanji_missing_from_kanjidic_fails(self):
        inputs = make_inputs(waller_levels={"日": "n5", "猫": "n1"})
        with self.assertRaises(build.BuildError):
            build.select_literals(inputs)

    def test_classification_follows_grade(self):
        inputs = make_inputs()
        got = {c: build.classify(inputs.kanji[c]) for c in ("日", "学", "鬱", "鮪")}
        self.assertEqual(got, {"日": "joyo", "学": "joyo", "鬱": "jinmeiyo", "鮪": "hyogai"})

    def test_extra_outside_n1_fails(self):
        inputs = make_inputs(waller_levels={"日": "n5", "鬱": "n2"})
        with self.assertRaises(build.BuildError):
            build.select_literals(inputs)

    def test_levels_flag_the_supplement(self):
        inputs = make_inputs()
        self.assertEqual(build.assign_level("日", inputs), ("n5", False))
        self.assertEqual(build.assign_level("月", inputs), ("n4", True))
        self.assertEqual(build.assign_level("鬱", inputs), ("n1", False))

    def test_supplement_levels_apply_to_joyo_kanji_only(self):
        inputs = make_inputs(supplement_levels={"月": "n4", "鮪": "n2", "鬱": "n2"}, waller_levels={"日": "n5"})
        self.assertEqual(build.assign_level("鮪", inputs), (None, False))
        self.assertEqual(build.assign_level("鬱", inputs), (None, False))
        self.assertEqual(build.assign_level("月", inputs), ("n4", True))

    def test_list_order_is_frequency_then_common_words_then_strokes_then_codepoint(self):
        inputs = make_inputs()
        counts = {"鬱": 5, "鮪": 5}
        order = build.list_order(build.select_literals(inputs), inputs.kanji, counts)
        # Ranked kanji come first by frequency. The unranked 鬱 and 鮪 tie on common words and strokes, so code point decides.
        self.assertEqual(sorted(order, key=order.get), ["日", "月", "学", "鰯", "鬱", "鮪"])

    def test_more_common_words_beat_fewer_strokes_and_code_point_breaks_ties(self):
        entries = {c: kanji(c, None, strokes=s, jis208=True) for c, s in (("亜", 7), ("唖", 10), ("娃", 9), ("阿", 8))}
        order = build.list_order(list(entries), entries, {"唖": 3, "娃": 3, "阿": 1})
        self.assertEqual(sorted(order, key=order.get), ["娃", "唖", "阿", "亜"])


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
        self.assertIn("AppOnly/kanji-search.json", self.files)

    def test_record_keys_match_swift_names(self):
        record = json.loads(self.files["Shared/kanji/065e5.json"])
        self.assertEqual(
            set(record),
            {"id", "meanings", "onyomi", "kunyomi", "radical", "strokeCount", "isJLPTLevelEstimated", "listIndex",
             "exampleWords", "jlptLevel", "joyoGrade", "frequencyRank", "classification"},
        )
        self.assertNotIn("strokePaths", record)
        self.assertEqual(record["radical"], {"character": "日", "meaning": "sun"})
        self.assertEqual(record["onyomi"][0]["romaji"], "on")
        self.assertEqual(record["classification"], "joyo")

    def test_every_record_and_index_entry_carries_its_classification(self):
        index = {e["id"]: e for e in json.loads(self.files["Shared/kanji-index.json"])["entries"]}
        self.assertEqual({c: e["classification"] for c, e in index.items()}, {"日": "joyo", "月": "joyo", "学": "joyo", "鬱": "jinmeiyo", "鮪": "hyogai", "鰯": "hyogai"})
        record = json.loads(self.files[f"Shared/kanji/{ord('鮪'):05x}.json"])
        self.assertEqual(record["classification"], "hyogai")
        self.assertNotIn("joyoGrade", record)
        self.assertNotIn("jlptLevel", record)

    def test_kanji_without_a_kanjivg_file_ship_no_stroke_order(self):
        self.assertNotIn(f"AppOnly/stroke-order/{ord('鰯'):05x}.svg", self.files)
        self.assertIn(f"Shared/kanji/{ord('鰯'):05x}.json", self.files)
        self.assertIn(f"AppOnly/stroke-order/{ord('鮪'):05x}.svg", self.files)

    def test_nil_fields_are_omitted(self):
        record = json.loads(self.files[f"Shared/kanji/{ord('鬱'):05x}.json"])
        self.assertNotIn("joyoGrade", record)
        self.assertNotIn("frequencyRank", record)
        self.assertEqual(record["jlptLevel"], "n1")

    def test_index_is_ordered_and_carries_frequency(self):
        index = json.loads(self.files["Shared/kanji-index.json"])
        self.assertEqual(index["formatVersion"], 1)
        self.assertEqual([e["id"] for e in index["entries"]], ["日", "月", "学", "鰯", "鬱", "鮪"])
        self.assertEqual(index["entries"][0]["frequencyRank"], 1)
        self.assertEqual(index["entries"][0]["primaryReading"], "オン")

    def test_words_json_has_common_words_only(self):
        words = json.loads(self.files["AppOnly/words.json"])
        self.assertEqual(sorted(w["word"] for w in words), ["月日"])

    def test_words_json_carries_rank(self):
        words = json.loads(self.files["AppOnly/words.json"])
        self.assertEqual(set(words[0]), {"id", "word", "kana", "romaji", "meaning", "rank"})
        self.assertEqual(words[0]["rank"], 53)

    def test_kanji_search_has_full_readings_and_meanings_in_code_point_order(self):
        search = json.loads(self.files["AppOnly/kanji-search.json"])
        self.assertEqual([e["id"] for e in search], ["学", "日", "月", "鬱", "鮪", "鰯"])
        search = sorted(search, key=lambda e: e["id"] != "日")
        self.assertEqual(set(search[0]), {"id", "meanings", "onyomi", "kunyomi"})
        self.assertEqual(search[0]["meanings"], ["meaning of 日"])
        self.assertEqual(search[0]["onyomi"], [{"kind": "onyomi", "kana": "オン", "romaji": "on"}])
        self.assertEqual(search[0]["kunyomi"][0]["kana"], "く.る")
        self.assertEqual(search[0]["kunyomi"][0]["romaji"], "ku.ru")

    def test_generation_is_deterministic(self):
        again = build.generate(make_inputs(), set(), LOCK)
        self.assertEqual(self.files, again)

    def test_sources_file_lists_pins_and_attribution(self):
        text = self.files["Shared/DATA-SOURCES.md"]
        self.assertIn("`abc`", text)
        self.assertIn("Jonathan Waller", text)
        self.assertIn("KanjiVG", text)

    def test_sources_file_links_each_title_to_its_page(self):
        text = self.files["Shared/DATA-SOURCES.md"]
        for link in (
            "[Electronic Dictionary Research and Development Group](https://www.edrdg.org)",
            "[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)",
            "[EDRDG licence](https://www.edrdg.org/edrdg/licence.html)",
            "[KanjiVG](https://kanjivg.tagaini.net)",
            "[CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/)",
            "[Jonathan Waller's JLPT Resources](https://www.tanos.co.uk/jlpt/)",
            "[CC BY](https://www.tanos.co.uk/jlpt/sharing/)",
            "[OpenJLPT](https://github.com/evanclan/OpenJLPT)",
        ):
            self.assertIn(link, text)
        self.assertIn("vocabulary lists", text)
        self.assertNotIn("has not published official kanji lists", text)
        self.assertNotIn("isJLPTLevelEstimated", text)

    def test_sources_file_counts_estimated_levels_from_the_records(self):
        records = [json.loads(text) for path, text in self.files.items() if path.startswith("Shared/kanji/")]
        estimated = sum(1 for record in records if record["isJLPTLevelEstimated"])
        self.assertEqual(estimated, 2)
        self.assertIn(f"Levels for {estimated} Jōyō kanji not in those lists", self.files["Shared/DATA-SOURCES.md"])

    def test_sources_file_counts_each_level(self):
        text = self.files["Shared/DATA-SOURCES.md"]
        self.assertIn("The bundle holds 6 kanji (3 Jōyō, 1 Jinmeiyō, 2 Hyōgai) and 1 common words", text)

    def test_sources_file_dates_each_snapshot(self):
        text = self.files["Shared/DATA-SOURCES.md"]
        self.assertIn("## Snapshots", text)
        self.assertIn("- KANJIDIC2: 2026-10-31 (database version 2026-304)", text)
        self.assertIn("- JMdict: 2026-10-31", text)
        self.assertIn("- KanjiVG: 2026-07-14 (release r20260714)", text)
        self.assertIn(f"- Jonathan Waller's lists and OpenJLPT: {sources.OPENJLPT_COMMIT_DATE} (OpenJLPT commit 0d1d341)", text)

    def test_sources_file_needs_every_snapshot_in_the_lock(self):
        lock = dict(LOCK)
        del lock["kanjivg-main.zip"]
        with self.assertRaises(build.BuildError):
            build.generate(make_inputs(), set(), lock)

    def test_out_of_range_day_of_year_fails(self):
        for version in ("2026-000", "2026-366", "2026-400"):
            lock = dict(LOCK, **{"kanjidic2.xml.gz": lock_entry(version)})
            with self.assertRaises(build.BuildError):
                build.generate(make_inputs(), set(), lock)

    def test_unreadable_snapshot_version_fails(self):
        lock = dict(LOCK, **{"JMdict_e.gz": lock_entry("latest")})
        with self.assertRaises(build.BuildError):
            build.generate(make_inputs(), set(), lock)


class GuardTests(unittest.TestCase):
    def test_new_stroke_mismatch_fails_but_allow_listed_passes(self):
        inputs = make_inputs()
        inputs.kanji["日"].stroke_count = 3
        with self.assertRaises(build.BuildError):
            build.generate(inputs, set(), LOCK)
        build.generate(inputs, {"日"}, LOCK)

    def test_missing_svg_fails_for_joyo_only(self):
        inputs = make_inputs()
        del inputs.svgs["月"]
        with self.assertRaises(build.BuildError):
            build.generate(inputs, set(), LOCK)
        inputs = make_inputs()
        del inputs.svgs["鬱"]
        build.generate(inputs, set(), LOCK)

    def test_stroke_check_skips_kanji_without_a_file(self):
        inputs = make_inputs()
        inputs.kanji["鰯"].stroke_count = 30
        build.generate(inputs, set(), LOCK)

    def test_budget_limits_are_8_and_24_mb(self):
        self.assertEqual((build.SHARED_BUDGET, build.APP_BUDGET), (8 * 1024 * 1024, 24 * 1024 * 1024))

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
