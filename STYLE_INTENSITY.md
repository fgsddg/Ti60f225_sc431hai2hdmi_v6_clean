# Ti60F225 风格强度插值

## 功能

显示端把原画和风格化结果按 `a/255` 加权：

```text
mixed = original + (styled - original) * a / 255
```

- `a = 0`：逐位精确回到原画。
- `a = 255`：逐位精确回到全屏风格化。
- `a = 0..255`：三通道统一插值，显示模式为 `3`。

RTL 使用 3 个 18x18 DSP 并行处理 R/G/B，两级流水线。除以 255 用移位/加法
实现，不推断除法器：

```text
floor(x / 255) = (x + 1 + (x >> 8)) >> 8
```

`signed delta` 先加 128 做最近舍入，再恢复符号。

## 按键操作

| 按键 | 引脚 | 功能 |
|---|---|---|
| KEY0 | `GPIOL_07` / C4 | 循环 Future → Van Gogh → Cubism，无长按功能 |
| KEY1 | `GPIOR_22` / P14 | 全屏风格化 ↔ 左右对比 |
| KEY2 | `GPIOR_21` / N14 | 强度 +16 |
| KEY3 | `GPIOL_03` / A3 | 强度 -16 |

- 默认上电直接进入插值模式，默认强度 255（100% 风格化）。
- 不再提供全屏原画切换。
- 四键均由 RTL 10 ms 消抖；KEY1/KEY2/KEY3 状态和事件位于 APB `0x9C`。
- 固件在帧边界处理按键，不打断正在执行的 19-pass 帧。

## HUD 提示

- KEY2/KEY3 每次调整：画面中下方显示约 **3.5 秒**：
  - 中文 `强度调节：`
  - 128 像素宽度的强度条，0 为空、255 为满
- 强度插值模式（显示模式 3）下，左上角 FPS 文本直接旁路关闭。
- 文字和强度条直接叠加，不绘制黑色背景框。
- 字形由 `tools/gen_style_hud_font.py` 生成 16x16 ROM；不占 BRAM。
- HUD 的 3.5 秒计时在 RTL 内完成，不依赖固件轮询。

## UART

`COM6 @ 115200`：

| 输入 | 功能 |
|---|---|
| `6` / `m` | 进入强度插值模式 |
| `+` / `]` | 强度 +16 |
| `-` / `[` | 强度 -16 |
| `i` | 打印当前强度 |
| `0` / `5` | 左右对比 / 全风格 |
| `1/2/3` | Future / Van Gogh / Cubism |
| `?` | 帮助 |

## 寄存器与 ABI

- 显示模式寄存器 `0xA0`：`0=split, 1=original, 2=styled, 3=mix`。
- 强度寄存器 `0xA4[7:0]`：`0..255`，可读写。
- 加速器 ABI 版本从 `0x00010000` 升到 `0x00010001`，固件会在启动时校验。

## 资源与时序

Efinity 2026.1，Ti60F225 I3：

| 项目 | 结果 |
|---|---:|
| 新增混合器 | 3 DSP / 126 FF / 162 LUT / 0 RAM |
| XLR | 57,036 / 60,800（93.81%） |
| Memory | 251 / 256（98.05%） |
| DSP | 108 / 160（67.50%） |
| Setup WNS | +0.169 ns |
| Hold WHS | +0.008 ns |

## 验证

- 运行 `tb\run_style_mix_sim.bat`；`iverilog -g2012` 仿真 `tb/tb_style_mix_3ch.v`：
  **524,288 个像素级检查 PASS**。
- `tb\run_hud_sim.bat`：中文 HUD 的强度条、开启、关闭三种状态均 PASS，视频 307,200 像素/帧时序对齐。
- 覆盖强度 `0/1/64/127/128/192/254/255`、全部 256x256 原画/风格值组合，
  并检查 RGB 三通道、`de/hs/vs` 对齐及端点精确性。
- Efinity map、interface、PnR、bitstream 全部 PASS。
- 固件用 `firmware/tinyml_style/build_multistyle.py` 重建：
  25,490 B，RAM 30,080 / 126,976 B。

## 当前产物

```text
artifacts/ti60f225_oob_128x96_hudclean_6071F0BA.bit
artifacts/ti60f225_oob_128x96_hudclean_C06330F7.hex
deploy/128x96_styles/firmware/tinyml_style_128x96_hudclean_6598C2BD.bin
artifacts/ti60f225_128x96_three_styles_hudclean_D5CB066F_flash.hex
```

SHA256：

```text
6071F0BA...  bitstream
C06330F7...  active-mode Flash bitstream
6598C2BD...  firmware
D5CB066F...  complete Flash image
```

完整 Flash 镜像仍使用普通 `JTAG2SPI`、起始地址 `0x00000000`。不要切 x8，
不要使用 `--burst_size 256`。

## 重建

```powershell
cd firmware/tinyml_style
python build_multistyle.py
cd ../..
python tools/build_flash_image.py `
  --bitstream-hex artifacts/ti60f225_oob_128x96_hudclean_C06330F7.hex `
  --firmware-bin firmware/tinyml_style/build/tinyml_style.bin `
  --styles-dir deploy/128x96_styles/models `
  --output artifacts/ti60f225_128x96_three_styles_hudclean_D5CB066F_flash.hex
```