"""Give Godot web assets content-addressed names for safe browser caching."""

import hashlib
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "build/web"


def fingerprint(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()[:12]


def prepare(directory: Path) -> tuple[str, str]:
    directory = directory.resolve()
    html_path = directory / "index.html"
    wasm_path = directory / "index.wasm"
    pack_path = directory / "index.pck"
    engine_files = [
        "index.wasm",
        "index.js",
        "index.audio.worklet.js",
        "index.audio.position.worklet.js",
    ]
    for name in engine_files + ["index.pck", "index.html"]:
        if not (directory / name).is_file():
            raise FileNotFoundError(f"Missing fresh Godot export file: {name}")

    engine_name = f"engine-{fingerprint(wasm_path)}"
    pack_name = f"art-{fingerprint(pack_path)}.pck"
    html = html_path.read_text(encoding="utf-8")
    script_tag = '<script src="index.js"></script>'
    if html.count(script_tag) != 1:
        raise ValueError("Expected one Godot engine script tag")
    match = re.search(r"\bconst config = ", html)
    if not match:
        raise ValueError("Godot export config was not found")
    config_start = match.end()
    config, config_length = json.JSONDecoder().raw_decode(html[config_start:])
    if config.get("executable") != "index":
        raise ValueError("Expected an unprepared Godot export")
    config["executable"] = engine_name
    config["mainPack"] = pack_name
    config["fileSizes"] = {
        f"{engine_name}.wasm": wasm_path.stat().st_size,
        pack_name: pack_path.stat().st_size,
    }
    html = (
        html[:config_start]
        + json.dumps(config, ensure_ascii=False, separators=(",", ":"))
        + html[config_start + config_length :]
    )
    html = html.replace(script_tag, f'<script src="{engine_name}.js"></script>', 1)

    # Generated assets from the previous export must not remain in the deployment.
    for old in directory.iterdir():
        if old.is_file() and re.fullmatch(
            r"(?:engine-[0-9a-f]{12}\.(?:wasm|js|audio\.worklet\.js|audio\.position\.worklet\.js)|art-[0-9a-f]{12}\.pck)",
            old.name,
        ):
            old.unlink()

    for name in engine_files:
        (directory / name).replace(directory / name.replace("index", engine_name, 1))
    pack_path.replace(directory / pack_name)
    html_path.write_text(html, encoding="utf-8")
    return engine_name, pack_name


def main() -> None:
    engine_name, pack_name = prepare(OUTPUT)
    print(f"Web assets ready: {engine_name}.wasm, {pack_name}")


if __name__ == "__main__":
    main()
