#include "style_net_scheduler.h"

#include "style_net_irq.h"
#include "style_net_platform.h"
#include "style_net_pass_table.h"
#include "style_net_memory_map.h"

#include <stddef.h>

/*
 * Board bring-up trace (off by default).
 *
 * Enable with:  make all STYLE_NET_RUN_FRAME=2 STYLE_NET_TRACE=1
 *
 * It prints one short line per step of style_net_run_pass() plus a periodic
 * status/cycle sample inside the completion wait, so the UART -- the only
 * channel that has been reliable on this board -- shows exactly which step
 * the pass dies on.
 *
 * NOTE: the BSP printf supports only %c %s %d %X %x (no %u, no field width).
 */
#if defined(STYLE_NET_TRACE) || defined(STYLE_NET_PROFILE_MIN)
#ifndef STYLE_NET_HOST_TEST
#include "bsp.h"
#endif
#define STYLE_NET_TRACE_P(...) bsp_printf(__VA_ARGS__)
#else
#define STYLE_NET_TRACE_P(...) do { } while (0)
#endif
/* How often the [W] spin trace fires (mask on a free-running counter).
 * 0x3FFFF (262144 polls) was too coarse: the CPU froze before the first line
 * ever printed, so the UART went silent right after [E2] with no clue where.
 * 0x7FF prints every 2048 polls, which lands well inside the freeze window and
 * still stops by itself when the CPU dies.  Override with
 * -DSTYLE_NET_TRACE_SPIN_MASK=0xNNNN if you need a different cadence. */
#ifndef STYLE_NET_TRACE_SPIN_MASK
#define STYLE_NET_TRACE_SPIN_MASK 0x7FFu
#endif

#ifndef STYLE_NET_DEFAULT_TIMEOUT_CYCLES
/* 200e6 CLINT ticks is ~2 s at the 100 MHz SoC clock. */
#define STYLE_NET_DEFAULT_TIMEOUT_CYCLES 200000000u
#endif

static volatile uint32_t *reg_at(volatile uint32_t *base, uint32_t off)
{
    return base + (off / 4u);
}

static void write_pass(const style_net_ctx_t *ctx, const style_net_pass_t *pass)
{
    volatile uint32_t *a = ctx->accel;

    style_net_mmio_write(reg_at(a, STYLE_NET_REG_PASS_ID), pass->pass_id);
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_STAGE_ID), pass->stage_id);
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_OP), pass->op);
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_IC), pass->ic);
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_OC), pass->oc);
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_IN_W), pass->in_w);
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_IN_H), pass->in_h);
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_OUT_W), pass->out_w);
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_OUT_H), pass->out_h);
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_STRIDE), pass->stride);
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_UPSAMPLE), pass->upsample);
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_PAD_MODE), pass->pad_mode);

    style_net_mmio_write(reg_at(a, STYLE_NET_REG_WEIGHT_BASE),
                         (uint32_t)(ctx->model_base + pass->weight_base));
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_W_SCALE_BASE),
                         (uint32_t)(ctx->model_base + pass->w_scale_base));
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_BIAS_BASE),
                         (uint32_t)(ctx->model_base + pass->bias_base));
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_GAMMA_BASE),
                         (uint32_t)(ctx->model_base + pass->gamma_base));
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_BETA_BASE),
                         (uint32_t)(ctx->model_base + pass->beta_base));
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_QUANT_IN_BASE),
                         (uint32_t)(ctx->model_base + pass->quant_in_base));
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_QUANT_MID_BASE),
                         (uint32_t)(ctx->model_base + pass->quant_mid_base));
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_QUANT_OUT_BASE),
                         (uint32_t)(ctx->model_base + pass->quant_out_base));

    {
        uint32_t input_base = (uint32_t)(ctx->arena_base + pass->input_base);
        uint32_t output_base = (uint32_t)(ctx->arena_base + pass->output_base);
        if (pass->flags & STYLE_NET_FLAG_RAW_CONSUME)
            input_base = (uint32_t)STYLE_NET_RAW_SCRATCH_BASE;
        if (pass->flags & STYLE_NET_FLAG_RAW_PRODUCE)
            output_base = (uint32_t)STYLE_NET_RAW_SCRATCH_BASE;

        style_net_mmio_write(reg_at(a, STYLE_NET_REG_INPUT_BASE), input_base);
        if (((uint32_t)pass->pass_id + 1u == (uint32_t)style_net_pass_count) &&
            (ctx->output_override != 0u)) {
            style_net_mmio_write(reg_at(a, STYLE_NET_REG_OUTPUT_BASE),
                                 (uint32_t)ctx->output_override);
        } else {
            style_net_mmio_write(reg_at(a, STYLE_NET_REG_OUTPUT_BASE), output_base);
        }
    }
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_RESIDUAL_BASE),
                         (uint32_t)(ctx->arena_base + pass->residual_base));
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_STATS_BASE),
                         (uint32_t)(ctx->arena_base + pass->stats_base));

    style_net_mmio_write(reg_at(a, STYLE_NET_REG_LANES), pass->lanes);
    /* Bring-up diagnostic: -DSTYLE_NET_FLAGS_OVERRIDE=0x05 makes every pass a
     * read-only stats pass, which isolates the compute/write path from the
     * read+loader path on the board. */
