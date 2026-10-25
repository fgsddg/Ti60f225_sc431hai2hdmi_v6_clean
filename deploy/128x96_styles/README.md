# Ti60F225 128x96 三风格热切换

本目录把 **Future / Van Gogh / Cubism（训练源名 Three-dimensional）** 三套
128x96@19-pass INT8 模型和固件收进主工程。支持完整 Flash 冷启动的版本为：

- `artifacts/ti60f225_oob_128x96_hudclean_6071F0BA.bit`
- SHA256 `6071F0BAEEA09E7DDCC62BD859913A0F05E3CE89F961BB973615170D7412174F`
- 固件 `firmware/tinyml_style_128x96_hudclean_6598C2BD.bin`
- 完整 Flash 镜像 `artifacts/ti60f225_128x96_three_styles_hudclean_D5CB066F_flash.hex`

上一版 `AF7C7FB6… / 91D2A5C2… / BAEC05E6…` 保留作回退。

## 设计

三套模型共用同一份 19-pass 表和 arena 布局，固件在 DDR 中保留三个互不重叠的
模型槽位：

| UART | 风格 | DDR base | model blob |
|---|---|---|---|
| `1` | Future | `0x04000000` | 53,808 B |
| `2` | Van Gogh | `0x04010000` | 53,808 B |
| `3` | Cubism | `0x04020000` | 53,808 B |

多风格固件不内嵌模型，只内嵌风格目录、Flash 地址和校验值，因此镜像为
**25,490 B**，RISC-V RAM 使用 **30,080 / 126,976 B（25.06%）**。Flash
冷启动时固件通过 SoC SPI0 把三个模型搬到 DDR；JTAG 已预载有效模型时则跳过
Flash 搬运。单风格固件仍保留，Future 版本可精确复现 `4913994C…`。

## Flash 冷启动镜像

完整冷启动镜像的地址布局：

| Flash 地址 | 内容 |
|---:|---|
| `0x00000000` | 位流 |
| `0x00380000` | 固件 |
| `0x003A0000` | Future 模型 |
| `0x003B0000` | Van Gogh 模型 |
| `0x003C0000` | Cubism 模型 |

烧录文件：`artifacts/ti60f225_128x96_three_styles_hudclean_D5CB066F_flash.hex`，起始地址
`0x00000000`。验证过的 GUI 配置是普通 `JTAG2SPI`；该模式下
`Flash Selection` 灰显/不可选是正常的，默认直接使用单片 Flash。
不要为了选 `Lower` 而切到 `JTAG2SPI x8`。不要选 SPI Active。
`--burst_size 256` 实测会隔页漏写，禁止使用。

SoC SPI0 已连到配置 Flash：

- `GPIOL_P_03`：Flash DI/DO
- `GPIOL_N_03`：Flash IO1
- `GPIOL_N_01`：Flash CLK
- `GPIOL_P_01`：Flash CS

## 首次加载

板子掉电后 JTAG SRAM 位流会丢失。已实测命令行可直接恢复：

```powershell
cd D:/efinity_prj/DemoBoard/Ti60F225_DemoBoard_v4/Ti60f225_sc431hai2hdmi_v6_clean
python tools/program_bitstream.py
```

该脚本校验 `6071F0BA…` 的 SHA256，临时设置 `creset_before_jtag_config=true`，
以 **1 MHz JTAG** 下载位流，结束后恢复原 `hw_tools.json`。此前 6 MHz 下载会停在
`CONFIGURATION_FAIL`；GUI / JTAG 仍可作为回退方式。不要选 SPI Active。

位流恢复后加载三模型和固件：

```powershell
cd D:/efinity_prj/DemoBoard/Ti60F225_DemoBoard_v4/Ti60f225_sc431hai2hdmi_v6_clean
python tools/load_multistyle.py
```

脚本会：

1. 校验三套模型的 SHA256。
2. OpenOCD `halt`（不使用 `reset halt`）。
3. 将三套模型分别加载到 `0x04000000/0x04010000/0x04020000`。
4. 将固件加载到 `0x00001000`，设置 PC 并 `resume`。

如果 OpenOCD 报 `dtmcontrol=0xffffffff`，说明位流已丢失，先运行
`tools/program_bitstream.py`（或使用 Efinity Programmer GUI）恢复位流。

## 板级验证

