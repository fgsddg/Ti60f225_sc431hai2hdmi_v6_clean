# Ti60F225 128x96 StyleCam clean project

This directory is the final StyleCam source and validated-artifact package.
Firmware build outputs under `firmware/tinyml_style/build/` are user build
artifacts and must be retained; do not delete them automatically.

## Open

Open `ti60f225_oob.xml` in Efinity 2026.1.

Top module: `ti60f225_oob_top`.

## Documentation

- `PROJECT_STRUCTURE.md`: directory map, RTL/firmware/model layout, build flow and submission checklist.
- `STYLE_INTENSITY.md`: style interpolation, HUD, controls and verification details.

## Current flash-boot artifacts (style-intensity version)

- `artifacts/ti60f225_oob_128x96_hudclean_6071F0BA.bit`
  - JTAG/SRAM bitstream with SoC SPI0 wired to the configuration Flash
  - SHA256 `6071F0BAEEA09E7DDCC62BD859913A0F05E3CE89F961BB973615170D7412174F`
- `artifacts/ti60f225_oob_128x96_hudclean_C06330F7.hex`
  - Active-mode bitstream for Flash address `0x00000000`
  - SHA256 `C06330F7937BF71D975E08B615A6EEC09BAC003F61DA65E85F1FF1AE56F366D5`
- `deploy/128x96_styles/firmware/tinyml_style_128x96_hudclean_6598C2BD.bin`
  - Firmware; loads all three models from Flash when DDR is empty
  - SHA256 `6598C2BDF3EB7DE36B42F98178A05D020CEA5BEAC2C5567362152E2E7626712C`
  - Size `25,490 B`; RAM `30,080 / 126,976 B`
- `artifacts/ti60f225_128x96_three_styles_hudclean_D5CB066F_flash.hex`
  - Complete cold-boot image containing bitstream, firmware and three models
  - SHA256 `D5CB066F84004D5C68EBBDD7CFDFB5C0721A317DDF31AAAF020F0466E4A551E1`

The previous validated `AF7C7FB6…` bitstream and `BAEC05E6…` Flash image remain
in `artifacts/` as rollback references.

### Style-intensity implementation

- Display mode `3` computes
  `mixed = original + (styled - original) * strength / 255`.
- Strength register: APB `0xA4`, range `0..255`; endpoints exactly reproduce
  original and styled pixels.
- Rendering cost: 3 x 18x18 DSP, 126 FF, 162 LUT, 0 RAM.
- Efinity PnR: XLR `57,036 / 60,800 (93.81%)`, Memory `251 / 256`,
  DSP `108 / 160`; Setup WNS `+0.169 ns`, Hold WHS `+0.008 ns`.

Flash layout:

| Address | Content |
|---:|---|
| `0x00000000` | bitstream |
| `0x00380000` | firmware |
| `0x003A0000` | Future model |
| `0x003B0000` | Van Gogh model |
| `0x003C0000` | Cubism model |

The board-validated way to program the complete image at `0x00000000` is the
Efinity Programmer GUI:

- Mode: plain `JTAG2SPI` (not x8)
- Flash Selection is greyed out / unavailable in this mode; that is expected.
  Plain JTAG2SPI uses the single Flash directly. Do not switch to x8 just to
  select `Lower`.
- Flash: Winbond W25Q64, JEDEC `EF6017`, 3-byte addressing
- Image address: `0x00000000`

The command-line helper `tools/program_flash.py` is available for diagnosis,
but it is not the validated production path. It validates the SHA256, loads
the bundled JTAG bridge, writes the image, and requires read-back verification.
Equivalent manual commands are:

```powershell
D:\Efinity\2026.1\pgm\bin\ftdi_pgm.bat -m jtag `
  -u "ftdi://0x0403:0x6011:0:ff/1" `
  -b "Generic Board Profile Using FT4232H" `
  --jtag_clock_freq 1000000 `
  D:\Efinity\2026.1\pgm\fli\titanium\u10660A79.bit

D:\Efinity\2026.1\pgm\bin\ftdi_pgm.bat -m jtag_bridge `
  -u "ftdi://0x0403:0x6011:0:ff/1" `
  -b "Generic Board Profile Using FT4232H" `
  --jtag_clock_freq 500000 `
  --address 0 --jtag_bridge_mode all --verify_method hostx1 `
  artifacts\ti60f225_128x96_three_styles_hudclean_D5CB066F_flash.hex
