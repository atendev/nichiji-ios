import tempfile
import unittest
from pathlib import Path

import fetch
import sources


class VerifyTests(unittest.TestCase):
    def test_pinned_hash_mismatch_fails(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "kanjivg-main.zip"
            path.write_bytes(b"not the archive")
            with self.assertRaises(SystemExit):
                fetch.verify("kanjivg-main.zip", path)

    def test_rolling_files_are_not_enforced(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "JMdict_e.gz"
            path.write_bytes(b"anything")
            fetch.verify("JMdict_e.gz", path)

    def test_pins_cover_the_expected_inputs(self):
        enforced = [n for n, (_, _, sha) in sources.INPUTS.items() if sha]
        self.assertEqual(len(sources.INPUTS), 18)
        self.assertEqual(len(enforced), 16)
        self.assertIn("kanjivg-main.zip", enforced)


if __name__ == "__main__":
    unittest.main()
