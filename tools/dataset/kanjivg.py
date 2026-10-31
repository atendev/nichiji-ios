"""KanjiVG archive reader. Output SVGs keep only the ordered stroke paths."""

import re
import zipfile

_PATH = re.compile(r"<path\b")


def hex_name(literal: str) -> str:
    return f"{ord(literal):05x}"


def read_svgs(archive_path, literals) -> dict[str, str]:
    """Maps each requested literal to its SVG text. Literals with no file are absent."""
    result = {}
    with zipfile.ZipFile(archive_path) as archive:
        names = set(archive.namelist())
        for literal in literals:
            name = f"kanji/{hex_name(literal)}.svg"
            if name in names:
                result[literal] = archive.read(name).decode("utf-8")
    return result


def stroke_count(svg: str) -> int:
    return len(_PATH.findall(svg))


def validate(literal: str, svg: str) -> list[str]:
    problems = []
    if f'id="kvg:{hex_name(literal)}"' not in svg:
        problems.append(f"{literal}: SVG id does not match its code point")
    if 'viewBox="0 0 109 109"' not in svg:
        problems.append(f"{literal}: unexpected viewBox")
    if stroke_count(svg) == 0:
        problems.append(f"{literal}: no stroke paths")
    return problems


_PATH_DATA = re.compile(r'<path\b[^>]*?\sd="([^"]*)"')
_HEAD = (
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 109 109">'
    '<g fill="none" stroke="#000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">'
)


def minify(svg: str) -> str:
    """Drops the licence header, stroke numbers and component groups. Path order is stroke order."""
    paths = "".join(f'<path d="{d}"/>' for d in _PATH_DATA.findall(svg))
    return f"{_HEAD}{paths}</g></svg>\n"
