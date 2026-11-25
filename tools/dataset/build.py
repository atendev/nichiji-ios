"""Joins the parsed inputs into the committed Dataset/ bundle. Offline and deterministic."""

import json
import re
import shutil
import sys
import unicodedata
from dataclasses import dataclass
from datetime import date, datetime, timedelta
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
FONTS = ROOT / "Fonts"
# Both budgets count generated dataset files only, as a guard against accidental dataset growth.
# Fonts and total bundle size are reported, not enforced; widget memory is the real limit.
SHARED_BUDGET = 8 * 1024 * 1024
APP_BUDGET = 24 * 1024 * 1024
MAX_EXAMPLES = 3
LEVEL_RANK = {level: index for index, level in enumerate(sources.LEVELS)}
JOYO_GRADES = set(kanjidic.GRADE_NAMES)
JOYO, JINMEIYO, HYOGAI = "joyo", "jinmeiyo", "hyogai"
CLASSIFICATIONS = (JOYO, JINMEIYO, HYOGAI)
EDRDG_URL = "https://www.edrdg.org"
EDRDG_LICENCE_URL = "https://www.edrdg.org/edrdg/licence.html"
CC_BY_SA_4 = "https://creativecommons.org/licenses/by-sa/4.0/"
CC_BY_SA_3 = "https://creativecommons.org/licenses/by-sa/3.0/"
WALLER_TITLE = "Jonathan Waller's JLPT Resources"


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


def classify(entry: kanjidic.KanjidicEntry) -> str:
    """Joyo is grade 1-6 or 8, jinmeiyo is grade 9 or 10, and every other bundled kanji is hyogai."""
    if entry.grade in JOYO_GRADES:
        return JOYO
    if entry.grade in kanjidic.JINMEIYO_GRADES:
        return JINMEIYO
    return HYOGAI


def select_literals(inputs: Inputs) -> list[str]:
    """Every Joyo and jinmeiyo kanji, every other JIS X 0208 kanji, and any Waller-listed kanji. Compatibility ideographs fold into their unified twin."""
    bundled = {c for c, e in inputs.kanji.items() if e.grade in JOYO_GRADES or e.grade in kanjidic.JINMEIYO_GRADES or e.jis208}
    listed = set(inputs.waller_levels)
    joyo = {c for c, e in inputs.kanji.items() if e.grade in JOYO_GRADES}
    stray = {c for c in listed - joyo if inputs.waller_levels[c] != "n1"}
    if stray:
        raise BuildError(f"non-Joyo kanji outside N1: {''.join(sorted(stray))}")
    missing = listed - set(inputs.kanji)
    if missing:
        raise BuildError(f"not in KANJIDIC2: {''.join(sorted(missing))}")
    chosen = bundled | listed
    # A compatibility ideograph is canonically equal to a unified one, and Swift compares Strings that way.
    folded = {c for c in chosen if unicodedata.normalize("NFC", c) != c}
    orphans = {c for c in folded if unicodedata.normalize("NFC", c) not in chosen}
    if orphans:
        raise BuildError(f"compatibility ideographs with no unified twin in the bundle: {''.join(sorted(orphans))}")
    return sorted(chosen - folded, key=ord)


def assign_level(literal: str, inputs: Inputs) -> tuple[str | None, bool]:
    """Waller's level, else OpenJLPT's estimate for a Joyo kanji. Jinmeiyo and hyogai kanji outside Waller have none."""
    if literal in inputs.waller_levels:
        return inputs.waller_levels[literal], False
    if literal in inputs.supplement_levels and classify(inputs.kanji[literal]) == JOYO:
        return inputs.supplement_levels[literal], True
    return None, False


def list_order(literals: list[str], kanji: dict[str, kanjidic.KanjidicEntry], common_counts: dict[str, int]) -> dict[str, int]:
    """Frequency rank first (unranked last), then more common JMdict words, then fewer strokes, then code point."""

    def key(literal: str):
        entry = kanji[literal]
        return (entry.frequency or 10**6, -common_counts.get(literal, 0), entry.stroke_count, ord(literal))

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


def search_word_record(word: jmdict.Word) -> dict:
    return {**word_record(word), "rank": word.rank}


