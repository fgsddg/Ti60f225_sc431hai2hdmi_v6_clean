# Ti60F225 128x96 multi-style models

三套 19-pass INT8 模型 blob，供 `STYLE_NET_MULTI_STYLE=1` 固件预加载到 DDR：

| UART | 风格 | DDR base | model | SHA256 |
|---|---|---|---|---|
| `1` | Future | `0x04000000` | `future/style_model.bin` | `F5318822...6F9E1E` |
| `2` | Van Gogh | `0x04010000` | `vangogh/style_model.bin` | `0F27D4B8...D9465` |
| `3` | Cubism（Three-dimensional） | `0x04020000` | `cubism/style_model.bin` | `D7744666...6B5216` |

- 每个 blob 均为 **53,808 B**，槽位间隔 64 KiB。
- 三套模型共用同一份 19-pass 表和 128×96 arena 布局。
- 固件不内嵌模型：JTAG 流程由 OpenOCD 预加载；Flash 冷启动时固件通过 SoC SPI0 从 `0x003A0000/0x003B0000/0x003C0000` 搬到 DDR。
- FNV-1a 与 SHA256 的完整值见 `manifest.json`。
- Cubism 的训练/导出源名为 `Three-dimensional`，工程内统一使用 `cubism` 作为选择键。

构建：

```powershell
cd D:/efinity_prj/DemoBoard/Ti60F225_DemoBoard_v4/Ti60f225_sc431hai2hdmi_v6_clean/firmware/tinyml_style
python build_multistyle.py
```

脚本会校验三个 blob、构建 19-pass 连续流固件并打印 SHA256。
