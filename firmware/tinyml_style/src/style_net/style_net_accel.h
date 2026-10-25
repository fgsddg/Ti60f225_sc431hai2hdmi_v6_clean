#ifndef STYLE_NET_ACCEL_H
#define STYLE_NET_ACCEL_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Software-facing ABI for the first style-transfer accelerator revision.
 *
 * The RISC-V core owns model loading and pass-level scheduling.  For each
 * pass it programs this register block, sets START, and waits for DONE.
 * The data path consumes the configuration and streams one complete pass.
 */

#define STYLE_NET_ABI_VERSION 0x00010001u

#define STYLE_NET_REG_CTRL             0x00u
#define STYLE_NET_REG_STATUS           0x04u
#define STYLE_NET_REG_ERROR            0x08u
#define STYLE_NET_REG_PASS_ID          0x0Cu
#define STYLE_NET_REG_STAGE_ID         0x10u
#define STYLE_NET_REG_OP               0x14u
#define STYLE_NET_REG_IC               0x18u
#define STYLE_NET_REG_OC               0x1Cu
#define STYLE_NET_REG_IN_W             0x20u
#define STYLE_NET_REG_IN_H             0x24u
#define STYLE_NET_REG_OUT_W            0x28u
#define STYLE_NET_REG_OUT_H            0x2Cu
#define STYLE_NET_REG_STRIDE           0x30u
#define STYLE_NET_REG_UPSAMPLE         0x34u
#define STYLE_NET_REG_PAD_MODE         0x38u
#define STYLE_NET_REG_WEIGHT_BASE      0x3Cu
#define STYLE_NET_REG_W_SCALE_BASE     0x40u
#define STYLE_NET_REG_BIAS_BASE        0x44u
#define STYLE_NET_REG_GAMMA_BASE       0x48u
#define STYLE_NET_REG_BETA_BASE        0x4Cu
#define STYLE_NET_REG_QUANT_IN_BASE    0x50u
#define STYLE_NET_REG_QUANT_MID_BASE   0x54u
#define STYLE_NET_REG_QUANT_OUT_BASE   0x58u
#define STYLE_NET_REG_INPUT_BASE       0x5Cu
#define STYLE_NET_REG_OUTPUT_BASE      0x60u
#define STYLE_NET_REG_RESIDUAL_BASE    0x64u
#define STYLE_NET_REG_STATS_BASE       0x68u
#define STYLE_NET_REG_LANES            0x6Cu
#define STYLE_NET_REG_FLAGS            0x70u
#define STYLE_NET_REG_CYCLES_LO        0x74u
#define STYLE_NET_REG_CYCLES_HI        0x78u
#define STYLE_NET_REG_PASS_COUNT       0x7Cu
#define STYLE_NET_REG_VERSION          0x80u

/* Bring-up debug bundle (top/loader FSM state, loader AXI handshake). */
#define STYLE_NET_REG_DBG              0x84u

/* Video-stream mailbox.
 * VIDEO_FRAME_COUNT increments after the q_in writer receives the AXI write
 * response for source line 95, so the value only changes once q_in is a
 * complete, stable frame.  VIDEO_CTRL[0] selects the q_out display bank; the
 * RTL latches it at video VS to prevent mid-frame mixing. */
#define STYLE_NET_REG_VIDEO_FRAME_COUNT 0x88u
#define STYLE_NET_REG_VIDEO_CTRL        0x8Cu
#define STYLE_NET_VIDEO_CTRL_QOUT_BANK  (1u << 0)

/* KEY0 (GPIOL_07) is debounced in RTL. Reading 0x98 clears the event bit;
 * bit 0 is a one-shot active-low press event, bit 1 is the stable level. */
#define STYLE_NET_REG_KEY0_STATUS       0x98u
#define STYLE_NET_KEY0_EVENT            (1u << 0)
#define STYLE_NET_KEY0_LEVEL            (1u << 1)

/* KEY1/KEY2 (GPIOR_22 / GPIOR_21), debounced in RTL. Reading 0x9C clears
 * both event bits. */