> 以下为 2026-10-24 历史版本记录。当前版本默认 `mix / strength=255`，
> KEY0 仅切风格，KEY2/KEY3 调节强度，已取消全屏原画切换。

2026-10-24 已完成按键引脚修正版的实板烧录与切换验证。

- 烧录前 JTAG IDCODE `0x10660A79`，`dtmcontrol=0xffffffff`，确认 SRAM
  位流已丢失；随后 `0210B889…` 以 CRESET + 1 MHz JTAG 烧录 PASS。
- 新固件 `5656C490…`：21,914 B，RAM `26,490 / 126,976 B`。
- OpenOCD 加载 Future / Van Gogh / Cubism 三模型和新固件 PASS。
- 启动确认 `key1: GPIOR_22 level=1; key2: GPIOR_21 level=1`，
  默认 `display mode: split compare`。
- UART `4 -> 5 -> 0` 实测分别进入原画、风格化、左右对比。
- 实体 KEY1/KEY2 实测 PASS：
  - KEY1：全屏原画，再按返回左右对比；
  - KEY2：全屏风格化，再按返回左右对比。
- 验证后已恢复到 Future + 左右对比。
- OSD 按显示源选择帧率：全屏原画直接统计相机 VSYNC，左右对比/全屏风格化显示 19-pass 处理帧率；
- 30 fps 相机配置位流 `35A31C8D…` 已烧录，三模型和固件重新加载 PASS；
  当前为 Future + 全屏原画，OSD 的 30 fps 目视确认待反馈。
  `FPS xx.x` 周围不再画黑色背景框，只保留白色文字。
- UART 上电校验：Future / Van Gogh / Cubism 三个槽位均 `OK`。
- UART 实测风格切换：
  - `2` → `style selected: vangogh (model @0x04010000)`
  - `3` → `style selected: cubism (model @0x04020000)`
  - `1` → `style selected: future (model @0x04000000)`
  - `?` → 菜单正常
- 连续流 compute-only 帧周期约 `7.30–7.35M cycles`，约 **13.6 fps**；
  端到端 OSD 为 **9.9–10.0 fps**。

## 左右对比显示

- 最终 640×480 像素流直接按列选择，不使用第二份画面或额外帧缓存：
  - `x < 320`：左侧显示原画 `scaled_rgb`
  - `x >= 320`：右侧显示风格化 `block_rgb`
- q_out reader 和风格化缩放块直接使用原画 `scaled_de/hs/vs`，两半共用同一 genlocked raster；
  左路只增加 1 拍像素延迟用于流水对齐。
- 左右两半来自同一空间坐标，因此切换风格时左右对应关系不变。
- KEY0 与 UART 风格切换均保留，帧率 OSD 仍叠加在左上角。

## 帧率 OSD

屏幕左上角显示的是所选显示源的实际帧率，不是 HDMI 显示器刷新率：

- 全屏原画（显示模式 `1`）：在 `i_mipi_rx_pclk` 域检测相机
  `w_mipi_rx_vs` 上升沿，翻转一个电平并通过两级同步器送到
  `hdmi_tx_slow_clk`，再还原为单拍脉冲。因此显示的是**相机真实出帧率**
  （当前配置预期约 30.0 fps）；
- 左右对比（模式 `0`）和全屏风格化（模式 `2`）：以 `qout_bank_sel` 翻转为帧脉冲，
  即每完成并发布一帧 19-pass 风格化结果计一次；
- 帧脉冲进入 OSD 后统一用 `24.75 MHz / 帧周期` 计算并显示 `FPS xx.x`；
- 不能用 `scaled_fdone` 代替原画帧率：它跟随 DDR 帧缓存后的自由振荡 60 Hz
  读光栅，相机 30 fps 时同一帧会被读两遍，OSD 会错误显示 60.0；
- SC431HAI 当前曝光寄存器原为 `0x3E00..2 = 0x01BBF0`，会把实际帧率拖到约
  12.6 fps；已恢复原 30 fps 配置 `0x00BAD0`（`0x3E00=0x00`、
  `0x3E01=0xBA`、`0x3E02=0xD0`）。
- 风格化通路实测 OSD 为 **9.9–10.0 fps**，不是显示器的约 58.9 fps；
  背景黑框已关闭，只保留白色 `FPS xx.x` 文字。
- 注意：`13.6 fps` 是仅按 19-pass 计算周期 `7.33M cycles/frame` 换算的
  compute-only 数值；完整环路还要等待下一帧 q_in 抓取，端到端实测为 **10.0 fps**
  （串口 11.18 s / 112 帧 = 10.018 fps）。

