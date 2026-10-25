# Ti60F225 StyleCam Clean 工程结构说明

本文档面向最终归档、交接和重新构建，说明 `Ti60f225_sc431hai2hdmi_v6_clean`
中哪些文件是源码与交付产物，哪些目录只是 Efinity/IDE 重新运行后生成的可删除缓存。

## 1. 工程定位

- FPGA：Efinix Titanium Ti60F225，Efinity 2026.1
- 视频输入：SC431HAI MIPI CSI-2
- 处理分辨率：128×96
- 风格网络：19-pass INT8 TinyML，三风格 Future / Van Gogh / Cubism
- 显示：640×480 HDMI，5× 最近邻显示块
- 默认状态：强度插值模式，强度 255（100% 风格化）
- 配置 Flash：Winbond W25Q64，普通 `JTAG2SPI` 烧录

## 2. 顶层文件

| 文件/目录 | 作用 | 必须提交 |
|---|---|---|
| `ti60f225_oob.xml` | Efinity 工程入口，定义 top module、HDL 文件、IP 和综合/PnR 参数 | 是 |
| `ti60f225_oob.peri.xml` | 引脚、时钟、GPIO、SPI Flash、DDR 等外围约束 | 是 |
| `ti60f225_oob.sdc` | 时序约束 | 是 |
| `rtl/ti60f225_oob_top.v` | FPGA 顶层，连接 SoC、视频通路、风格加速器、OSD/HUD 和 HDMI | 是 |
| `debug_top.v` / `debug.json` / `debug_profile.wizard.json` | Efinity 调试/EDB 配置 | 是 |
| `package_settings.xml` | Efinity 打包设置 | 是 |
| `README_CLEAN.md` | 工程快速入口、产物和烧录方法 | 是 |
| `STYLE_INTENSITY.md` | 强度插值、HUD、按键和验证说明 | 是 |
| `PROJECT_STRUCTURE.md` | 本文件 | 是 |
| `artifacts/` | 已验证位流、固件和完整 Flash 镜像 | 是 |
| `deploy/` | 部署模型、当前固件、manifest、预览和风格参考图 | 是 |
| `firmware/tinyml_style/` | RISC-V 固件工程及模型目录 | 是 |
| `rtl/` | FPGA RTL | 是 |
| `ip/` | SoC、AXI crossbar、CSI/DSI 等 Efinity IP | 是 |
| `embedded_sw/` | 固件使用的 SoC BSP；虽然可生成，最终源码包需要保留 | 是 |
| `tools/` | 烧录、加载、Flash 合并、HUD 字库生成脚本 | 是 |
| `tb/` | RTL 仿真 testbench 和运行脚本 | 是 |
| `outflow*/`、`work_*/`、`ooc/` | Efinity 中间产物 | 否，重新生成 |
| `firmware/tinyml_style/build/` | 固件编译输出（ELF/BIN/HEX/MAP 等） | 是，必须保留 |

> clean 工程是最终发布副本，不是 Git 仓库。若要重新放入 Git，需注意现有
> `.gitignore` 会忽略 `*.bit`、`*.hex` 和 `/embedded_sw/`，归档时必须保留这些文件。

## 3. 顶层目录树

```text
Ti60f225_sc431hai2hdmi_v6_clean/
├─ artifacts/                     # 已验证交付产物
├─ deploy/128x96_styles/          # 三风格部署目录
│  ├─ firmware/                   # 当前固件 + 历史回退固件
│  ├─ models/                     # Future / Van Gogh / Cubism
│  ├─ preview/                    # 风格预览图
│  ├─ style-images/               # 训练风格参考图
│  ├─ manifest.json               # 产物哈希、Flash/DDR 地址、控制说明
│  └─ README.md                   # 部署说明
├─ embedded_sw/                   # SoC BSP，固件编译依赖
├─ firmware/tinyml_style/         # RISC-V 固件工程
│  ├─ src/
│  │  ├─ main.c                   # 启动、模型加载、按键/UART、连续帧调度
│  │  ├─ style_net/               # 加速器 ABI、IRQ、调度和地址映射
│  │  ├─ model/                   # 多风格模型目录/校验
│  │  └─ common/                  # 启动、trap、syscall
│  ├─ styles/128x96/              # 三模型 blob 和布局说明
│  ├─ .project / .cproject        # Efinity RISC-V IDE 工程
│  ├─ makefile
│  └─ build_multistyle.py         # 可复现固件构建脚本
├─ ip/                            # Efinity IP
├─ rtl/                           # FPGA RTL
├─ tb/                            # 仿真 testbench
├─ tools/                         # 构建/烧录/加载工具
├─ ti60f225_oob.xml               # Efinity 工程入口
├─ ti60f225_oob.peri.xml          # 引脚/外围约束
├─ ti60f225_oob.sdc               # 时序约束
├─ README_CLEAN.md
├─ STYLE_INTENSITY.md
└─ PROJECT_STRUCTURE.md
```