```

A valid write must report both `Flash verify successful` and
`JTAG2SPI programming...done`. Do not use SPI Active. Do not use
`--burst_size 256`: it left every alternate 256-byte page erased in testing.

The SoC SPI pins must remain connected as follows:

- `GPIOL_P_03`: Flash DI/DO (IO0)
- `GPIOL_N_03`: Flash IO1
- `GPIOL_N_01`: Flash clock
- `GPIOL_P_01`: Flash chip select

Current three-style models are under `deploy/128x96_styles/models/`:

- Future: Flash `0x003A0000`, DDR `0x04000000`
- Van Gogh: Flash `0x003B0000`, DDR `0x04010000`
- Cubism: Flash `0x003C0000`, DDR `0x04020000`

## Program over JTAG

```powershell
python tools/program_bitstream.py
python tools/load_multistyle.py
```

`load_multistyle.py` preloads all three model blobs through OpenOCD before
starting the firmware. The new firmware detects valid preloaded models and
skips Flash access; when models are absent, it loads them from the Flash
addresses above. These commands do not write Flash.

## Controls

- Power-on default: interpolation mode at strength 255 (100% style)
- KEY0 / `GPIOL_07`: cycle Future -> Van Gogh -> Cubism (no long-press function)
- KEY1 / `GPIOR_22`: full styled, press again for split compare
- KEY2 / `GPIOR_21`: style strength +16
- KEY3 / `GPIOL_03` / A3: style strength -16
- KEY2/KEY3 adjustment shows a borderless lower-centre Chinese HUD and strength bar for about 3.5 s
- FPS OSD is hidden while interpolation mode is active
- No physical or UART switch to full original
- UART `1/2/3`: select style
- UART `0/5/6`: split / styled / interpolation
- UART `+/-`: intensity step +/-16; `i`: report intensity

## Contents

- `rtl/`, `ip/`: synthesizable hardware sources and IP
- `embedded_sw/`: generated SoC BSP and software support
- `tb/`: testbenches
- `tools/`: JTAG programming, Flash-image merging and firmware/model loading scripts
- `deploy/128x96_styles/`: current models, firmware, previews and manifest
- `artifacts/`: current bitstream/firmware/Flash image plus previous rollback artifacts

Generated directories are not included. Build outputs will be created by
Efinity when the flow is run.

## Firmware project

The standalone Eclipse/Efinity RISC-V firmware project is included at:

`firmware/tinyml_style/`

It uses this clean project's local BSP:

`embedded_sw/my_soc/bsp/efinix/EfxSapphireSoc`

Production defaults are already enabled in `firmware/tinyml_style/makefile`:

- `STYLE_NET_RUN_FRAME=19`
- `STYLE_NET_STREAM=1`
- `STYLE_NET_MULTI_STYLE=1`

Build from a terminal:

```powershell
cd firmware/tinyml_style
python build_multistyle.py
```

Outputs:

- `build/tinyml_style.bin`
- `build/tinyml_style.elf`
- `build/tinyml_style.hex`
- `build/tinyml_style.map`

To rebuild the complete Flash image after a bitstream/firmware update:

```powershell
python tools/build_flash_image.py `
  --bitstream-hex artifacts/ti60f225_oob_128x96_hudclean_C06330F7.hex `
  --firmware-bin firmware/tinyml_style/build/tinyml_style.bin `
  --styles-dir deploy/128x96_styles/models `
  --output artifacts/ti60f225_128x96_three_styles_hudclean_D5CB066F_flash.hex
```

The project can also be imported into Efinity RISC-V IDE as the existing
`tinyml_style` project. The IDE launch file and include paths point to the BSP
inside this clean project.
