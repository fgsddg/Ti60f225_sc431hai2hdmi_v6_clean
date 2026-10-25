#!/usr/bin/env python3
"""Build the cold-boot Flash image used by the 128x96 style demo.

The Efinity flash image is an ASCII byte-stream: one hex byte per line.  The
layout is fixed by firmware/tinyml_style/src/model/style_multistyle.c.  This
script fills unused regions with 0xFF and verifies every input size.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

FIRMWARE_ADDR = 0x0038_0000
STYLE_BASE = (0x003A_0000, 0x003B_0000, 0x003C_0000)
STYLE_IDS = ("future", "vangogh", "cubism")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def load_efinity_hex(path: Path) -> bytes:
    """Decode Efinity's one-byte-per-line ASCII HEX format."""
    values = path.read_bytes().splitlines()
    try:
        return bytes(int(value, 16) for value in values)
    except ValueError as exc:
        raise SystemExit(f"{path}: invalid Efinity HEX byte stream: {exc}") from exc


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bitstream-hex", type=Path, required=True,
                        help="active-mode Efinity HEX from efx_pgm")
    parser.add_argument("--firmware-bin", type=Path, required=True)
    parser.add_argument("--styles-dir", type=Path, required=True,
                        help="directory containing future/vangogh/cubism model dirs")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    bitstream = load_efinity_hex(args.bitstream_hex)
    firmware = args.firmware_bin.read_bytes()
    models = [
        (args.styles_dir / style_id / "style_model.bin").read_bytes()
        for style_id in STYLE_IDS
    ]

    if not bitstream:
        raise SystemExit("empty bitstream")
    if len(bitstream) >= FIRMWARE_ADDR:
        raise SystemExit("bitstream overlaps firmware slot")
    if len(firmware) > STYLE_BASE[0] - FIRMWARE_ADDR:
        raise SystemExit("firmware overlaps first model slot")
    for index, model in enumerate(models):
        slot_end = STYLE_BASE[index] + 0x1_0000
        if len(model) > 0x1_0000:
            raise SystemExit(f"{STYLE_IDS[index]} model exceeds 64 KiB slot")
        if STYLE_BASE[index] + len(model) > slot_end:
            raise SystemExit(f"{STYLE_IDS[index]} model overlaps next slot")

    image_size = STYLE_BASE[-1] + len(models[-1])
    image = bytearray(b"\xFF" * image_size)
    image[:len(bitstream)] = bitstream
    image[FIRMWARE_ADDR:FIRMWARE_ADDR + len(firmware)] = firmware
    placements = [(0, bitstream, args.bitstream_hex.name),
                  (FIRMWARE_ADDR, firmware, args.firmware_bin.name)]
    for address, model, style_id in zip(STYLE_BASE, models, STYLE_IDS):
        image[address:address + len(model)] = model
        placements.append((address, model, f"{style_id}/style_model.bin"))

    encoded = b"".join(b"%02X\n" % value for value in image)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(encoded)

    lines = [
        "**** Efinity Programming Tool Generation Report *****",
        "",
        f"Output: {args.output.as_posix()}",
        f"Decoded image bytes: {len(image)}",
        f"HEX file bytes: {len(encoded)}",
        f"SHA256: {sha256(encoded)}",
        "",
        "Flash Address  Length      Input Image File",
    ]
    for address, data, name in placements:
        lines.append(f"0x{address:08X}     0x{len(data):08X}  {name}")
    report = "\n".join(lines) + "\n"
    if args.report:
        args.report.write_text(report, encoding="utf-8", newline="\n")
    print(report, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())