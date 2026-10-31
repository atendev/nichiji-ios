"""Joins the parsed inputs into the committed Dataset/ bundle. Offline and deterministic."""

import json
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

import fetch
import jlpt
import jmdict
import kanjidic
import kanjivg
import radicals
import romaji
import sources

HERE = Path(__file__).parent
ROOT = HERE.parent.parent
ALLOWLIST = HERE / "strokecount-allowlist.json"
SHARED_BUDGET = 3 * 1024 * 1024
APP_BUDGET = 8 * 1024 * 1024
MAX_EXAMPLES = 3
LEVEL_RANK = {level: index for index, level in enumerate(sources.LEVELS)}
JOYO_GRADES = set(kanjidic.GRADE_NAMES)


@dataclass
class Inputs:
    kanji: dict[str, kanjidic.KanjidicEntry]
    waller_levels: dict[str, str]
    supplement_levels: dict[str, str]
    vocabulary_levels: dict[str, str]
    words: list[jmdict.Word]
    svgs: dict[str, str]


class BuildError(Exception):
    pass


def is_kanji(char: str) -> bool:
    """Han ideographs across every block, plus the numeral zero 〇, which has no record."""
    code = ord(char)
    return (
        0x3400 <= code <= 0x4DBF
        or 0x4E00 <= code <= 0x9FFF
        or 0xF900 <= code <= 0xFAFF
        or 0x20000 <= code <= 0x2FA1F
        or code == 0x3007
    )


def select_literals(inputs: Inputs) -> list[str]:
    joyo = {c for c, e in inputs.kanji.items() if e.grade in JOYO_GRADES}
    extra = {c for c, level in inputs.waller_levels.items() if c not in joyo}
    stray = {c for c in extra if inputs.waller_levels[c] != "n1"}
    if stray:
        raise BuildError(f"non-Joyo kanji outside N1: {''.join(sorted(stray))}")
    missing = (joyo | extra) - set(inputs.kanji)
    if missing:
        raise BuildError(f"not in KANJIDIC2: {''.join(sorted(missing))}")
    return sorted(joyo | extra, key=ord)


def assign_level(literal: str, inputs: Inputs) -> tuple[str | None, bool]:
    if literal in inputs.waller_levels:
        return inputs.waller_levels[literal], False
    if literal in inputs.supplement_levels:
        return inputs.supplement_levels[literal], True
    return None, False


def list_order(literals: list[str], kanji: dict[str, kanjidic.KanjidicEntry]) -> dict[str, int]:
    def key(literal: str):
        entry = kanji[literal]
        grade = 7 if entry.grade == 8 else (entry.grade or 99)
        return (grade, entry.frequency or 10**6, entry.stroke_count, ord(literal))

    return {literal: index for index, literal in enumerate(sorted(literals, key=key))}


def usable_words(words: list[jmdict.Word], bundle: set[str]) -> list[jmdict.Word]:
    return [w for w in words if all(not is_kanji(c) or c in bundle for c in w.headword)]


def pick_examples(literal: str, level: str | None, words_by_kanji, vocabulary_levels) -> list[jmdict.Word]:
    def preferred(word: jmdict.Word) -> int:
        word_level = vocabulary_levels.get(word.headword)
        if level and word_level and LEVEL_RANK[word_level] <= LEVEL_RANK[level]:
            return 0
        return 1

    candidates = sorted(
        words_by_kanji.get(literal, []),
        key=lambda w: (w.tier, preferred(w), w.nf_band, w.sequence, w.headword),
    )
    chosen, seen = [], set()
    for word in candidates:
        if word.headword in seen:
            continue
        seen.add(word.headword)
        chosen.append(word)
        if len(chosen) == MAX_EXAMPLES:
            break
    return chosen


def word_record(word: jmdict.Word) -> dict:
    return {
        "id": f"{word.sequence}:{word.headword}",
        "word": word.headword,
        "kana": word.kana,
        "romaji": romaji.romanize(word.kana),
        "meaning": word.meaning,
    }