#ifdef STYLE_NET_FLAGS_OVERRIDE
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_FLAGS), STYLE_NET_FLAGS_OVERRIDE);
#else
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_FLAGS), pass->flags);
#endif
}

static uint32_t ctrl_irq_bit(const style_net_ctx_t *ctx)
{
    return (ctx->use_irq != 0u) ? STYLE_NET_CTRL_IRQ_EN : 0u;
}

/* Unified completion wait.
 *
 * The accelerator IRQ is only an optimisation: the loop always compares the
 * ISR sequence counter first and falls back to polling STATUS, so a board
 * with the interrupt line not yet wired still completes correctly. */
static int wait_done(const style_net_ctx_t *ctx, uint32_t irq_seq)
{
    const uint64_t start = style_net_time_now();
#ifdef STYLE_NET_TRACE
    uint32_t spin = 0u;
#endif

    for (;;) {
        const uint32_t status =
            style_net_mmio_read(reg_at(ctx->accel, STYLE_NET_REG_STATUS));

        if (style_net_irq_count() != irq_seq) {
            return (style_net_irq_status() & STYLE_NET_STATUS_ERROR)
                       ? STYLE_NET_ERR_ACCEL
                       : STYLE_NET_OK;
        }
        if (status & STYLE_NET_STATUS_ERROR) {
            return STYLE_NET_ERR_ACCEL;
        }
        if (status & STYLE_NET_STATUS_DONE) {
            return STYLE_NET_OK;
        }
        if (ctx->timeout_cycles != 0u &&
            (style_net_time_now() - start) >= ctx->timeout_cycles) {
            return STYLE_NET_ERR_TIMEOUT;
        }
        style_net_idle();
#ifdef STYLE_NET_TRACE
        /* Every ~256k polls, show whether the accelerator is still moving.
         * `cyc` is the accelerator's own cycle counter (0x74), not the CPU's. */
        if ((++spin & STYLE_NET_TRACE_SPIN_MASK) == 0u) {
            STYLE_NET_TRACE_P("[W] spin=%d st=%x cyc=%x dbg=%x\r\n", (int)spin,
                              (unsigned)status,
                              (unsigned)style_net_mmio_read(
                                  reg_at(ctx->accel, STYLE_NET_REG_CYCLES_LO)),
                              (unsigned)style_net_mmio_read(
                                  reg_at(ctx->accel, STYLE_NET_REG_DBG)));
        }
#endif
    }
}

const char *style_net_status_str(int status)
{
    switch (status) {
    case STYLE_NET_OK:          return "ok";
    case STYLE_NET_ERR_NULL:    return "null argument";
    case STYLE_NET_ERR_BUSY:    return "accelerator busy";
    case STYLE_NET_ERR_TIMEOUT: return "timeout";
    case STYLE_NET_ERR_ACCEL:   return "accelerator error";
    case STYLE_NET_ERR_ABI:     return "ABI mismatch";
    case STYLE_NET_ERR_RANGE:   return "pass index out of range";
    case STYLE_NET_ERR_BLOB:    return "model blob invalid";
    default:                    return "unknown";
    }
}

void style_net_ctx_init(style_net_ctx_t *ctx,
                        volatile uint32_t *accel,
                        uintptr_t model_base,
                        uintptr_t arena_base)
{
    if (ctx == NULL) {
        return;
    }
    ctx->accel = accel;
    ctx->model_base = model_base;
    ctx->arena_base = arena_base;
    ctx->arena_size = STYLE_NET_ARENA_SIZE;
    ctx->timeout_cycles = STYLE_NET_DEFAULT_TIMEOUT_CYCLES;
    ctx->use_irq = 1u;
    ctx->last_pass_id = 0u;
    ctx->last_frame_cycles = 0u;
    ctx->output_override = 0u;
}

