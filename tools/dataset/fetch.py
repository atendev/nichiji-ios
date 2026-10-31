"""Downloads pinned inputs into .cache/ and writes sources.lock.json."""

import hashlib
import json
import re
import sys
import urllib.request
from pathlib import Path

import jmdict
import kanjidic
import sources

HERE = Path(__file__).parent
CACHE = HERE / ".cache"
LOCK = HERE / "sources.lock.json"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def upstream_version(name: str, path: Path) -> str:
    if name == "kanjidic2.xml.gz":
        return kanjidic.parse(kanjidic.read_text(path))[0]
    if name == "JMdict_e.gz":
        match = re.search(rb"JMdict created: (\d{4}-\d{2}-\d{2})", jmdict.open_text(path)[:200_000])
        return match.group(1).decode() if match else "unknown"
    if name == "kanjivg-main.zip":
        return sources.KANJIVG_TAG
    return sources.OPENJLPT_COMMIT


def verify(name: str, path: Path) -> None:
    pinned = sources.INPUTS[name][2]
    if pinned and sha256(path) != pinned:
        raise SystemExit(f"{name}: SHA-256 does not match the pinned value")


def main() -> None:
    CACHE.mkdir(exist_ok=True)
    lock = {}
    for name, (url, licence, _) in sorted(sources.INPUTS.items()):
        path = CACHE / name
        print(f"fetching {name}", file=sys.stderr)
        with urllib.request.urlopen(url, timeout=120) as response:
            path.write_bytes(response.read())
        verify(name, path)
        lock[name] = {
            "url": url,
            "licence": licence,
            "sha256": sha256(path),
            "version": upstream_version(name, path),
            "enforced": sources.INPUTS[name][2] is not None,
        }
    LOCK.write_text(json.dumps(lock, indent=2, sort_keys=True, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