def readings(kind: str, values: list[str]) -> list[dict]:
    return [{"kind": kind, "kana": value, "romaji": romaji.romanize(value)} for value in values]


def check_stroke_counts(inputs: Inputs, literals: list[str], allowlist: set[str]) -> None:
    missing = [c for c in literals if c not in inputs.svgs]
    if missing:
        raise BuildError(f"no KanjiVG file for: {''.join(missing)}")
    problems = [p for c in literals for p in kanjivg.validate(c, inputs.svgs[c])]
    mismatched = {c for c in literals if kanjivg.stroke_count(inputs.svgs[c]) != inputs.kanji[c].stroke_count}
    new = sorted(mismatched - allowlist)
    if new:
        details = ", ".join(
            f"{c} (KANJIDIC2 {inputs.kanji[c].stroke_count}, KanjiVG {kanjivg.stroke_count(inputs.svgs[c])})" for c in new
        )
        problems.append(f"new stroke-count mismatches: {details}")
    if problems:
        raise BuildError("; ".join(problems))


def dump(value) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n"


def generate(inputs: Inputs, allowlist: set[str], lock: dict) -> dict[str, str]:
    """Returns relative output path -> text, with every path under Shared/ or AppOnly/."""
    literals = select_literals(inputs)
    check_stroke_counts(inputs, literals, allowlist)
    bundle = set(literals)
    usable = usable_words(inputs.words, bundle)
    words_by_kanji: dict[str, list[jmdict.Word]] = {}
    for word in usable:
        for char in set(word.headword):
            if char in bundle:
                words_by_kanji.setdefault(char, []).append(word)
    order = list_order(literals, inputs.kanji)
    files: dict[str, str] = {}
    index = []
    for literal in literals:
        entry = inputs.kanji[literal]
        level, estimated = assign_level(literal, inputs)
        radical_character, radical_name = radicals.lookup(entry.radical)
        record = {
            "id": literal,
            "meanings": entry.meanings,
            "onyomi": readings("onyomi", entry.onyomi),
            "kunyomi": readings("kunyomi", entry.kunyomi),
            "radical": {"character": radical_character, "meaning": radical_name},
            "strokeCount": entry.stroke_count,
            "isJLPTLevelEstimated": estimated,
            "listIndex": order[literal],
            "exampleWords": [word_record(w) for w in pick_examples(literal, level, words_by_kanji, inputs.vocabulary_levels)],
        }
        optional = {
            "jlptLevel": level,
            "joyoGrade": kanjidic.GRADE_NAMES.get(entry.grade),
            "frequencyRank": entry.frequency,
        }
        record.update({k: v for k, v in optional.items() if v is not None})
        files[f"Shared/kanji/{kanjivg.hex_name(literal)}.json"] = dump(record)
        files[f"AppOnly/stroke-order/{kanjivg.hex_name(literal)}.svg"] = kanjivg.minify(inputs.svgs[literal])
        first_reading = (entry.onyomi or entry.kunyomi or [""])[0]
        summary = {
            "id": literal,
            "primaryMeaning": entry.meanings[0] if entry.meanings else "",
            "primaryReading": first_reading,
            "strokeCount": entry.stroke_count,
            "listIndex": order[literal],
        }
        summary.update({k: v for k, v in optional.items() if v is not None})
        index.append(summary)
    index.sort(key=lambda item: item["listIndex"])
    files["Shared/kanji-index.json"] = dump({"formatVersion": 1, "entries": index})
    common = sorted({(w.sequence, w.headword): w for w in usable if w.is_common}.values(), key=lambda w: (w.sequence, w.headword))
    files["AppOnly/words.json"] = dump([word_record(w) for w in common])
    files["Shared/DATA-SOURCES.md"] = data_sources(lock, len(literals), len(common))
    return files


