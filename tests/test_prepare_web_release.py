import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.prepare_web_release import prepare


class PrepareWebReleaseTests(unittest.TestCase):
    def test_content_hashes_and_references(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            for name in (
                "index.wasm",
                "index.pck",
                "index.js",
                "index.audio.worklet.js",
                "index.audio.position.worklet.js",
            ):
                (directory / name).write_bytes(name.encode("ascii"))
            (directory / "index.html").write_text(
                '<script src="index.js"></script>\n'
                'const config = {"executable":"index","fileSizes":{"index.pck":9,"index.wasm":10}};',
                encoding="utf-8",
            )
            engine, pack = prepare(directory)
            html = (directory / "index.html").read_text(encoding="utf-8")
            config = json.JSONDecoder().raw_decode(html.split("const config = ", 1)[1])[0]
            self.assertEqual(config["executable"], engine)
            self.assertEqual(config["mainPack"], pack)
            self.assertIn(f'<script src="{engine}.js"></script>', html)
            self.assertEqual(config["fileSizes"][f"{engine}.wasm"], len("index.wasm"))
            self.assertTrue((directory / f"{engine}.audio.worklet.js").is_file())
            self.assertTrue((directory / f"{engine}.audio.position.worklet.js").is_file())
            self.assertTrue((directory / pack).is_file())
            self.assertFalse((directory / "index.wasm").exists())


if __name__ == "__main__":
    unittest.main()
