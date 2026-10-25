#!/usr/bin/env python3
"""Preload the three 128x96 models and start the multi-style firmware."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "deploy" / "128x96_styles" / "manifest.json"
DEFAULT_TRAIN = Path(r"D:/train/fast-neural-style-transfer-fresh")
DEFAULT_OPENOCD = Path(r"D:/Efinity/2026.1/debugger/openocd/bin/openocd.exe")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def check_hash(path: Path, expected: str) -> None:
    actual = sha256(path)
    if actual != expected:
        raise SystemExit(f"SHA256 mismatch: {path}\n  expected {expected}\n  actual   {actual}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--training-repo", type=Path, default=DEFAULT_TRAIN)
    parser.add_argument("--openocd", type=Path, default=DEFAULT_OPENOCD)
    parser.add_argument("--adapter-speed", default="8000")
    parser.add_argument("--print-commands", action="store_true")
    parser.add_argument("--dry-run", action="store_true", help="validate assets and print OpenOCD commands only")
    args = parser.parse_args()

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    deploy = ROOT / "deploy" / "128x96_styles"
    firmware = deploy / "firmware" / Path(manifest["multistyle_firmware"]["path"]).name

    check_hash(firmware, manifest["multistyle_firmware"]["sha256"])
    model_loads = []
    for style in manifest["styles"]:
        model = deploy / style["model"]
        check_hash(model, style["model_sha256"])
        model_loads.append((style, model))

    cfg1 = args.training_repo / "soc/embedded_sw/my_soc/bsp/efinix/EfxSapphireSoc/openocd/ftdi_ti.cfg"
    cfg2 = args.training_repo / "soc/embedded_sw/my_soc/bsp/efinix/EfxSapphireSoc/openocd/debug_ti.cfg"
    for path in (args.openocd, cfg1, cfg2, firmware):
        if not path.exists():
            raise SystemExit(f"missing required file: {path}")

    def win(path: Path) -> str:
        return path.resolve().as_posix()

    cmd = [
        str(args.openocd), "-f", win(cfg1), "-f", win(cfg2),
        "-c", f"adapter speed {args.adapter_speed}",
        "-c", "halt",
    ]
    for style, model in model_loads:
        cmd += ["-c", f"load_image {win(model)} {style['ddr_base']}"]
    cmd += [
        "-c", f"load_image {win(firmware)} 0x00001000",
        "-c", "reg pc 0x00001000",
        "-c", "resume",
        "-c", "shutdown",
    ]
    if args.print_commands or args.dry_run:
        for item in cmd:
            print(item)
    if args.dry_run:
        print("dry run: assets verified; OpenOCD not started")
        return 0

    print("loading future/vangogh/cubism models and multi-style firmware...")
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print("\nOpenOCD failed.", file=sys.stderr)
        print("If JTAG shows dtmcontrol=0xffffffff, the SRAM bitstream is gone.", file=sys.stderr)
        print("Run tools/program_bitstream.py (or use the Efinity Programmer GUI), then rerun this script.", file=sys.stderr)
        print("Do not use SPI Active or reset halt.", file=sys.stderr)
        return result.returncode

    print("loaded and resumed; KEY0=next style; KEY1=styled/split KEY2=+ KEY3=-; UART 1/2/3=styles 0/4/5/6=display +/-=intensity")
    return 0


if __name__ == "__main__":
    sys.exit(main())