def data_sources(lock: dict, kanji_count: int, word_count: int) -> str:
    lines = [
        "# Data sources",
        "",
        "Generated by `tools/dataset`. Do not edit by hand.",
        "",
        f"The bundle holds {kanji_count} kanji and {word_count} common words for Dictionary search.",
        "",
        "## Inputs",
        "",
        "| File | Version | Licence | SHA-256 | URL |",
        "|---|---|---|---|---|",
    ]
    for name, item in sorted(lock.items()):
        lines.append(f"| {name} | {item['version']} | {item['licence']} | `{item['sha256']}` | {item['url']} |")
    lines += [
        "",
        "## Attribution",
        "",
        "- Kanji records: KANJIDIC2 and example words: JMdict, both from the Electronic Dictionary Research and "
        "Development Group (https://www.edrdg.org), used under CC BY-SA 4.0 (https://www.edrdg.org/edrdg/licence.html).",
        "- Stroke order: KanjiVG (https://kanjivg.tagaini.net) by Ulrich Apel, CC BY-SA 3.0. "
        "The bundled SVGs keep only each file's ordered stroke paths and are shared under the same licence.",
        "- JLPT N5-N1 kanji levels: Jonathan Waller's JLPT Resources (https://www.tanos.co.uk/jlpt/), CC BY. "
        "The JLPT has not published official kanji lists since 2010, so levels are an unofficial estimate.",
        "- Levels for 172 Joyo kanji not in those lists: OpenJLPT (https://github.com/evanclan/OpenJLPT), "
        "CC BY-SA 4.0, built from JMdict and KANJIDIC2 (EDRDG), Jonathan Waller's JLPT lists, and Tatoeba. "
        "These levels carry `isJLPTLevelEstimated`.",
        "- Radical names and the selection, ordering and schema of this bundle are the app's own.",
        "",
    ]
    return "\n".join(lines)


def check_budgets(files: dict[str, str]) -> None:
    shared = sum(len(text.encode("utf-8")) for path, text in files.items() if path.startswith("Shared/"))
    total = sum(len(text.encode("utf-8")) for text in files.values())
    if shared > SHARED_BUDGET:
        raise BuildError(f"widget set is {shared} bytes, over the {SHARED_BUDGET} byte budget")
    if total > APP_BUDGET:
        raise BuildError(f"app set is {total} bytes, over the {APP_BUDGET} byte budget")


def write(files: dict[str, str], out: Path) -> None:
    for sub in ("Shared", "AppOnly"):
        shutil.rmtree(out / sub, ignore_errors=True)
    for relative, text in files.items():
        target = out / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8", newline="\n")


def load_inputs() -> tuple[Inputs, dict]:
    if not fetch.LOCK.exists() or not fetch.CACHE.exists():
        raise BuildError("inputs missing: run `make dataset-fetch` first")
    lock = json.loads(fetch.LOCK.read_text())
    for name, item in lock.items():
        path = fetch.CACHE / name
        if not path.exists() or fetch.sha256(path) != item["sha256"]:
            raise BuildError(f"{name} does not match sources.lock.json: run `make dataset-fetch`")
        fetch.verify(name, path)

    def read(name: str):
        return json.loads((fetch.CACHE / name).read_text(encoding="utf-8"))

    _, kanji = kanjidic.parse(kanjidic.read_text(fetch.CACHE / "kanjidic2.xml.gz"))
    inputs = Inputs(
        kanji=kanji,
        waller_levels=jlpt.load_waller_kanji(read),
        supplement_levels=jlpt.load_supplement(read),
        vocabulary_levels=jlpt.load_vocabulary_levels(read),
        words=list(jmdict.parse(jmdict.open_text(fetch.CACHE / "JMdict_e.gz"))),
        svgs={},
    )
    inputs.svgs = kanjivg.read_svgs(fetch.CACHE / "kanjivg-main.zip", select_literals(inputs))
    return inputs, lock


def main() -> None:
    try:
        inputs, lock = load_inputs()
        allowlist = set(json.loads(ALLOWLIST.read_text())["literals"]) if ALLOWLIST.exists() else set()
        files = generate(inputs, allowlist, lock)
        check_budgets(files)
    except BuildError as error:
        raise SystemExit(f"dataset: {error}")
    write(files, ROOT / "Dataset")
    print(f"wrote {len(files)} files to Dataset/", file=sys.stderr)


if __name__ == "__main__":
    main()
