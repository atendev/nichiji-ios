"""Waller N-levels (via the pinned OpenJLPT snapshot) and the OpenJLPT supplement."""

LEVELS = ("n5", "n4", "n3", "n2", "n1")


def load_waller_kanji(read) -> dict[str, str]:
    """read(name) returns the parsed JSON for a cached input name."""
    mapping = {}
    for level in LEVELS:
        for item in read(f"waller-kanji-{level}.json"):
            mapping[item["front"]] = level
    return mapping


def load_supplement(read) -> dict[str, str]:
    """OpenJLPT levels for kanji Waller does not list, keyed to its `supplementary` flag."""
    mapping = {}
    for level in LEVELS:
        for item in read(f"openjlpt-kanji-{level}.json"):
            if item.get("supplementary"):
                mapping[item["character"]] = level
    return mapping


def load_vocabulary_levels(read) -> dict[str, str]:
    """Easiest Waller vocabulary level for each headword, split on '/' variants."""
    mapping = {}
    for level in LEVELS:
        for item in read(f"waller-vocab-{level}.json"):
            for form in item["front"].split("/"):
                mapping.setdefault(form, level)
    return mapping