int style_net_probe(const style_net_ctx_t *ctx)
{
    uint32_t version;
    uint32_t passes;

    if (ctx == NULL || ctx->accel == NULL) {
        return STYLE_NET_ERR_NULL;
    }

    version = style_net_mmio_read(reg_at(ctx->accel, STYLE_NET_REG_VERSION));
    passes = style_net_mmio_read(reg_at(ctx->accel, STYLE_NET_REG_PASS_COUNT));

    if (version != STYLE_NET_ABI_VERSION ||
        passes != style_net_pass_count) {
        return STYLE_NET_ERR_ABI;
    }
    return STYLE_NET_OK;
}

int style_net_load_model(style_net_ctx_t *ctx, const void *blob, uint32_t bytes)
{
    volatile uint32_t *dst;
    const uint32_t *src;
    uint32_t words;
    uint32_t i;

    if (ctx == NULL || ctx->accel == NULL || blob == NULL) {
        return STYLE_NET_ERR_NULL;
    }
    if (bytes == 0u || (bytes & 3u) != 0u) {
        return STYLE_NET_ERR_BLOB;
    }

    dst = (volatile uint32_t *)ctx->model_base;
    src = (const uint32_t *)blob;
    words = bytes / 4u;

    for (i = 0; i < words; ++i) {
        dst[i] = src[i];
    }
    for (i = 0; i < words; ++i) {
        if (dst[i] != src[i]) {
            return STYLE_NET_ERR_BLOB;
        }
    }

    /* Publish the blob to the accelerator's DMA view. */
    style_net_cache_flush((const void *)ctx->model_base, bytes);
    return STYLE_NET_OK;
}

