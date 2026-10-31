"""Pinned upstream inputs. EDRDG files are rolling, so only their hash is recorded."""

KANJIVG_TAG = "r20260714"
OPENJLPT_COMMIT = "0d1d3410bec90bd4098a7c72de820543cb4f707c"
_OPENJLPT_RAW = f"https://raw.githubusercontent.com/evanclan/OpenJLPT/{OPENJLPT_COMMIT}"
LEVELS = ("n5", "n4", "n3", "n2", "n1")

# name -> (url, licence, enforced sha256 or None)
INPUTS = {
    "kanjidic2.xml.gz": ("https://www.edrdg.org/kanjidic/kanjidic2.xml.gz", "CC BY-SA 4.0 (EDRDG)", None),
    "JMdict_e.gz": ("https://www.edrdg.org/pub/Nihongo/JMdict_e.gz", "CC BY-SA 4.0 (EDRDG)", None),
    "kanjivg-main.zip": (
        f"https://github.com/KanjiVG/kanjivg/releases/download/{KANJIVG_TAG}/kanjivg-20260714-main.zip",
        "CC BY-SA 3.0 (KanjiVG)",
        "b5df6cd2bc249dd49b8041eb99e38ba9f8dc6b9ea57962a80084b4a315d1a7fc",
    ),
}

_WALLER_SHA = {
    "kanji": {
        "n1": "a5194d58e9f522bd065c065de5029d262d8580f995a85aca0acb7a7eb304ff3b",
        "n2": "61f83b12bf76f2bec417472ac8171213f43465d2487d9a7a8adf659e6f018a34",
        "n3": "49659ae47992824cc3bf0711efcaf1ca4cfcefc19ce140c20932d42e914ad300",
        "n4": "52b731c4e64f0cfa8260f76696e4e31e9337306c8bf9f38250f2f13305d4cd92",
        "n5": "ed3e37ad2a3ac01093e5eded49a0be44efff227737bc8e9cec06707b0602c6dc",
    },
    "vocab": {
        "n1": "45fda879f81d73a09517267d4f30d21466fa67f98f52b16ad78db04e5bacf27c",
        "n2": "7c14c1a337550f2046d213b132f29e199e97d88aa6663735ce9eb6d2b0551ca7",
        "n3": "adc67d77756583de575e2378f0d3bcc666d064d0d1025f43bf026b60680c3027",
        "n4": "6f0d3696e8314e6d768827b56286570e26c8909c3a1191f1ba583a1d99f35d0f",
        "n5": "a4b868288951a37cd2bdd34173d0dd06848817ae68eb5f036c0c23a3ffdb3df3",
    },
}
_OPENJLPT_KANJI_SHA = {
    "n1": "1814dd4fd4b363854fb861f091c2ca408bac01c96dddb6e9b3a5e2566069a79e",
    "n2": "2e3bd6f9a26d8794aad2dd770b094836bc6c478950202d631e5fb9233e26cc85",
    "n3": "c81669777f0ea37f848105babf8177ab36e968900307e5118b57e4156ed05fef",
    "n4": "a034d51bea0ee6c9ee1cc48b1cc83d9602641b9f5d38d99a55f5136f447a58d8",
    "n5": "c81458831e5e2e807ce0bb81a5af971d493ac8a9243701005eb57fe353990fce",
}

for _level in LEVELS:
    INPUTS[f"waller-kanji-{_level}.json"] = (
        f"{_OPENJLPT_RAW}/sources/waller/kanji-eng-{_level}.json",
        "CC BY (Jonathan Waller)",
        _WALLER_SHA["kanji"][_level],
    )
    INPUTS[f"waller-vocab-{_level}.json"] = (
        f"{_OPENJLPT_RAW}/sources/waller/vocab-eng-{_level}.json",
        "CC BY (Jonathan Waller)",
        _WALLER_SHA["vocab"][_level],
    )
    INPUTS[f"openjlpt-kanji-{_level}.json"] = (
        f"{_OPENJLPT_RAW}/data/json/kanji/{_level}.json",
        "CC BY-SA 4.0 (OpenJLPT)",
        _OPENJLPT_KANJI_SHA[_level],
    )
