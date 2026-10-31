"""Hepburn romaji for KANJIDIC2 and JMdict kana. Reading markers pass through."""

_BASE = {
    "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
    "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
    "さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so",
    "た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
    "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
    "は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
    "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
    "や": "ya", "ゆ": "yu", "よ": "yo",
    "ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro",
    "わ": "wa", "ゐ": "i", "ゑ": "e", "を": "o", "ん": "n",
    "が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go",
    "ざ": "za", "じ": "ji", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
    "だ": "da", "ぢ": "ji", "づ": "zu", "で": "de", "ど": "do",
    "ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",
    "ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po",
    "ゔ": "vu",
    "ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o",
}

_SMALL_Y = {"ゃ": "ya", "ゅ": "yu", "ょ": "yo"}
_YOON_STEM = {
    "き": "ky", "し": "sh", "ち": "ch", "に": "ny", "ひ": "hy", "み": "my",
    "り": "ry", "ぎ": "gy", "じ": "j", "ぢ": "j", "び": "by", "ぴ": "py",
    "ゔ": "vy",
}
_SMALL_VOWEL = {"ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o"}
_FOREIGN = {
    "し": {"ぇ": "she"}, "ち": {"ぇ": "che"}, "じ": {"ぇ": "je"},
    "て": {"ぃ": "ti"}, "で": {"ぃ": "di"}, "と": {"ぅ": "tu"},
    "ど": {"ぅ": "du"}, "ふ": {"ぁ": "fa", "ぃ": "fi", "ぇ": "fe", "ぉ": "fo"},
    "う": {"ぃ": "wi", "ぇ": "we", "ぉ": "wo"}, "ゔ": {"ぁ": "va", "ぃ": "vi", "ぇ": "ve", "ぉ": "vo"},
}
_MACRON = {"a": "ā", "i": "ī", "u": "ū", "e": "ē", "o": "ō"}
_MARKERS = ".-"
_VOWELS = "aiueo"


def to_hiragana(text: str) -> str:
    out = []
    for ch in text:
        code = ord(ch)
        if 0x30A1 <= code <= 0x30F6:
            out.append(chr(code - 0x60))
        else:
            out.append(ch)
    return "".join(out)


def _syllables(kana: str) -> list[tuple[str, str]]:
    """Returns (source kana, romaji) pairs; the source drives long-vowel merging."""
    result: list[tuple[str, str]] = []
    i = 0
    while i < len(kana):
        ch = kana[i]
        nxt = kana[i + 1] if i + 1 < len(kana) else ""
        if ch in _MARKERS:
            result.append((ch, ch))
        elif ch == "ー":
            result.append(("ー", "ー"))
        elif ch == "っ":
            result.append(("っ", "っ"))
        elif nxt in _SMALL_Y and ch in _YOON_STEM:
            stem = _YOON_STEM[ch]
            vowel = _SMALL_Y[nxt][1:]
            romaji = stem + vowel if stem in ("j",) else stem + _SMALL_Y[nxt][1:]
            result.append((ch + nxt, romaji))
            i += 1
        elif nxt in _SMALL_VOWEL and ch in _FOREIGN and nxt in _FOREIGN[ch]:
            result.append((ch + nxt, _FOREIGN[ch][nxt]))
            i += 1
        elif ch in _BASE:
            result.append((ch, _BASE[ch]))
        else:
            result.append((ch, ch))
        i += 1
    return result


def romanize(text: str) -> str:
    kana = to_hiragana(text)
    syllables = _syllables(kana)
    out: list[tuple[str, str]] = []
    for source, romaji in syllables:
        prev = out[-1] if out else None
        if source == "ー" and prev and prev[1] and prev[1][-1] in _VOWELS:
            out[-1] = (prev[0] + source, prev[1][:-1] + _MACRON[prev[1][-1]])
            continue
        if prev and source in ("お", "う", "あ", "え") and prev[1] and prev[1][-1] in _VOWELS:
            last = prev[1][-1]
            joins = (
                (last == "o" and source in ("お", "う"))
                or (last == "u" and source == "う")
                or (last == "a" and source == "あ")
                or (last == "e" and source == "え")
            )
            if joins and not prev[0].endswith(("ー",)) and prev[1][-1] != "ō" and prev[1][-1] in _VOWELS:
                out[-1] = (prev[0] + source, prev[1][:-1] + _MACRON[last])
                continue
        out.append((source, romaji))
    pieces: list[str] = []
    for index, (source, romaji) in enumerate(out):
        if source == "っ":
            follower = out[index + 1][1] if index + 1 < len(out) else ""
            if follower.startswith("ch"):
                pieces.append("t")
            elif follower and follower[0] not in _VOWELS + _MARKERS:
                pieces.append(follower[0])
            continue
        if source == "ん" and index + 1 < len(out):
            follower = out[index + 1][1]
            if follower and (follower[0] in _VOWELS or follower[0] == "y"):
                pieces.append("n'")
                continue
        pieces.append(romaji)
    return "".join(pieces)
