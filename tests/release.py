"""Release checks use an in-memory ZIP; no build artifacts are written."""
from contextlib import redirect_stdout
import importlib.util
import io
from pathlib import Path
import unittest
from unittest.mock import patch
import zipfile

spec = importlib.util.spec_from_file_location("packaging", Path(__file__).resolve().parents[1] / "tools/package.py")
packaging = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packaging)

class ReleaseTests(unittest.TestCase):
    def test_tags(self):
        for tag, version, kind in [
            ("2.0.1", "2.0.1", "release"), ("v2.0.1", "2.0.1", "release"),
            ("2.0.0-forever", "2.0.0-forever", "release"),
            ("v2.0.0-forever", "2.0.0-forever", "release"),
            ("2.0.0-forever-alpha.1", "2.0.0-forever-alpha.1", "alpha"),
            ("2.0.0-forever-beta.1", "2.0.0-forever-beta.1", "beta"),
            ("2.0.1-alpha.2", "2.0.1-alpha.2", "alpha"),
            ("v2.0.1-beta.1", "2.0.1-beta.1", "beta"),
            ("2.0.1-rc.1", "2.0.1-rc.1", "beta"),
            ("2.0.0-forever.1", "2.0.0-forever.1", "beta"),
        ]:
            self.assertEqual(packaging.release_metadata(tag), (version, kind))
        for tag in ["", "latest", "../../bad", "2.0", "2.0.1\n"]:
            with self.assertRaises(ValueError):
                packaging.release_metadata(tag)

    def test_archive_matches_tag_without_changing_checkout(self):
        toc = packaging.ROOT / "FishMaster.toc"
        original = toc.read_bytes()
        buffer = io.BytesIO()
        real_zip = zipfile.ZipFile
        def memory_zip(path, mode="r", *args, **kwargs):
            if mode == "r":
                buffer.seek(0)
            return real_zip(buffer, mode, *args, **kwargs)
        with redirect_stdout(io.StringIO()), patch.object(packaging.zipfile, "ZipFile", side_effect=memory_zip), patch.object(Path, "mkdir"):
            output, kind = packaging.build("2.0.0-forever")
        self.assertEqual(output.name, "FishMaster-2.0.0-forever.zip")
        self.assertEqual(kind, "release")
        with real_zip(buffer) as archive:
            self.assertIn("## Version: 2.0.0-forever\n", archive.read("FishMaster/FishMaster.toc").decode())
            self.assertIsNone(archive.testzip())
        self.assertEqual(toc.read_bytes(), original)

if __name__ == "__main__":
    unittest.main()
