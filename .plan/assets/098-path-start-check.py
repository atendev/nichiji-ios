"""Ticket 098 check: is each KanjiVG path's first point the pen-down end?

Run: python3 -I .plan/assets/098-path-start-check.py <kanjivg-main.zip> Dataset/AppOnly/stroke-order [animcjk-svgsJa-dir]
The optional third argument is a folder of animCJK svgsJa files (decimal code point names,
https://github.com/parsimonhi/animCJK), an independent stroke dataset whose medians run in writing direction.
Throwaway evidence for the decision; not part of the app or the dataset build.
"""
import math
import re
import sys
import zipfile
from pathlib import Path

TOKEN = re.compile(r"[MmCcSsLlHhVvZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?")
PATH = re.compile(r'<path[^>]*?kvg:type="([^"]*)"[^>]*?d="([^"]+)"|<path[^>]*?d="([^"]+)"[^>]*?kvg:type="([^"]*)"')
PLAIN_PATH = re.compile(r'<path[^>]*?\bd="([^"]+)"')
LABEL = re.compile(r'<text transform="matrix\(1 0 0 1 ([-\d.]+) ([-\d.]+)\)">(\d+)</text>')

# Allowed first-tangent angle in degrees, y down: E=0, S=90, W=180, N=-90.
HORIZONTAL_FIRST = (-60, 60)
VERTICAL_FIRST = (0, 160)
EXPECTED = {
    "㇐": HORIZONTAL_FIRST, "㇕": HORIZONTAL_FIRST, "㇖": HORIZONTAL_FIRST, "㇆": HORIZONTAL_FIRST,
    "㇇": HORIZONTAL_FIRST, "㇋": HORIZONTAL_FIRST, "㇌": HORIZONTAL_FIRST, "㇅": HORIZONTAL_FIRST,
    "㇈": HORIZONTAL_FIRST, "㇎": HORIZONTAL_FIRST, "㇍": HORIZONTAL_FIRST,
    "㇑": VERTICAL_FIRST, "㇚": VERTICAL_FIRST, "㇙": VERTICAL_FIRST, "㇄": VERTICAL_FIRST,
    "㇟": VERTICAL_FIRST, "㇗": VERTICAL_FIRST, "㇞": VERTICAL_FIRST, "㇉": VERTICAL_FIRST,
    "㇊": VERTICAL_FIRST, "㇁": VERTICAL_FIRST,
    "㇒": (45, 215), "㇓": (45, 215), "㇛": (45, 215), "㇜": (45, 215),
    "㇏": (-15, 110), "㇂": (-15, 110), "㇔": (-30, 210), "㇀": (-95, 15),
}

# Where the stroke's end must sit relative to its start, by stroke type (y down).
ENDPOINT = {}
for t in "㇐㇖":
    ENDPOINT[t] = ("end right of start", lambda dx, dy: dx > 0)
for t in "㇑㇚㇙㇄㇟㇗㇞㇉㇁㇊㇔㇛㇜㇕㇆㇇㇋㇌㇅㇈㇎㇍":
    ENDPOINT[t] = ("end below start", lambda dx, dy: dy > 0)
for t in "㇒㇓":
    ENDPOINT[t] = ("end below and left of start", lambda dx, dy: dy > 0 and dx < 0)
for t in "㇏㇂":
    ENDPOINT[t] = ("end below and right of start", lambda dx, dy: dy > 0 and dx > 0)
ENDPOINT["㇀"] = ("end above and right of start", lambda dx, dy: dy < 0 and dx > 0)

ANIM_PATH = re.compile(r'<path[^>]*clip-path="url\(#z\d+c(\d+)\)"[^>]*\bd="([^"]+)"')

HAND_CHECK = "一十口木人大小山川水子九入力手心日目上下"