## 4. RTL 结构

### 4.1 顶层与视频主通路

- `rtl/ti60f225_oob_top.v`
  - 连接 MIPI RX、debayer、帧缓存、缩放器、风格加速器、OSD/HUD 和 HDMI
  - 实例化 `style_accel_apb`、`style_accel_top`、`style_mix_3ch`
  - 实例化 `video_scale_block`、`fps_overlay`、`style_hud_overlay`
- `rtl/scale/`
  - `video_scaler_top.v`：最近邻缩放
  - `video_scale_out.v`：缩放 + FIFO + 640×480 输出光栅
  - `video_out_timing.v`：输出时序
  - `video_scaler_bilinear.v`：备用双线性缩放
  - `fps_overlay.v`：左上角 FPS OSD；插值模式时旁路
  - `style_hud_font.v`：HUD 用 16×16 中文字形 ROM
  - `style_hud_overlay.v`：中下方无黑底强度 HUD

### 4.2 风格迁移加速器

`rtl/style_accel/`：

- `style_accel_top.v`：加速器顶层，连接 AXI master、网络核心和参数加载
- `style_net_core.v`：19-pass INT8 网络核心
- `style_net_axi_master.v`：从 DDR 读取输入、回写输出
- `style_param_loader.v` / `style_weight_bram.v`：权重/InstanceNorm 参数
- `conv3x3_stage_lanes.v` / `conv3x3_zp_lanes.v`：卷积流水线
- `line_buffer_3x3_bp.v` / `reflect_pad1_stream.v`：行缓存和 reflect padding
- `norm_param_core.v` / `stats_accum_core.v`：InstanceNorm
- `requant_relu_core.v` / `requant_pipe_core.v`：重量化和激活
- `axi4_pixel_read.v` / `axi4_pixel_write.v`：像素 AXI 传输
- `style_accel_apb.v` / `style_accel_cmd_regs.v`：RISC-V 可见的 APB 寄存器
- `style_net_axi_if.vh`：AXI 参数和错误码
- `style_mix_3ch.v`：原画/风格化三通道强度混合，3 个 18×18 DSP

### 4.3 其它 RTL

- `rtl/cam/`、`rtl/cam_i2c_ctrl/`：摄像头 I2C 配置
- `rtl/debayer/`：RAW/Bayer 转 RGB
- `rtl/frame_buffer_V3/`：帧缓存和 FIFO
- `rtl/ddr3_controller/`：DDR3 控制器
- `rtl/dvi_tx/`、`rtl/efx_dsi_tx.sv`：DVI/HDMI/DSI 发送
- `rtl/mipi_config/`、`rtl/csi_rx_controller.sv`：MIPI 配置与 CSI-2 接收
- `rtl/soc_oob/`：SoC 外围连接
- `rtl/gamma_conrrection/`：历史 gamma 模块，当前主通路不实例化

## 5. 固件结构

`firmware/tinyml_style/`：

- `src/main.c`
  - 初始化 BSP
  - 从 Flash 检查/搬运三个模型到 DDR
  - 启动连续 19-pass 推理
  - KEY/UART 控制
  - 默认设置显示模式 `3`、强度 `255`
- `src/style_net/`
  - `style_net_accel.h`：寄存器与 ABI
  - `style_net_scheduler.c`：逐 pass 调度
  - `style_net_platform.c`：MMIO、缓存和延时
  - `style_net_irq.c`：加速器中断
  - `style_net_memory_map.h`：DDR 地址布局
- `src/model/`
  - `style_multistyle.c/.h`：三风格目录、Flash 地址、哈希校验
- `styles/128x96/`
  - `future/style_model.bin`
  - `vangogh/style_model.bin`
  - `cubism/style_model.bin`
  - 每个模型 53,808 B

固件构建：

```powershell
cd firmware/tinyml_style
python build_multistyle.py
```

固定参数：

```text
STYLE_NET_RUN_FRAME=19
STYLE_NET_STREAM=1
STYLE_NET_MULTI_STYLE=1
```

当前已验证输出：

- `.bin` 25,490 B
- RAM 30,080 / 126,976 B
- SHA256 `6598C2BDF3EB7DE36B42F98178A05D020CEA5BEAC2C5567362152E2E7626712C`

## 6. 部署目录

`deploy/128x96_styles/`：

- `manifest.json`：当前版本、哈希、Flash/DDR 地址和按键说明
- `README.md`：部署、烧录和板级验证
- `firmware/`：当前固件和历史回退固件
- `models/`：三风格模型、QAT/INT8 文件、布局和 pass table
- `preview/`：模型预览图
- `style-images/`：训练用风格参考图

当前固件文件：

```text
deploy/128x96_styles/firmware/tinyml_style_128x96_hudclean_6598C2BD.bin
```

## 7. 当前交付产物