def readings(kind: str, values: list[str]) -> list[dict]:
    return [{"kind": kind, "kana": value, "romaji": romaji.romanize(value)} for value in values]


def check_stroke_counts(inputs: Inputs, literals: list[str], allowlist: set[str]) -> None:
    """Joyo kanji must have a KanjiVG file. Others without one ship with no stroke order."""
    missing = [c for c in literals if c not in inputs.svgs and classify(inputs.kanji[c]) == JOYO]
    if missing:
        raise BuildError(f"no KanjiVG file for: {''.join(missing)}")
    drawn = [c for c in literals if c in inputs.svgs]
    problems = [p for c in drawn for p in kanjivg.validate(c, inputs.svgs[c])]
    mismatched = {c for c in drawn if kanjivg.stroke_count(inputs.svgs[c]) != inputs.kanji[c].stroke_count}
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
    common = sorted({(w.sequence, w.headword): w for w in usable if w.is_common}.values(), key=lambda w: (w.sequence, w.headword))
    common_counts: dict[str, int] = {}
    for word in common:
        for char in set(word.headword):
            if char in bundle:
                common_counts[char] = common_counts.get(char, 0) + 1
    order = list_order(literals, inputs.kanji, common_counts)
    files: dict[str, str] = {}
    index = []
    search_kanji = []
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
            "classification": classify(entry),
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
        if literal in inputs.svgs:
            files[f"AppOnly/stroke-order/{kanjivg.hex_name(literal)}.svg"] = kanjivg.minify(inputs.svgs[literal])
        search_kanji.append(
            {
                "id": literal,
                "meanings": entry.meanings,
                "onyomi": record["onyomi"],
                "kunyomi": record["kunyomi"],
            }
        )
        first_reading = (entry.onyomi or entry.kunyomi or [""])[0]
        summary = {
            "id": literal,
            "primaryMeaning": entry.meanings[0] if entry.meanings else "",
            "primaryReading": first_reading,
            "classification": record["classification"],
            "strokeCount": entry.stroke_count,
            "listIndex": order[literal],
        }
        summary.update({k: v for k, v in optional.items() if v is not None})
        index.append(summary)
    index.sort(key=lambda item: item["listIndex"])
    files["Shared/kanji-index.json"] = dump({"formatVersion": 1, "entries": index})
    files["AppOnly/words.json"] = dump([search_word_record(w) for w in common])
    files["AppOnly/kanji-search.json"] = dump(search_kanji)
    estimated_count = sum(1 for literal in literals if assign_level(literal, inputs)[1])
    level_counts = {name: sum(1 for item in index if item["classification"] == name) for name in CLASSIFICATIONS}
    files["Shared/DATA-SOURCES.md"] = data_sources(lock, level_counts, len(common), estimated_count)
    return files


def snapshot_date(version: str) -> str:
    """ISO date for a lock version: YYYY-MM-DD, KANJIDIC2's YYYY-DDD, or KanjiVG's rYYYYMMDD."""
    try:
        if re.fullmatch(r"\d{4}-\d{2}-\d{2}", version):
            return date.fromisoformat(version).isoformat()
        if re.fullmatch(r"\d{4}-\d{3}", version):
            year, day = (int(part) for part in version.split("-"))
            days_in_year = (date(year + 1, 1, 1) - date(year, 1, 1)).days
            if 1 <= day <= days_in_year:
                return (date(year, 1, 1) + timedelta(days=day - 1)).isoformat()
        if re.fullmatch(r"r\d{8}", version):
            return datetime.strptime(version[1:], "%Y%m%d").date().isoformat()
    except ValueError:
        pass
    raise BuildError(f"cannot read a snapshot date from version {version!r}")


def snapshots(lock: dict) -> list[str]:
    def version(name: str) -> str:
        if name not in lock:
            raise BuildError(f"{name} is missing from sources.lock.json")
        return lock[name]["version"]

    kanjidic_version = version("kanjidic2.xml.gz")
    jmdict_version = version("JMdict_e.gz")
    kanjivg_version = version("kanjivg-main.zip")
    commit = version("waller-kanji-n1.json")[:7]
    return [
        f"- KANJIDIC2: {snapshot_date(kanjidic_version)} (database version {kanjidic_version})",
        f"- JMdict: {snapshot_date(jmdict_version)}",
        f"- KanjiVG: {snapshot_date(kanjivg_version)} (release {kanjivg_version})",
        f"- Jonathan Waller's lists and OpenJLPT: {sources.OPENJLPT_COMMIT_DATE} (OpenJLPT commit {commit})",
    ]


