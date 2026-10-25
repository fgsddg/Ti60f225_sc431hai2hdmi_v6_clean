#!/usr/bin/env python3
"""Program the 128x96 SRAM bitstream through the Efinity FTDI/JTAG path.

Configuration Flash is present; this helper only loads the passive JTAG/SRAM bitstream.  A JTAG download at 6 MHz was
observed to finish in CONFIGURATION_FAIL; asserting CRESET before configuration
and using a 1 MHz JTAG clock successfully enters user mode.  This script sets
that option in the per-user hw_tools.json only for the duration of the run and
restores the file afterwards.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "deploy" / "128x96_styles" / "manifest.json"
DEFAULT_FTDI = Path(r"D:/Efinity/2026.1/pgm/bin/ftdi_pgm.bat")
DEFAULT_BITSTREAM = None


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bitstream", type=Path, default=DEFAULT_BITSTREAM)
    parser.add_argument("--ftdi-programmer", type=Path, default=DEFAULT_FTDI)
    parser.add_argument("--jtag-clock-hz", type=int, default=1_000_000)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    expected = manifest["bitstream"]["sha256"]
    bitstream = args.bitstream if args.bitstream else ROOT / manifest["bitstream"]["path"]
    if not bitstream.exists():
        raise SystemExit(f"missing bitstream: {bitstream}")
    actual = sha256(bitstream)
    if actual != expected:
        raise SystemExit(f"bitstream SHA256 mismatch: expected {expected}, got {actual}")
    if not args.ftdi_programmer.exists():
        raise SystemExit(f"missing ftdi programmer: {args.ftdi_programmer}")

    config = Path(os.environ.get("LOCALAPPDATA", Path.home() / "AppData/Local")) / "efinity/hw_tools.json"
    command = [
        str(args.ftdi_programmer), "-m", "jtag",
        "--jtag_clock_freq", str(args.jtag_clock_hz),
        bitstream.resolve().as_posix(),
    ]
    print("bitstream:", bitstream)
    print("bitstream SHA256 OK:", actual)
    print("hw_tools:", config)
    print("command:", " ".join(command))
    if args.dry_run:
        print("dry run: bitstream not programmed")
        return 0

    config.parent.mkdir(parents=True, exist_ok=True)
    original = config.read_bytes() if config.exists() else None
    try:
        if original is None:
            settings = {"config": {}}
        else:
            settings = json.loads(original.decode("utf-8"))
        settings.setdefault("config", {})
        settings["config"]["creset_before_jtag_config"] = True
        config.write_text(json.dumps(settings, indent=2) + "\n", encoding="utf-8")

        result = subprocess.run(command, capture_output=True, text=True)
        output = (result.stdout or "") + (result.stderr or "")
        print(output, end="")
        failed = "ERROR" in output or "PROGRAM_RESULT False" in output or result.returncode != 0
        if failed:
            print("JTAG bitstream programming FAILED", file=sys.stderr)
            return 1
        if "finished with JTAG programming" not in output:
            print("JTAG bitstream programming did not report completion", file=sys.stderr)
            return 1
        print("JTAG bitstream programming PASS")
        return 0
    finally:
        if original is None:
            if config.exists():
                config.unlink()
        else:
            config.write_bytes(original)


if __name__ == "__main__":
    sys.exit(main())