#define STYLE_NET_REG_KEY12_STATUS      0x9Cu
#define STYLE_NET_KEY1_EVENT            (1u << 0)
#define STYLE_NET_KEY1_LEVEL            (1u << 1)
#define STYLE_NET_KEY2_EVENT            (1u << 2)
#define STYLE_NET_KEY2_LEVEL            (1u << 3)
#define STYLE_NET_KEY3_EVENT            (1u << 4)
#define STYLE_NET_KEY3_LEVEL            (1u << 5)

/* Display mux: 0=left/right compare, 1=full original, 2=full styled,
 * 3=full-screen original/style intensity blend. */
#define STYLE_NET_REG_DISPLAY_MODE      0xA0u
#define STYLE_NET_DISPLAY_SPLIT         0u
#define STYLE_NET_DISPLAY_ORIGINAL      1u
#define STYLE_NET_DISPLAY_STYLED        2u
#define STYLE_NET_DISPLAY_MIX           3u

/* Display-side style interpolation strength: 0=original, 255=styled. */
#define STYLE_NET_REG_STYLE_STRENGTH    0xA4u
#define STYLE_NET_REG_HUD               0xA8u
#define STYLE_NET_HUD_ADJUST            1u
#define STYLE_NET_HUD_ON                2u
#define STYLE_NET_HUD_OFF               3u

#define STYLE_NET_CTRL_START           (1u << 0)
#define STYLE_NET_CTRL_IRQ_EN          (1u << 1)
#define STYLE_NET_CTRL_CLEAR           (1u << 2)
#define STYLE_NET_CTRL_ABORT           (1u << 3)
/* Self-test: set DONE without a running datapath (IRQ bring-up). */
#define STYLE_NET_CTRL_FORCE_DONE      (1u << 4)

#define STYLE_NET_STATUS_BUSY          (1u << 0)
#define STYLE_NET_STATUS_DONE          (1u << 1)
#define STYLE_NET_STATUS_ERROR         (1u << 2)

#define STYLE_NET_OP_CONV              1u
#define STYLE_NET_OP_CONV_NORM         2u
#define STYLE_NET_OP_CONV_NORM_RELU    3u
#define STYLE_NET_OP_CONV_TANH         4u
#define STYLE_NET_OP_CONV_RESIDUAL     5u

#define STYLE_NET_PAD_NONE             0u
#define STYLE_NET_PAD_REFLECT          1u

#define STYLE_NET_FLAG_STATS           (1u << 0)
#define STYLE_NET_FLAG_COMPUTE         (1u << 1)
#define STYLE_NET_FLAG_NORM            (1u << 2)
#define STYLE_NET_FLAG_RELU            (1u << 3)
#define STYLE_NET_FLAG_RESIDUAL        (1u << 4)
#define STYLE_NET_FLAG_TANH            (1u << 5)
#define STYLE_NET_FLAG_UPSAMPLE        (1u << 6)
#define STYLE_NET_FLAG_LAST            (1u << 7)
/* p0/p1 raw-int32 validation (outside the arena, 0x03000000 transient scratch). */
#define STYLE_NET_FLAG_RAW_PRODUCE     (1u << 8)
#define STYLE_NET_FLAG_RAW_CONSUME     (1u << 9)

typedef struct {
    uint32_t pass_id;
    uint32_t stage_id;
    uint32_t op;
    uint32_t ic;
    uint32_t oc;
    uint32_t in_w;
    uint32_t in_h;
    uint32_t out_w;
    uint32_t out_h;
    uint32_t stride;
    uint32_t upsample;
    uint32_t pad_mode;
    uint32_t weight_base;
    uint32_t w_scale_base;
    uint32_t bias_base;
    uint32_t gamma_base;
    uint32_t beta_base;
    uint32_t quant_in_base;
    uint32_t quant_mid_base;
    uint32_t quant_out_base;
    uint32_t input_base;
    uint32_t output_base;
    uint32_t residual_base;
    uint32_t stats_base;
    uint32_t lanes;
    uint32_t flags;
} style_net_pass_t;

#ifdef __cplusplus
}
#endif

#endif