def data_sources(lock: dict, level_counts: dict[str, int], word_count: int, estimated_count: int) -> str:
    lines = [
        "# Data sources",
        "",
        "Generated by `tools/dataset`. Do not edit by hand.",
        "",
        f"The bundle holds {sum(level_counts.values())} kanji ({level_counts[JOYO]} Jōyō, {level_counts[JINMEIYO]} Jinmeiyō, "
        f"{level_counts[HYOGAI]} Hyōgai) and {word_count} common words for Dictionary search.",
        "",
        "## Inputs",
        "",
        "| File | Version | Licence | SHA-256 | URL |",
        "|---|---|---|---|---|",
    ]
    for name, item in sorted(lock.items()):
        lines.append(f"| {name} | {item['version']} | {item['licence']} | `{item['sha256']}` | {item['url']} |")
    # Waller's sharing page states CC BY with no version, so the licence link points at that page.
    lines += [
        "",
        "## Attribution",
        "",
        "- Kanji records: KANJIDIC2 and example words: JMdict, both from the "
        f"{link('Electronic Dictionary Research and Development Group', EDRDG_URL)}, "
        f"used under {link('CC BY-SA 4.0', CC_BY_SA_4)} and the {link('EDRDG licence', EDRDG_LICENCE_URL)}.",
        f"- Stroke order: {link('KanjiVG', 'https://kanjivg.tagaini.net')} by Ulrich Apel, {link('CC BY-SA 3.0', CC_BY_SA_3)}. "
        "The bundled SVGs keep only each file's ordered stroke paths and are shared under the same licence.",
        "- JLPT N5-N1 kanji levels, and the vocabulary lists that pick example words: "
        f"{link(WALLER_TITLE, 'https://www.tanos.co.uk/jlpt/')}, {link('CC BY', 'https://www.tanos.co.uk/jlpt/sharing/')}. "
        "Levels are an unofficial estimate.",
        f"- Levels for {estimated_count} Jōyō kanji not in those lists: {link('OpenJLPT', 'https://github.com/evanclan/OpenJLPT')}, "
        f"{link('CC BY-SA 4.0', CC_BY_SA_4)}, built from JMdict and KANJIDIC2 (EDRDG), Jonathan Waller's JLPT lists, and Tatoeba.",
        "- Radical names and the selection, ordering and schema of this bundle are the app's own.",
        "",
        "## Snapshots",
        "",
        *snapshots(lock),
        "",
    ]
    return "\n".join(lines)


def link(title: str, url: str) -> str:
    return f"[{title}]({url})"


def check_budgets(files: dict[str, str]) -> None:
    shared = sum(len(text.encode("utf-8")) for path, text in files.items() if path.startswith("Shared/"))
    total = sum(len(text.encode("utf-8")) for text in files.values())
    if shared > SHARED_BUDGET:
        raise BuildError(f"Shared dataset is {shared} bytes, over the {SHARED_BUDGET} byte budget")
    if total > APP_BUDGET:
        raise BuildError(f"app dataset is {total} bytes, over the {APP_BUDGET} byte budget")


def bundle_report(files: dict[str, str], fonts_dir: Path = FONTS) -> str:
    """One info line with the sizes the budgets leave out: bundled fonts plus the dataset."""
    mib = 1024 * 1024
    fonts = sum(path.stat().st_size for path in fonts_dir.glob("*.ttf")) if fonts_dir.is_dir() else 0
    shared = sum(len(text.encode("utf-8")) for path, text in files.items() if path.startswith("Shared/"))
    total = sum(len(text.encode("utf-8")) for text in files.values())
    return (
        f"with fonts ({fonts / mib:.2f} MiB): widget {(shared + fonts) / mib:.2f} MiB, "
        f"app {(total + fonts) / mib:.2f} MiB (not budgeted)"
    )


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
    print(bundle_report(files), file=sys.stderr)


if __name__ == "__main__":
    main()