def parse(d):
    """Returns (start, first non-zero tangent, end) for one KanjiVG path."""
    tokens = TOKEN.findall(d)
    i, cmd = 0, None
    cur = start = None
    tangent = None
    last_c2 = None
    poly = []

    def num():
        nonlocal i
        v = float(tokens[i])
        i += 1
        return v

    def note(p):
        nonlocal tangent
        if tangent is None and (abs(p[0] - cur[0]) > 1e-6 or abs(p[1] - cur[1]) > 1e-6):
            tangent = (p[0] - cur[0], p[1] - cur[1])

    while i < len(tokens):
        if tokens[i].isalpha():
            cmd = tokens[i]
            i += 1
            if cmd in "Zz":
                continue
        rel = cmd.islower()
        base = cur if rel and cur else (0.0, 0.0)
        c = cmd.upper()
        if c == "M":
            cur = (base[0] + num(), base[1] + num())
            if start is None:
                start = cur
                poly.append(cur)
            cmd = "l" if rel else "L"
        elif c in "LHV":
            if c == "L":
                p = (base[0] + num(), base[1] + num())
            elif c == "H":
                p = ((cur[0] if rel else 0) + num(), cur[1])
            else:
                p = (cur[0], (cur[1] if rel else 0) + num())
            note(p)
            poly.append(p)
            cur = p
            last_c2 = None
        elif c in "CS":
            if c == "C":
                c1 = (base[0] + num(), base[1] + num())
            else:
                c1 = (2 * cur[0] - last_c2[0], 2 * cur[1] - last_c2[1]) if last_c2 else cur
            c2 = (base[0] + num(), base[1] + num())
            end = (base[0] + num(), base[1] + num())
            for p in (c1, c2, end):
                note(p)
            p0 = cur
            for k in range(1, 17):
                t = k / 16
                u = 1 - t
                poly.append((u**3 * p0[0] + 3 * u * u * t * c1[0] + 3 * u * t * t * c2[0] + t**3 * end[0],
                             u**3 * p0[1] + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t**3 * end[1]))
            cur, last_c2 = end, c2
        else:
            raise ValueError(f"unhandled command {cmd!r} in {d}")
    return start, tangent, cur, poly


def chord_at(poly, distance):
    """Vector from the start to the point `distance` units along the path (or its end)."""
    walked = 0.0
    for a, b in zip(poly, poly[1:]):
        step = math.dist(a, b)
        if walked + step >= distance and step > 0:
            t = (distance - walked) / step
            return (a[0] + t * (b[0] - a[0]) - poly[0][0], a[1] + t * (b[1] - a[1]) - poly[0][1])
        walked += step
    return (poly[-1][0] - poly[0][0], poly[-1][1] - poly[0][1])


def length(poly):
    return sum(math.dist(a, b) for a, b in zip(poly, poly[1:]))


RULES = {
    "first tangent": lambda poly, tangent: tangent,
    "chord at 6 units": lambda poly, tangent: chord_at(poly, 6),
    "chord at 10 units": lambda poly, tangent: chord_at(poly, 10),
    "chord at 15 units": lambda poly, tangent: chord_at(poly, 15),
    "chord at 20% of length": lambda poly, tangent: chord_at(poly, 0.2 * length(poly)),
}


def parts(kvg_type):
    return [part[:1] for part in kvg_type.split("/") if part[:1]]


def endpoint_ok(kvg_type, start, end):
    """True, False, or None when no label part has an endpoint rule."""
    rules = [ENDPOINT[t][1] for t in parts(kvg_type) if t in ENDPOINT]
    if not rules:
        return None
    return any(rule(end[0] - start[0], end[1] - start[1]) for rule in rules)


def anim_medians(path):
    medians = {}
    for n, d in ANIM_PATH.findall(path.read_text()):
        numbers = [float(v) for v in re.findall(r"[-\d.]+", d)]
        points = list(zip(numbers[0::2], numbers[1::2]))
        medians[int(n)] = points
    return [medians[k] for k in sorted(medians)]


def primary_type_ok(kvg_type):
    return kvg_type[:1] in EXPECTED


def angle(v):
    return math.degrees(math.atan2(v[1], v[0]))


def in_range(a, lo, hi):
    for shifted in (a, a + 360, a - 360):
        if lo <= shifted <= hi:
            return True
    return False


def compass(a):
    names = ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
    return names[round((a % 360) / 45) % 8]


