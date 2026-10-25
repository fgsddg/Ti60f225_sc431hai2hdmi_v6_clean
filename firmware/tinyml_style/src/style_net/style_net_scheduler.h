#ifndef STYLE_NET_SCHEDULER_H
#define STYLE_NET_SCHEDULER_H

#include <stdint.h>

#include "style_net_accel.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Status codes returned by every driver entry point.  Negative = error. */
typedef enum {
    STYLE_NET_OK          =  0,
    STYLE_NET_ERR_NULL    = -1,
    STYLE_NET_ERR_BUSY    = -2,
    STYLE_NET_ERR_TIMEOUT = -3,
    STYLE_NET_ERR_ACCEL   = -4,
    STYLE_NET_ERR_ABI     = -5,
    STYLE_NET_ERR_RANGE   = -6,
    STYLE_NET_ERR_BLOB    = -7
} style_net_status_t;

typedef struct {
    volatile uint32_t *accel;        /* MMIO base of style_accel_cmd_regs  */
    uintptr_t          model_base;   /* packed INT8 blob, DDR              */
    uintptr_t          arena_base;   /* activation arena, DDR              */
    uint32_t           arena_size;   /* bytes                              */
    uint32_t           timeout_cycles; /* 0 = wait forever                 */
    uint32_t           use_irq;        /* 1 = raise IRQ_EN per pass        */
    uint32_t           last_pass_id;   /* updated by run_frame             */
    uint64_t           last_frame_cycles;
    /* Non-zero = absolute DDR address used for the final pass output.  This
     * is the q_out ping-pong hook; intermediate passes keep their table
     * offsets inside the arena. */
    uintptr_t          output_override;
} style_net_ctx_t;

/* Fill in a context.  arena_size defaults to STYLE_NET_ARENA_SIZE and the
 * timeout to STYLE_NET_DEFAULT_TIMEOUT_CYCLES; override before use if the
 * board memory map differs. */
void style_net_ctx_init(style_net_ctx_t *ctx,
                        volatile uint32_t *accel,
                        uintptr_t model_base,
                        uintptr_t arena_base);

/* Human readable form of a style_net_status_t, for UART logging. */
const char *style_net_status_str(int status);

/* Read VERSION / PASS_COUNT and confirm they match this firmware build. */
int style_net_probe(const style_net_ctx_t *ctx);

/* Copy the packed model blob into model_base, verify it, and publish it to
 * the accelerator (cache flush). */
int style_net_load_model(style_net_ctx_t *ctx, const void *blob, uint32_t bytes);

/* Program one pass descriptor, pulse START and wait for DONE. */
int style_net_run_pass(style_net_ctx_t *ctx, uint32_t pass_id);

/* Run the first `count` passes (clamped to the table); updates
 * last_pass_id / last_frame_cycles.  Use count = STYLE_NET_PASS_COUNT for a
 * whole frame, or 2 for the L5 q_in -> q1 bring-up check. */
int style_net_run_passes(style_net_ctx_t *ctx, uint32_t count);

/* Same, but starting at an explicit pass.  Board bring-up reads the pass range
 * from a DDR magic word and calls this, so the range is not compiled in. */
int style_net_run_passes_from(style_net_ctx_t *ctx, uint32_t first, uint32_t count);

/* Run all passes for one frame; updates last_pass_id / last_frame_cycles. */
int style_net_run_frame(style_net_ctx_t *ctx);

#ifdef __cplusplus
}
#endif

#endif

