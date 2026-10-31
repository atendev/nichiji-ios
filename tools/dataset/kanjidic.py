"""KANJIDIC2 parser. Keeps only the fields the bundle uses."""

import gzip
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field

# KANJIDIC2 grades 1-6 are the school grades, 8 is the rest of the Joyo set.
GRADE_NAMES = {1: "grade1", 2: "grade2", 3: "grade3", 4: "grade4", 5: "grade5", 6: "grade6", 8: "secondary"}


@dataclass
class KanjidicEntry:
    literal: str
    grade: int | None
    stroke_count: int
    frequency: int | None
    radical: int
    onyomi: list[str] = field(default_factory=list)
    kunyomi: list[str] = field(default_factory=list)
    meanings: list[str] = field(default_factory=list)


def read_text(path) -> bytes:
    data = path.read_bytes()
    return gzip.decompress(data) if data[:2] == b"\x1f\x8b" else data


def parse(data: bytes) -> tuple[str, dict[str, KanjidicEntry]]:
    root = ET.fromstring(data)
    version = root.findtext("header/database_version") or ""
    entries: dict[str, KanjidicEntry] = {}
    for node in root.iter("character"):
        literal = node.findtext("literal")
        grade = node.findtext("misc/grade")
        freq = node.findtext("misc/freq")
        radical = node.find("radical/rad_value[@rad_type='classical']")
        entry = KanjidicEntry(
            literal=literal,
            grade=int(grade) if grade else None,
            stroke_count=int(node.findtext("misc/stroke_count")),
            frequency=int(freq) if freq else None,
            radical=int(radical.text),
        )
        for reading in node.iterfind("reading_meaning/rmgroup/reading"):
            kind = reading.get("r_type")
            if kind == "ja_on":
                entry.onyomi.append(reading.text)
            elif kind == "ja_kun":
                entry.kunyomi.append(reading.text)
        for meaning in node.iterfind("reading_meaning/rmgroup/meaning"):
            if meaning.get("m_lang") in (None, "en"):
                entry.meanings.append(meaning.text)
        entries[literal] = entry
    return version, entries