## 按键映射

| 按键 | 引脚 | 功能 |
|---|---|---|
| KEY0 | `GPIOL_07` / C4 | 循环 Future → Van Gogh → Cubism，无长按功能 |
| KEY1 | `GPIOR_22` / P14 | 全屏风格化 ↔ 左右对比 |
| KEY2 | `GPIOR_21` / N14 | 强度 +16 |
| KEY3 | `GPIOL_03` / A3 | 强度 -16 |

- 默认上电直接进入插值模式，默认强度 255（100% 风格化）。
- 不再提供物理或 UART 全屏原画切换；UART `0`=对比、`5`=全屏风格、`6`=插值。
- 四键均由 RTL 10 ms 消抖；KEY1/KEY2/KEY3 状态和事件位于 APB `0x9C`。
- 引脚依据 `01_Ti60F225_Key_led_osc_demo/01_Ti60F225_key_demo` 确认。
- KEY3 使用 `GPIOL_03`（A3），不与配置 Flash 的 `GPIOL_P_03/N_03` 冲突。
- KEY2/KEY3 调整时显示中下方无黑底 `强度调节：` + 强度条约 3.5 秒。
- 插值模式下 FPS OSD 关闭。

## 风格强度插值

显示端逐像素计算：

```text
mixed = original + (styled - original) * strength / 255
```

- `strength` 为 APB `0xA4`，范围 `0..255`。
- `0` 精确等于原画，`255` 精确等于全屏风格化。
- 每个像素 3 通道加权，使用 3 个 18x18 DSP，附加 126 FF / 162 LUT / 0 RAM。
- 最终资源：XLR `57,036 / 60,800 (93.81%)`、Memory `251 / 256`、
  DSP `108 / 160`。
- 时序：Setup WNS `+0.169 ns`，Hold WHS `+0.008 ns`。
- 仿真：`tb/tb_style_mix_3ch.v`，524,288 个像素级检查全部通过。

## 运行切换

UART：`COM6 @115200`。启动日志应出现：

```text
style 1: future @0x4000000 OK (53808 bytes)
style 2: vangogh @0x4010000 OK (53808 bytes)
style 3: cubism @0x4020000 OK (53808 bytes)
style selected: future
style hot-switch: UART 1=future 2=vangogh 3=cubism
```

直接发送单字符：

- `1` / `f`：Future
- `2` / `v`：Van Gogh
- `3` / `c`：Cubism
- `6` / `m`：强度插值模式
- `+/-`：强度加/减 16；`i`：读取强度
- `?`：打印菜单

切换在帧边界生效，不会打断正在执行的 19-pass 帧。模型槽位不会互相覆盖，
不需要重新加载固件。

本工程固件：

```powershell
cd D:/efinity_prj/DemoBoard/Ti60F225_DemoBoard_v4/Ti60f225_sc431hai2hdmi_v6_clean/firmware/tinyml_style
python build_multistyle.py
```

固定构建条件：`STYLE_NET_RUN_FRAME=19 STYLE_NET_STREAM=1
STYLE_NET_MULTI_STYLE=1`。当前源码可复现
`6598C2BDF3EB7DE36B42F98178A05D020CEA5BEAC2C5567362152E2E7626712C`。

完整 Flash 镜像由工程根目录执行：

```powershell
python tools/build_flash_image.py `
  --bitstream-hex artifacts/ti60f225_oob_128x96_hudclean_C06330F7.hex `
  --firmware-bin firmware/tinyml_style/build/tinyml_style.bin `
  --styles-dir deploy/128x96_styles/models `
  --output artifacts/ti60f225_128x96_three_styles_hudclean_D5CB066F_flash.hex
```
## 单风格回退

`firmware/*_legacy.bin` 是三套已验证的单风格固件，可直接烧到 `0x00001000`。
其中：

- Future：`4913994C…`
- Van Gogh：`5E867354…`
- Cubism：`29792982…`

## 目录

- `firmware/`：多风格固件 + 三套单风格回退固件
- `models/<style>/`：QAT 模型、INT8 npz、模型 blob、pass table、布局
- `preview/`：amber 对比图
- `style-images/`：训练用风格参考图
- `manifest.json`：SHA256、FNV-1a、DDR 地址和构建参数