def main(zip_path, dataset_dir, anim_dir=None):
    archive = zipfile.ZipFile(zip_path)
    dataset = sorted(Path(dataset_dir).glob("*.svg"))
    files = strokes = d_mismatch = type_checked = type_fail = generic_fail = 0
    label_checked = label_near_start = 0
    failures, by_type = [], {}
    hand = {}
    rule_tally, lengths, chord_misses = {}, [], []
    endpoint_checked, endpoint_misses, chord_any_misses = 0, [], []
    tick_total = tick_chord_ok = 0
    tick_legs, kanji_strokes = [], {}

    for svg in dataset:
        raw = archive.read(f"kanji/{svg.name}").decode()
        ours = PLAIN_PATH.findall(svg.read_text())
        theirs = []
        for m in PATH.finditer(raw):
            kvg_type = m.group(1) if m.group(1) is not None else m.group(4)
            d = m.group(2) or m.group(3)
            theirs.append((kvg_type, d))
        labels = {int(n): (float(x), float(y)) for x, y, n in LABEL.findall(raw)}
        files += 1
        if [d for _, d in theirs] != ours:
            d_mismatch += 1
        char = chr(int(svg.stem, 16))
        for n, (kvg_type, d) in enumerate(theirs, 1):
            strokes += 1
            start, tangent, end, poly = parse(d)
            a = angle(tangent)
            verdict = endpoint_ok(kvg_type, start, end)
            if verdict is not None:
                endpoint_checked += 1
                if not verdict:
                    endpoint_misses.append(f"{char} s{n} {kvg_type} start={tuple(round(v, 1) for v in start)} end={tuple(round(v, 1) for v in end)}")
            if primary_type_ok(kvg_type) and not in_range(a, *EXPECTED[kvg_type[:1]]):
                tick_total += 1
                chord_ok = any(in_range(angle(chord_at(poly, 10)), *EXPECTED[t]) for t in parts(kvg_type) if t in EXPECTED)
                tick_chord_ok += 1 if chord_ok else 0
                first_leg = math.dist(poly[0], poly[16]) if len(poly) > 16 else length(poly)
                tick_legs.append(first_leg)
            any_part = [t for t in parts(kvg_type) if t in EXPECTED]
            if any_part and not any(in_range(angle(chord_at(poly, 10)), *EXPECTED[t]) for t in any_part):
                chord_any_misses.append(f"{char} s{n} {kvg_type} start={tuple(round(v, 1) for v in start)} heads {angle(chord_at(poly, 10)):.0f} deg, end={tuple(round(v, 1) for v in end)}")
            kanji_strokes.setdefault(char, []).append((start, end, chord_at(poly, 10)))
            if primary_type_ok(kvg_type):
                for name, rule in RULES.items():
                    ok = in_range(angle(rule(poly, tangent)), *EXPECTED[kvg_type[:1]])
                    tally = rule_tally.setdefault(name, {})
                    entry = tally.setdefault(kvg_type[:1], [0, 0])
                    entry[0] += 1
                    entry[1] += 0 if ok else 1
                    if not ok and name == "chord at 10 units":
                        chord_misses.append(f"{char} s{n} {kvg_type} start={tuple(round(v, 1) for v in start)} heads {angle(rule(poly, tangent)):.0f} deg, end={tuple(round(v, 1) for v in end)}")
                lengths.append(length(poly))
            primary = kvg_type[:1]
            if (end[0] - start[0]) < -1 and (end[1] - start[1]) < -1:
                generic_fail += 1
                failures.append(f"generic up-left  {char} s{n} {kvg_type} start={start} end={end}")
            if primary in EXPECTED:
                type_checked += 1
                ok = in_range(a, *EXPECTED[primary])
                by_type.setdefault(primary, [0, 0])
                by_type[primary][0] += 1
                if not ok:
                    by_type[primary][1] += 1
                    type_fail += 1
                    failures.append(f"type {kvg_type:4} {char} s{n} first tangent {a:7.1f} deg")
            if n in labels:
                label_checked += 1
                lx, ly = labels[n]
                if math.dist((lx, ly), start) < math.dist((lx, ly), end):
                    label_near_start += 1
                else:
                    failures.append(f"label nearer end {char} s{n} label=({lx},{ly}) start={start} end={end}")
            if char in HAND_CHECK:
                hand.setdefault(char, []).append((n, kvg_type, start, compass(a), end))

    print(f"files {files}, strokes {strokes}, dataset d != KanjiVG d in {d_mismatch} files")
    print(f"first tangent vs kvg:type: {type_checked} strokes checked, {type_fail} outside the expected range")
    for t, (count, bad) in sorted(by_type.items(), key=lambda kv: -kv[1][0]):
        print(f"  {t} {count:6} strokes, {bad} outside")
    lengths.sort()
    print(f"stroke length in viewBox units: min {lengths[0]:.1f}, 5th pct {lengths[len(lengths)//20]:.1f}, median {lengths[len(lengths)//2]:.1f}")
    print("arrow direction rules, strokes outside their kvg:type range:")
    for name, tally in rule_tally.items():
        total = sum(bad for _, bad in tally.values())
        worst = sorted(((bad, t) for t, (count, bad) in tally.items() if bad), reverse=True)[:5]
        print(f"  {name:24} {total:5} outside; worst " + ", ".join(f"{t} {bad}" for bad, t in worst))
    print("chord at 10 units, strokes outside their range:")
    for line in chord_misses:
        print("  " + line)
    print(f"chord at 10 units against any part of a composite label: {len(chord_any_misses)} outside")
    for line in chord_any_misses:
        print("  " + line)
    tick_legs.sort()
    print(f"first-tangent misses whose 10-unit chord is in range: {tick_chord_ok} of {tick_total}; "
          f"length of the first curve segment in those strokes: median {tick_legs[len(tick_legs)//2]:.1f} units, 90th pct {tick_legs[len(tick_legs)*9//10]:.1f}")
    print(f"endpoint check by stroke type (any label part): {endpoint_checked} strokes checked, {len(endpoint_misses)} fail")
    for line in endpoint_misses:
        print("  " + line)
    print(f"generic check (end up-and-left of start): {generic_fail} strokes")
    print(f"stroke-number label nearer start than end: {label_near_start} of {label_checked}")
    print(f"failures listed: {len(failures)}")
    for line in failures[:10]:
        print("  " + line)
    if anim_dir:
        print("\nanimCJK comparison. Same way: KanjiVG's start-to-end vector is within 90 deg of animCJK's (a reversed path is about 180 deg off).")
        print("Arrow: KanjiVG's 10-unit chord is within 45 deg of the same chord on animCJK's median, scaled to 109 units.")
        total = same_way = arrow_ok = 0
        for svg in sorted(Path(anim_dir).glob("*.svg")):
            char = chr(int(svg.stem))
            ours, theirs = kanji_strokes.get(char, []), anim_medians(svg)
            if len(ours) != len(theirs):
                print(f"  {char}: stroke count differs, KanjiVG {len(ours)} animCJK {len(theirs)}")
                continue
            marks = []
            for (start, end, chord), median in zip(ours, theirs):
                median = [(x * 109 / 1024, y * 109 / 1024) for x, y in median]
                overall = abs((angle((end[0] - start[0], end[1] - start[1])) - angle((median[-1][0] - median[0][0], median[-1][1] - median[0][1])) + 180) % 360 - 180)
                arrow = abs((angle(chord) - angle(chord_at(median, 10)) + 180) % 360 - 180)
                total += 1
                same_way += overall < 90
                arrow_ok += arrow < 45
                marks.append("ok" if overall < 90 and arrow < 45 else f"{'same way' if overall < 90 else 'REVERSED'} {overall:.0f}/arrow {arrow:.0f} deg")
            print(f"  {char}: " + ", ".join(f"s{i} {mark}" for i, mark in enumerate(marks, 1)))
        print(f"animCJK comparison: {same_way} of {total} strokes run the same way, {arrow_ok} of {total} arrows agree within 45 deg")
    print("\nHand check (start, first direction, end):")
    for char in HAND_CHECK:
        print(f"{char}:")
        for n, t, s, c, e in hand.get(char, []):
            print(f"  s{n} {t:4} start ({s[0]:5.1f},{s[1]:5.1f}) heads {c:2} end ({e[0]:5.1f},{e[1]:5.1f})")


if __name__ == "__main__":
    main(*sys.argv[1:4])
