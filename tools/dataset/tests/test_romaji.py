import unittest

from romaji import romanize


class RomanizeTests(unittest.TestCase):
    def test_basic_and_katakana(self):
        self.assertEqual(romanize("ニチ"), "nichi")
        self.assertEqual(romanize("ジツ"), "jitsu")
        self.assertEqual(romanize("ひ"), "hi")

    def test_long_vowels(self):
        self.assertEqual(romanize("きょう"), "kyō")
        self.assertEqual(romanize("とうきょう"), "tōkyō")
        self.assertEqual(romanize("おおきい"), "ōkii")
        self.assertEqual(romanize("ゆうびん"), "yūbin")
        self.assertEqual(romanize("ラーメン"), "rāmen")
        self.assertEqual(romanize("ええ"), "ē")

    def test_small_kana_and_sokuon(self):
        self.assertEqual(romanize("ちょっと"), "chotto")
        self.assertEqual(romanize("ざっし"), "zasshi")
        self.assertEqual(romanize("まっちゃ"), "matcha")
        self.assertEqual(romanize("じゃ"), "ja")
        self.assertEqual(romanize("シェフ"), "shefu")
        self.assertEqual(romanize("ファイル"), "fairu")

    def test_n_before_vowel_or_y(self):
        self.assertEqual(romanize("こんや"), "kon'ya")
        self.assertEqual(romanize("ほんい"), "hon'i")
        self.assertEqual(romanize("さんぽ"), "sanpo")

    def test_reading_markers_pass_through(self):
        self.assertEqual(romanize("た.べる"), "ta.beru")
        self.assertEqual(romanize("-び"), "-bi")
        self.assertEqual(romanize("お.う"), "o.u")

    def test_separate_morphemes_do_not_merge(self):
        self.assertEqual(romanize("お.おう"), "o.ō")


if __name__ == "__main__":
    unittest.main()