int style_net_run_pass(style_net_ctx_t *ctx, uint32_t pass_id)
{
    volatile uint32_t *a;
    uint32_t status;
    uint32_t irq_seq;
    int rc;

    if (ctx == NULL || ctx->accel == NULL) {
        return STYLE_NET_ERR_NULL;
    }
    if (pass_id >= (uint32_t)style_net_pass_count) {
        return STYLE_NET_ERR_RANGE;
    }

    a = ctx->accel;
    STYLE_NET_TRACE_P("[A] run_pass=%d\r\n", (int)pass_id);
    status = style_net_mmio_read(reg_at(a, STYLE_NET_REG_STATUS));
    STYLE_NET_TRACE_P("[B] status=%x\r\n", (unsigned)status);
    if (status & STYLE_NET_STATUS_BUSY) {
        return STYLE_NET_ERR_BUSY;
    }

    style_net_mmio_write(reg_at(a, STYLE_NET_REG_CTRL),
                         STYLE_NET_CTRL_CLEAR | ctrl_irq_bit(ctx));
    write_pass(ctx, &style_net_pass_table[pass_id]);
    /* PASS_ID is the only descriptor register the block reads back, so it is a
     * cheap proof that the APB write path took the 26 descriptor writes. */
    STYLE_NET_TRACE_P("[C] desc done, pass_id reg=%x\r\n",
                      (unsigned)style_net_mmio_read(
                          reg_at(a, STYLE_NET_REG_PASS_ID)));

    /* The input tensor for this pass lives in DDR; make sure the accelerator
     * sees the producer's writes before START. */
    style_net_cache_flush((const void *)ctx->arena_base, ctx->arena_size);
    STYLE_NET_TRACE_P("[D] arena flushed\r\n");

    irq_seq = style_net_irq_count();
    /* Bracket the START write with debug-bundle reads: [D2] is the state
     * before, [E0] is the loader/top state the moment the pass kicks off.
     * If only [D2] appears, the CPU died inside the CTRL write. */
    STYLE_NET_TRACE_P("[D2] dbg=%x\r\n",
                      (unsigned)style_net_mmio_read(
                          reg_at(a, STYLE_NET_REG_DBG)));
#ifdef STYLE_NET_START_DELAY_CYCLES
    /* Bench hook for the shared FTDI/JTAG chain: the Efinity logic analyser and
     * OpenOCD cannot be attached at the same time, so the analyser is armed
     * first (JTAG free after OpenOCD detaches) and this hold-off gives it time
     * to be armed before the accelerator issues its first AXI read.  The value
     * is in CLINT ticks: 100 MHz -> 1 tick = 10 ns. */
    {
        const uint64_t t0 = style_net_time_now();
        STYLE_NET_TRACE_P("[D3] start held off for logic analyser\r\n");
        while ((style_net_time_now() - t0) <
               (uint64_t)STYLE_NET_START_DELAY_CYCLES) {
            style_net_idle();
        }
        STYLE_NET_TRACE_P("[D4] starting now\r\n");
    }
#endif
    style_net_mmio_write(reg_at(a, STYLE_NET_REG_CTRL),
                         STYLE_NET_CTRL_START | ctrl_irq_bit(ctx));
    /* Keep the post-START probes separate: the START write and the two status
     * reads are three independent APB transactions, and on this board one of
     * them is what wedges the CPU's bus. */
    STYLE_NET_TRACE_P("[E0] dbg=%x\r\n",
                      (unsigned)style_net_mmio_read(
                          reg_at(a, STYLE_NET_REG_DBG)));
    STYLE_NET_TRACE_P("[E1] st=%x\r\n",
                      (unsigned)style_net_mmio_read(reg_at(a, STYLE_NET_REG_STATUS)));
    STYLE_NET_TRACE_P("[E2] cyc=%x\r\n",
                      (unsigned)style_net_mmio_read(reg_at(a, STYLE_NET_REG_CYCLES_LO)));

    rc = wait_done(ctx, irq_seq);
#ifdef STYLE_NET_PROFILE_MIN
    STYLE_NET_TRACE_P("P%d cyc=%x\r\n", (int)pass_id,
                      (unsigned)style_net_mmio_read(
                          reg_at(a, STYLE_NET_REG_CYCLES_LO)));
#endif
    STYLE_NET_TRACE_P("[F] done rc=%d st=%x cyc=%x irq=%d dbg=%x\r\n", (int)rc,
                      (unsigned)style_net_mmio_read(reg_at(a, STYLE_NET_REG_STATUS)),
                      (unsigned)style_net_mmio_read(reg_at(a, STYLE_NET_REG_CYCLES_LO)),
                      (int)style_net_irq_count(),
                      (unsigned)style_net_mmio_read(reg_at(a, STYLE_NET_REG_DBG)));

    /* Drop stale lines so a CPU read of the result sees the accelerator's
     * output rather than cached intermediates. */
    style_net_cache_invalidate((const void *)ctx->arena_base, ctx->arena_size);

    style_net_mmio_write(reg_at(a, STYLE_NET_REG_CTRL),
                         STYLE_NET_CTRL_CLEAR | ctrl_irq_bit(ctx));

    return rc;
}

int style_net_run_passes_from(style_net_ctx_t *ctx, uint32_t first, uint32_t count)
{
    const uint64_t start = style_net_time_now();
    uint32_t pass_id;

    if (ctx == NULL || ctx->accel == NULL) {
        return STYLE_NET_ERR_NULL;
    }
    if (first >= (uint32_t)style_net_pass_count) {
        return STYLE_NET_ERR_RANGE;
    }
    if (first + count > (uint32_t)style_net_pass_count) {
        count = (uint32_t)style_net_pass_count - first;
    }
    for (pass_id = first; pass_id < first + count; ++pass_id) {
        int rc = style_net_run_pass(ctx, pass_id);

        ctx->last_pass_id = pass_id;
        if (rc != STYLE_NET_OK) {
            return rc;
        }
    }

    ctx->last_frame_cycles = style_net_time_now() - start;
    return STYLE_NET_OK;
}

int style_net_run_passes(style_net_ctx_t *ctx, uint32_t count)
{
    /* Bring-up diagnostic: -DSTYLE_NET_FIRST_PASS=N starts at pass N.  The
     * firmware can also override first/count at runtime from a DDR magic word,
     * so an IDE rebuild (which drops these -D flags) cannot clobber an
     * experiment; see the runtime override in main.c. */
#ifndef STYLE_NET_FIRST_PASS
#define STYLE_NET_FIRST_PASS 0u
#endif
    return style_net_run_passes_from(ctx, (uint32_t)STYLE_NET_FIRST_PASS, count);
}

int style_net_run_frame(style_net_ctx_t *ctx)
{
    return style_net_run_passes(ctx, (uint32_t)style_net_pass_count);
}



