#!/usr/bin/env python3
"""Program the complete three-style image into the configuration Flash."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "deploy" / "128x96_styles" / "manifest.json"
DEFAULT_FTDI = Path(r"D:/Efinity/2026.1/pgm/bin/ftdi_pgm.bat")
BRIDGE = Path(r"D:/Efinity/2026.1/pgm/fli/titanium/u10660A79.bit")
URL = "ftdi://0x0403:0x6011:0:ff/1"
BOARD = "Generic Board Profile Using FT4232H"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def run(command: list[str]) -> tuple[int, str]:
    result = subprocess.run(command, capture_output=True, text=True)
    output = (result.stdout or "") + (result.stderr or "")
    print(output, end="")
    return result.returncode, output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ftdi-programmer", type=Path, default=DEFAULT_FTDI)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    flash = manifest["flash_image"]
    image = ROOT / flash["path"]
    expected = flash["sha256"]
    if not image.exists():
        raise SystemExit(f"missing flash image: {image}")
    actual = sha256(image)
    if actual != expected:
        raise SystemExit(f"flash image SHA256 mismatch: expected {expected}, got {actual}")
    if not args.ftdi_programmer.exists() or not BRIDGE.exists():
        raise SystemExit("missing ftdi_pgm.bat or JTAG bridge bitstream")

    bridge_cmd = [str(args.ftdi_programmer), "-m", "jtag", "-u", URL, "-b", BOARD,
                  "--jtag_clock_freq", "1000000", str(BRIDGE)]
    # Do not pass --burst_size 256 here.  On this board it caused every
    # alternate 256-byte page to remain erased.  Plain GUI JTAG2SPI has no
    # Flash Selection control and is the validated production flow.
    flash_cmd = [str(args.ftdi_programmer), "-m", "jtag_bridge", "-u", URL, "-b", BOARD,
                 "--jtag_clock_freq", "500000",
                 "--address", "0", "--jtag_bridge_mode", "all",
                 "--verify_method", "hostx1", str(image)]
    print("flash image SHA256 OK:", actual)
    print("bridge:", " ".join(bridge_cmd))
    print("flash :", " ".join(flash_cmd))
    if args.dry_run:
        return 0

    rc, output = run(bridge_cmd)
    if rc != 0 or "finished with JTAG programming" not in output:
        print("JTAG bridge load FAILED", file=sys.stderr)
        return 1

    rc, output = run(flash_cmd)
    if rc != 0 or "Flash verify successful" not in output:
        print("Flash write/verify FAILED", file=sys.stderr)
        return 1
    if "JTAG2SPI programming...done" not in output:
        print("Flash programmer did not report completion", file=sys.stderr)
        return 1
    print("Flash write/verify PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
