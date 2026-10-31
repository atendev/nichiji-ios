"""JMdict parser and example-word selection."""

import gzip
import re
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field

EXCLUDED_KANJI_INFO = ("sK", "iK", "oK", "rK")
COMMON_TAGS = ("news1", "ichi1", "spec1", "gai1")
SECOND_TAGS = ("news2", "ichi2", "spec2", "gai2")
_HAS_LATIN_OR_DIGIT = re.compile(r"[0-9A-Za-z＀-｟Ͱ-Ͽ]")


@dataclass
class Word:
    sequence: int
    headword: str
    kana: str
    meaning: str
    priority: list[str] = field(default_factory=list)

    @property
    def tier(self) -> int:
        if any(tag in COMMON_TAGS for tag in self.priority):
            return 0
        if any(tag in SECOND_TAGS for tag in self.priority):
            return 1
        return 2

    @property
    def is_common(self) -> bool:
        return self.tier == 0

    @property
    def nf_band(self) -> int:
        bands = [int(tag[2:]) for tag in self.priority if re.fullmatch(r"nf\d+", tag)]
        return min(bands) if bands else 99


def open_text(path) -> bytes:
    data = path.read_bytes()
    return gzip.decompress(data) if data[:2] == b"\x1f\x8b" else data


def entity_texts(data: bytes) -> dict[str, str]:
    header = data[: data.find(b"]>") + 2].decode("utf-8")
    return dict(re.findall(r'<!ENTITY\s+(\S+)\s+"([^"]*)">', header))


def parse(data: bytes):
    """Yields one Word per usable kanji headword. Entities expand to their text."""
    entities = entity_texts(data)
    excluded = {entities[name] for name in EXCLUDED_KANJI_INFO if name in entities}
    for _, node in ET.iterparse(_Stream(data), events=("end",)):
        if node.tag != "entry":
            continue
        yield from _words(node, excluded)
        node.clear()


class _Stream:
    def __init__(self, data: bytes):
        self._data = data
        self._offset = 0

    def read(self, size: int = -1) -> bytes:
        chunk = self._data[self._offset : self._offset + (size if size > 0 else len(self._data))]
        self._offset += len(chunk)
        return chunk


def _words(entry, excluded: set[str]):
    sequence = int(entry.findtext("ent_seq"))
    readings = []
    for node in entry.iterfind("r_ele"):
        if node.find("re_nokanji") is not None:
            continue
        readings.append(
            (
                node.findtext("reb"),
                [r.text for r in node.iterfind("re_restr")],
                [p.text for p in node.iterfind("re_pri")],
            )
        )
    sense = entry.find("sense")
    glosses = [g.text for g in sense.iterfind("gloss") if g.get("{http://www.w3.org/XML/1998/namespace}lang") in (None, "eng")] if sense is not None else []
    if not readings or not glosses:
        return
    meaning = ", ".join(glosses[:3])
    for node in entry.iterfind("k_ele"):
        headword = node.findtext("keb")
        if any(info.text in excluded for info in node.iterfind("ke_inf")):
            continue
        if _HAS_LATIN_OR_DIGIT.search(headword):
            continue
        fitting = [r for r in readings if not r[1] or headword in r[1]]
        if not fitting:
            continue
        kana, _, reading_priority = fitting[0]
        priority = [p.text for p in node.iterfind("ke_pri")]
        priority += reading_priority
        yield Word(sequence, headword, kana, meaning, sorted(set(priority)))