| 类型 | 文件 | SHA256 |
|---|---|---|
| JTAG/SRAM 位流 | `artifacts/ti60f225_oob_128x96_hudclean_6071F0BA.bit` | `6071F0BAEEA09E7DDCC62BD859913A0F05E3CE89F961BB973615170D7412174F` |
| Active HEX | `artifacts/ti60f225_oob_128x96_hudclean_C06330F7.hex` | `C06330F7937BF71D975E08B615A6EEC09BAC003F61DA65E85F1FF1AE56F366D5` |
| 固件 | `deploy/128x96_styles/firmware/tinyml_style_128x96_hudclean_6598C2BD.bin` | `6598C2BDF3EB7DE36B42F98178A05D020CEA5BEAC2C5567362152E2E7626712C` |
| 完整 Flash | `artifacts/ti60f225_128x96_three_styles_hudclean_D5CB066F_flash.hex` | `D5CB066F84004D5C68EBBDD7CFDFB5C0721A317DDF31AAAF020F0466E4A551E1` |

Flash 布局：

| 地址 | 内容 |
|---:|---|
| `0x00000000` | 位流 |
| `0x00380000` | 固件 |
| `0x003A0000` | Future |
| `0x003B0000` | Van Gogh |
| `0x003C0000` | Cubism |

## 8. 工具脚本

`tools/`：

- `program_bitstream.py`：JTAG 下载被动位流
- `load_multistyle.py`：OpenOCD 预载三模型和固件
- `program_flash.py`：普通 JTAG2SPI 烧录完整 Flash 镜像
- `build_flash_image.py`：位流 + 固件 + 三模型的完整 Flash HEX 合并
- `gen_style_hud_font.py`：从 Windows SimHei 生成 16×16 HUD 字库

Flash 合并示例：

```powershell
python tools/build_flash_image.py `
  --bitstream-hex artifacts/ti60f225_oob_128x96_hudclean_C06330F7.hex `
  --firmware-bin firmware/tinyml_style/build/tinyml_style.bin `
  --styles-dir deploy/128x96_styles/models `
  --output artifacts/ti60f225_128x96_three_styles_hudclean_D5CB066F_flash.hex
```

## 9. 仿真入口

- `tb/run_scaler_sim.bat`：视频缩放、输出时序、FPS OSD 回归
- `tb/run_style_mix_sim.bat`：三通道强度混合，524,288 像素检查
- `tb/run_hud_sim.bat`：中文 HUD、强度条、无黑底和时序检查
- `tb/tb_style_net_*.v`：风格网络 AXI/核心仿真
- `tb/tb_video_qin_writer_128x96.v` / `tb_video_qout_reader_128x96.v`：128×96
  DDR 读写路径

## 10. 编译缓存与保留规则

以下目录可由工具重新生成，但**不要在未确认时自动删除**；其中固件 `build/` 是用户编译产物，必须保留：

```text
outflow/
outflow_*/
work_syn/
work_syn_*/
work_pnr/
work_pnr_*/
work_interface_*/
work_dbg/
ooc/
tools/__pycache__/
tb/*.vvp
*.vcd
*.wlf
```

重新打开 Efinity 或构建固件后，这些目录会再次出现，属于正常现象。

不要删除：

```text
artifacts/
deploy/
rtl/
ip/
embedded_sw/
firmware/tinyml_style/（含 build/ 编译输出）
tb/
tools/
ti60f225_oob.xml
ti60f225_oob.peri.xml
ti60f225_oob.sdc
debug_top.v
debug.json
debug_profile.wizard.json
package_settings.xml
README_CLEAN.md
STYLE_INTENSITY.md
PROJECT_STRUCTURE.md
```

## 11. 最终归档建议

当前目录包含最终 artifacts、回退产物和固件 `build/` 编译文件；文件数与体积会随 IDE/编译状态变化。

1. 确认上述交付产物 SHA256。
2. 保留 `firmware/tinyml_style/build/`；不要自动删除用户编译文件。
3. 不要删除 `embedded_sw/` 和 `artifacts/` 中的 `.bit/.hex`。
4. 打包为 ZIP，包内保留完整目录树。
5. 如果改用 Git 管理，需要调整 `.gitignore`：
   - 允许 `artifacts/*.bit`、`artifacts/*.hex`
   - 取消忽略 `embedded_sw/`
   - 不要忽略 `firmware/tinyml_style/build/`；它是用户要求保留的编译输出

## 12. 当前控制摘要

- 默认：强度插值，强度 255
- KEY0 / `GPIOL_07` / C4：循环三风格，无长按
- KEY1 / `GPIOR_22` / P14：全屏风格化 ↔ 左右对比
- KEY2 / `GPIOR_21` / N14：强度 +16
- KEY3 / `GPIOL_03` / A3：强度 -16
- UART：`1/2/3` 选风格，`0/5/6` 选显示模式，`+/-` 调强度，`i` 读取
- 强度 HUD：中下方中文提示 + 强度条，约 3.5 秒，无黑底
- 插值模式期间 FPS OSD 关闭