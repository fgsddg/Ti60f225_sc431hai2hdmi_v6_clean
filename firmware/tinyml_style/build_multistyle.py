#!/usr/bin/env python3
"""Build and verify the three-style Ti60F225 128x96 firmware."""

from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STYLE_DIR = ROOT / "styles" / "128x96"
BUILD_DIR = ROOT / "build"


def fnv1a32(data: bytes) -> int:
    value = 0x811C9DC5
    for byte in data:
        value = ((value ^ byte) * 0x01000193) & 0xFFFFFFFF
    return value


def verify_models() -> None:
    manifest = json.loads((STYLE_DIR / "manifest.json").read_text(encoding="utf-8"))
    for style in manifest["styles"]:
        path = STYLE_DIR / style["id"] / "style_model.bin"
        data = path.read_bytes()
        actual_sha = hashlib.sha256(data).hexdigest().upper()
        actual_fnv = fnv1a32(data)
        expected_fnv = int(style["fnv1a32"], 16)
        if len(data) != style["model_bytes"]:
            raise SystemExit(f"{style['id']}: size mismatch")
        if actual_sha != style["sha256"]:
            raise SystemExit(f"{style['id']}: SHA256 mismatch")
        if actual_fnv != expected_fnv:
            raise SystemExit(f"{style['id']}: FNV mismatch")
        print(f"model {style['id']}: {len(data)} B, FNV=0x{actual_fnv:08X}, SHA256 OK")


def prepare_build_dir() -> None:
    resolved = BUILD_DIR.resolve()
    expected_parent = ROOT.resolve()
    if resolved.parent != expected_parent:
        raise SystemExit(f"refusing to clean unexpected path: {resolved}")
    if resolved.exists():
        shutil.rmtree(resolved)
    for relative in ("out/src/common", "out/src/model", "out/src/style_net", "out/src/main"):
        (resolved / relative).mkdir(parents=True, exist_ok=True)


def main() -> int:
    verify_models()
    prepare_build_dir()
    cmd = [
        "make", "all", "OBJDIR=build",
        "STYLE_NET_RUN_FRAME=19", "STYLE_NET_STREAM=1",
        "STYLE_NET_MULTI_STYLE=1",
    ]
    print("+", " ".join(cmd))
    subprocess.run(cmd, cwd=ROOT, check=True)
    firmware = BUILD_DIR / "tinyml_style.bin"
    data = firmware.read_bytes()
    print(f"firmware: {firmware} ({len(data)} B)")
    print("SHA256:", hashlib.sha256(data).hexdigest().upper())
    return 0


if __name__ == "__main__":
    sys.exit(main())
