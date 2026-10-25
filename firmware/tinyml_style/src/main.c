#include <stdint.h>

#include "bsp.h"
#include "soc.h"
#include "riscv.h"
#include "style_net_accel.h"
#include "style_net_irq.h"
#include "style_net_memory_map.h"
#include "style_net_pass_table.h"
#include "style_net_platform.h"
#include "style_net_scheduler.h"
#include "style_model_data.h"
#ifdef STYLE_NET_MULTI_STYLE
#include "style_multistyle.h"
#endif

static volatile uint32_t *const accel =
    (volatile uint32_t *)STYLE_NET_ACCEL_BASE;

static style_net_ctx_t ctx;

#ifdef STYLE_NET_MULTI_STYLE
static const style_multistyle_entry_t *active_style;
static unsigned active_style_index;

static void apply_style(unsigned index)
{
    active_style_index = index;
    active_style = &style_multistyle_entries[index];
    ctx.model_base = active_style->model_base;
    bsp_printf("style selected: %s (model @0x%x)\r\n",
               active_style->name, (unsigned)active_style->model_base);
}

static unsigned active_display_mode;
static unsigned active_style_strength;
static unsigned last_key1_level = 2u;
static unsigned last_key2_level = 2u;
static unsigned last_key3_level = 2u;

/* KEY0: cycle styles. KEY1: styled <-> split. KEY2: +16. KEY3: -16. */

static void set_style_strength(unsigned value, int announce)
{
    if (value > 255u)
        value = 255u;
    active_style_strength = value;
    accel[STYLE_NET_REG_STYLE_STRENGTH / 4u] = value;
    if (announce) {
        const unsigned percent = (value * 100u + 127u) / 255u;
        bsp_printf("style strength: %u/255 (%u%%)\r\n", value, percent);
    }
}

static void set_hud(unsigned type)
{
    accel[STYLE_NET_REG_HUD / 4u] = type;
}

static void set_display_mode(unsigned mode)
{
    active_display_mode = mode;
    accel[STYLE_NET_REG_DISPLAY_MODE / 4u] = mode;
    if (mode == STYLE_NET_DISPLAY_ORIGINAL)
        bsp_printf("display mode: original\r\n");
    else if (mode == STYLE_NET_DISPLAY_STYLED)
        bsp_printf("display mode: styled\r\n");
    else if (mode == STYLE_NET_DISPLAY_MIX)
        bsp_printf("display mode: interpolation (%u/255)\r\n",
                   active_style_strength);
    else
        bsp_printf("display mode: split compare\r\n");
}

static void enter_mix_mode(void)
{
    if (active_display_mode != STYLE_NET_DISPLAY_MIX)
        set_display_mode(STYLE_NET_DISPLAY_MIX);
}

static void adjust_style_strength(int delta)
{
    unsigned value;

    enter_mix_mode();
    if (delta > 0) {
        value = active_style_strength + (unsigned)delta;
        if (value > 255u)
            value = 255u;
    } else {
        const unsigned decrease = (unsigned)(-delta);
        value = active_style_strength > decrease
                    ? active_style_strength - decrease
                    : 0u;
    }
    set_style_strength(value, 1);
    set_hud(STYLE_NET_HUD_ADJUST);
}

/* Poll controls only while the accelerator is idle (frame boundaries), so a
 * switch is atomic with respect to a 19-pass frame. */
static void poll_style_switch(void)
{
    while (uart_readOccupancy(BSP_UART_TERMINAL) != 0u) {
        const char c = uart_read(BSP_UART_TERMINAL);
        unsigned index;

        if (c >= '1' && c <= '3') {
            index = (unsigned)(c - '1');
            apply_style(index);
        } else if (c == 'f' || c == 'F') {
            apply_style(0u);
        } else if (c == 'v' || c == 'V') {
            apply_style(1u);
        } else if (c == 'c' || c == 'C') {
            apply_style(2u);
        } else if (c == '0' || c == 'b' || c == 'B') {
            set_display_mode(STYLE_NET_DISPLAY_SPLIT);
        } else if (c == '5' || c == 's' || c == 'S') {
            set_display_mode(STYLE_NET_DISPLAY_STYLED);
        } else if (c == '6' || c == 'm' || c == 'M') {
            enter_mix_mode();
        } else if (c == '+' || c == ']') {
            adjust_style_strength(16);
        } else if (c == '-' || c == '[') {
            adjust_style_strength(-16);
        } else if (c == 'i' || c == 'I') {
            set_style_strength(active_style_strength, 1);
        } else if (c == '?') {
            bsp_printf("styles: 1=future 2=vangogh 3=cubism\r\n");
            bsp_printf("display: 0=split 5=styled 6=mix\r\n");
            bsp_printf("intensity: +/- step 16, i=read\r\n");
            bsp_printf("keys: KEY0=next style; KEY2=+ KEY3=-\r\n");
        }
    }
}

static void poll_key0_control(void)
{
    const uint32_t status = accel[STYLE_NET_REG_KEY0_STATUS / 4u];

    if ((status & STYLE_NET_KEY0_EVENT) != 0u) {
        const unsigned next =
            (active_style_index + 1u) % STYLE_MULTISTYLE_COUNT;
        bsp_printf("key0: next style\r\n");
        apply_style(next);
    }
}

static void poll_display_switch(void)
{
    const uint32_t status = accel[STYLE_NET_REG_KEY12_STATUS / 4u];
    const unsigned key1_level = (status & STYLE_NET_KEY1_LEVEL) != 0u;
    const unsigned key2_level = (status & STYLE_NET_KEY2_LEVEL) != 0u;
    const unsigned key3_level = (status & STYLE_NET_KEY3_LEVEL) != 0u;

    if (key1_level != last_key1_level) {
        bsp_printf("key1: GPIOR_22 level=%d\r\n", (int)key1_level);
        last_key1_level = key1_level;
    }
    if (key2_level != last_key2_level) {
        bsp_printf("key2: GPIOR_21 level=%d\r\n", (int)key2_level);
        last_key2_level = key2_level;
    }
    if (key3_level != last_key3_level) {
        bsp_printf("key3: GPIOL_03 level=%d\r\n", (int)key3_level);
        last_key3_level = key3_level;
    }

    if ((status & STYLE_NET_KEY1_EVENT) != 0u) {
        bsp_printf("key1: styled/split toggle\r\n");
        set_display_mode(active_display_mode == STYLE_NET_DISPLAY_STYLED
                             ? STYLE_NET_DISPLAY_SPLIT
                             : STYLE_NET_DISPLAY_STYLED);
    }
    if ((status & STYLE_NET_KEY2_EVENT) != 0u) {
        bsp_printf("key2: strength +\r\n");
        adjust_style_strength(16);
    }
    if ((status & STYLE_NET_KEY3_EVENT) != 0u) {
        bsp_printf("key3: strength -\r\n");
        adjust_style_strength(-16);
    }
}

static void poll_style_inputs(void)
{
    poll_style_switch();
    poll_key0_control();
    poll_display_switch();
}
#endif

/* Machine trap vector.  The accelerator only needs the external interrupt
 * path; anything else is fatal during bring-up. */
void trap(void)
{
    const int32_t mcause = (int32_t)csr_read(mcause);

    if (mcause < 0 && (mcause & 0x1f) == CAUSE_MACHINE_EXTERNAL) {
        style_net_irq_handler();
        return;
    }

    bsp_printf("FATAL: unexpected trap, mcause=0x%x\r\n", (unsigned)mcause);
    while (1) {
    }
}

static void halt(const char *what, int rc)
{
    bsp_printf("ERROR: %s (%d: %s)\r\n", what, rc, style_net_status_str(rc));
    while (1) {
    }
}

static void apb_readback_test(void)
{
    accel[STYLE_NET_REG_PASS_ID / 4u] = 17u;
    if (accel[STYLE_NET_REG_PASS_ID / 4u] != 17u) {
        bsp_printf("ERROR: APB write/readback failed\r\n");
        while (1) {
        }
    }
    accel[STYLE_NET_REG_PASS_ID / 4u] = 0u;
}

/* L4: confirm the accelerator interrupt actually reaches the CPU.
 *
 * Arms the level interrupt, then uses the register block CTRL[4] self-test
 * bit to set DONE without a running datapath.  The ISR should fire, capture
 * STATUS and clear the source.
 *
 * Every wait here is bounded by an instruction-count guard, so a missing
 * interrupt (or a CLINT that is not ticking) still reports instead of
 * hanging the bring-up.
 *
 * Returns 0 on success, -1 if no interrupt arrived, -2 if the bitstream
 * predates the CTRL_FORCE_DONE self-test bit.
 */
#ifndef STYLE_NET_USE_IRQ
#define STYLE_NET_USE_IRQ 1u
#endif

static int irq_selftest(void)
{
    const uint32_t before = style_net_irq_count();
    uint32_t guard = 0x2000000u;
    uint32_t status;

    accel[STYLE_NET_REG_CTRL / 4u] = STYLE_NET_CTRL_IRQ_EN;
    accel[STYLE_NET_REG_CTRL / 4u] =
        STYLE_NET_CTRL_IRQ_EN | STYLE_NET_CTRL_FORCE_DONE;

    /* Did the self-test bit latch at all?  If the bitstream predates
     * CTRL_FORCE_DONE the DONE flag never appears and there is no point
     * waiting for an interrupt. */
    status = accel[STYLE_NET_REG_STATUS / 4u];
    if ((status & STYLE_NET_STATUS_DONE) == 0u) {
        return -2;
    }

    while (style_net_irq_count() == before) {
        if (--guard == 0u) {
            return -1;
        }
    }
    return 0;
}


#ifdef STYLE_NET_STREAM
#ifndef STYLE_NET_STREAM_TIMEOUT_CYCLES
/* 500e6 CLINT ticks is 5 s at the 100 MHz SoC clock. */
#define STYLE_NET_STREAM_TIMEOUT_CYCLES 500000000u
#endif
#ifndef STYLE_NET_STREAM_REPORT_MASK
#define STYLE_NET_STREAM_REPORT_MASK 0x7u
#endif

/* Wait until q_in contains a new complete frame.  The q_in writer publishes
 * VIDEO_FRAME_COUNT only after line 95 has received its final AXI write
 * response, and captures exactly one frame per accelerator-idle interval. */
static int wait_qin_frame(uint32_t *seen)
{
    const uint64_t t0 = style_net_time_now();
    uint32_t count = accel[STYLE_NET_REG_VIDEO_FRAME_COUNT / 4u];

    if (*seen == 0u) {
        while (count == 0u) {
            if ((style_net_time_now() - t0) >=
                (uint64_t)STYLE_NET_STREAM_TIMEOUT_CYCLES) {
                return STYLE_NET_ERR_TIMEOUT;
            }
#ifdef STYLE_NET_MULTI_STYLE
            poll_style_inputs();
#endif
            style_net_idle();
            count = accel[STYLE_NET_REG_VIDEO_FRAME_COUNT / 4u];
        }
    } else {
        while (count == *seen) {
            if ((style_net_time_now() - t0) >=
                (uint64_t)STYLE_NET_STREAM_TIMEOUT_CYCLES) {
                return STYLE_NET_ERR_TIMEOUT;
            }
#ifdef STYLE_NET_MULTI_STYLE
            poll_style_inputs();
#endif
            style_net_idle();
            count = accel[STYLE_NET_REG_VIDEO_FRAME_COUNT / 4u];
        }
    }

    *seen = count;
    return STYLE_NET_OK;
}

static int run_continuous_frames(void)
{
    uint32_t seen = 0u;
    uint32_t frames = 0u;
    uint32_t bank = 1u;   /* display starts on bank 0; render the first frame to bank 1 */
    int rc;

    bsp_printf("stream: waiting for complete q_in frames\r\n");

    for (;;) {
        rc = wait_qin_frame(&seen);
        if (rc != STYLE_NET_OK) {
            return rc;
        }
#ifdef STYLE_NET_MULTI_STYLE
        poll_style_inputs();
#endif

        ctx.output_override = bank ? STYLE_NET_QOUT_BANK1_ADDR
                                   : STYLE_NET_QOUT_BANK0_ADDR;
        rc = style_net_run_frame(&ctx);
        if (rc != STYLE_NET_OK) {
            return rc;
        }

        /* The final pass has completed and its AXI write responses have been
         * received.  Publish the new bank; the reader latches it at VS. */
        accel[STYLE_NET_REG_VIDEO_CTRL / 4u] =
            bank ? STYLE_NET_VIDEO_CTRL_QOUT_BANK : 0u;
        if ((accel[STYLE_NET_REG_VIDEO_CTRL / 4u] &
             STYLE_NET_VIDEO_CTRL_QOUT_BANK) !=
            (bank ? STYLE_NET_VIDEO_CTRL_QOUT_BANK : 0u)) {
            return STYLE_NET_ERR_ABI;
        }

        frames++;
        if (frames == 1u ||
            (frames & (uint32_t)STYLE_NET_STREAM_REPORT_MASK) == 0u) {
            bsp_printf("stream frame %d: qin=%d cycles=%d bank=%d\r\n",
                       (int)frames, (int)seen,
                       (int)ctx.last_frame_cycles, (int)bank);
        }

        bank ^= 1u;
    }
}
#endif

int main(void)
{
    int rc;

    bsp_init();
    bsp_printf("\r\n-- Efinix TinyML style-transfer deployment --\r\n");

    style_net_ctx_init(&ctx, accel, STYLE_NET_MODEL_BASE, STYLE_NET_ARENA_BASE);
    /* timeout_cycles already comes from STYLE_NET_DEFAULT_TIMEOUT_CYCLES via
     * style_net_ctx_init -- do NOT hard-code it here or the makefile
     * STYLE_NET_TIMEOUT_CYCLES= override is silently ignored. */
    /* Bring-up escape hatch: make STYLE_NET_NO_IRQ=1 sets this to 0, so the
     * accelerator runs with IRQ_EN clear and wait_done() polls STATUS.  That
     * isolates the datapath from the PLIC/IRQ plumbing entirely. */
    ctx.use_irq = STYLE_NET_USE_IRQ;

    rc = style_net_probe(&ctx);
    if (rc != STYLE_NET_OK) {
        halt("accelerator probe", rc);
    }
    /* NOTE: the BSP bsp_printf handles %c %s %d %X %x only. A %u is not
     * recognised and its parser then swallows the rest of the format string,
     * which is why this line used to stop printing after "passes=". */
    bsp_printf("accelerator ABI 0x%x, passes=%d, lanes=%d\r\n",
               (int)accel[STYLE_NET_REG_VERSION / 4u],
               (int)accel[STYLE_NET_REG_PASS_COUNT / 4u],
               (int)style_net_pass_table[0].lanes);

    apb_readback_test();
    bsp_printf("APB register readback OK\r\n");

    /* Route the accelerator IRQ through the PLIC and enable machine
     * external interrupts. */
    style_net_irq_init(accel);
    style_net_irq_reset();
    bsp_printf("accelerator IRQ on PLIC gateway %d\r\n",
               (int)STYLE_NET_PLIC_IRQ_ID);

    /* CLINT sanity: the scheduler timeouts (and the previous self-test)
     * depend on mtime actually ticking on this SoC. */
    {
        const uint32_t t0 = (uint32_t)style_net_time_now();
        volatile uint32_t spin = 0u;
        uint32_t i;

        for (i = 0u; i < 10000u; ++i) {
            spin = spin + i;
        }
        bsp_printf("CLINT mtime: %d -> %d\r\n",
                   (int)t0, (int)(uint32_t)style_net_time_now());
    }

    bsp_printf("IRQ self-test: start\r\n");
    switch (irq_selftest()) {
    case 0:
        bsp_printf("IRQ self-test PASS: count=%d status=0x%x\r\n",
                   (int)style_net_irq_count(),
                   (unsigned)style_net_irq_status());
        break;
    case -2:
        bsp_printf("IRQ self-test SKIP: bitstream has no CTRL_FORCE_DONE\r\n");
        break;
    default:
        bsp_printf("IRQ self-test FAIL: no interrupt (check PLIC wiring)\r\n");
        break;
    }

#ifdef STYLE_NET_MULTI_STYLE
    {
        unsigned i;

        style_multistyle_prepare();

        for (i = 0u; i < STYLE_MULTISTYLE_COUNT; ++i) {
            const style_multistyle_entry_t *entry = &style_multistyle_entries[i];

            if (style_multistyle_verify(entry) != 0) {
                bsp_printf("ERROR: model %s @0x%x hash mismatch\r\n",
                           entry->name, (unsigned)entry->model_base);
                halt("multi-style model verify", STYLE_NET_ERR_BLOB);
            }
            bsp_printf("style %d: %s @0x%x OK (%d bytes)\r\n",
                       (int)(i + 1u), entry->name,
                       (unsigned)entry->model_base, (int)entry->model_bytes);
        }
        apply_style(0u);
        set_style_strength(255u, 0);
        set_display_mode(STYLE_NET_DISPLAY_MIX);
        bsp_printf("style hot-switch: UART 1=future 2=vangogh 3=cubism\r\n");
        bsp_printf("display: default=mix; KEY1=styled/split; UART 0=split 5=styled 6=mix\r\n");
        bsp_printf("intensity: default=255; KEY2=+ KEY3=-; UART +/- step 16\r\n");
        {
            const uint32_t key_status =
                accel[STYLE_NET_REG_KEY0_STATUS / 4u];
            const uint32_t key12_status =
                accel[STYLE_NET_REG_KEY12_STATUS / 4u];
            bsp_printf("key0: GPIOL_07 level=%d, cycles styles\r\n",
                       (int)((key_status & STYLE_NET_KEY0_LEVEL) != 0u));
            last_key1_level =
                (key12_status & STYLE_NET_KEY1_LEVEL) != 0u;
            last_key2_level =
                (key12_status & STYLE_NET_KEY2_LEVEL) != 0u;
            last_key3_level =
                (key12_status & STYLE_NET_KEY3_LEVEL) != 0u;
            bsp_printf("key1: GPIOR_22 level=%d; key2: GPIOR_21 level=%d; key3: GPIOL_03 level=%d\r\n",
                       (int)last_key1_level, (int)last_key2_level,
                       (int)last_key3_level);
        }
    }
#else
    rc = style_net_load_model(&ctx, style_model_blob, style_model_blob_len);
    if (rc != STYLE_NET_OK) {
        halt("model load", rc);
    }
    bsp_printf("model loaded: %d bytes -> 0x%x\r\n",
               (int)style_model_blob_len,
               (unsigned)STYLE_NET_MODEL_BASE);
#endif
    bsp_printf("arena: 0x%x, %d bytes\r\n",
               (unsigned)STYLE_NET_ARENA_BASE,
               (int)STYLE_NET_ARENA_SIZE);

    bsp_printf("pass table: first flags=0x%x last flags=0x%x\r\n",
               (unsigned)style_net_pass_table[0].flags,
               (unsigned)style_net_pass_table[style_net_pass_count - 1u].flags);

#ifdef STYLE_NET_RUN_FRAME
#ifndef STYLE_NET_RUN_PASSES
#define STYLE_NET_RUN_PASSES STYLE_NET_PASS_COUNT
#endif
    #ifndef STYLE_NET_RUNCFG_ADDR
#define STYLE_NET_RUNCFG_ADDR 0x04700000u
#endif
#define STYLE_NET_RUNCFG_MAGIC 0x5A4C3551u   /* written by tools/l5_*.tcl */
    /* The pass range is data, not a compile-time constant.  The Efinity IDE
     * rebuilds this firmware through its own launch configuration and silently
     * drops -DSTYLE_NET_FIRST_PASS / -DSTYLE_NET_RUN_PASSES, which cost several
     * board runs; read [first, count] from a DDR magic word instead. */
    {
        uint32_t first = 0u;
        uint32_t count = STYLE_NET_RUN_PASSES;
        volatile uint32_t *rcfg = (volatile uint32_t *)STYLE_NET_RUNCFG_ADDR;
#ifdef STYLE_NET_WAIT_RUNCFG
        /* Board-only q_in/q1 A/B hook.  Wait until the camera writer has
         * published one complete frame (it then stays disarmed while the
         * accelerator is idle), then park until JTAG supplies a known q_in
         * image and the RUNCFG magic. */
        bsp_printf("debug wait: waiting for complete q_in frame\r\n");
        while (accel[STYLE_NET_REG_VIDEO_FRAME_COUNT / 4u] == 0u) {
            style_net_idle();
        }
        bsp_printf("debug wait: q_in captured; waiting for RUNCFG magic\r\n");
        while (rcfg[0] != STYLE_NET_RUNCFG_MAGIC) {
            style_net_idle();
        }
#endif

#ifdef STYLE_NET_FIRST_PASS
        first = (uint32_t)STYLE_NET_FIRST_PASS;
#endif
        if (rcfg[0] == STYLE_NET_RUNCFG_MAGIC) {
            first = rcfg[1] & 0xFFFFu;
            count = rcfg[2] & 0xFFFFu;
            if (count == 0u) {
                count = 1u;
            }
            bsp_printf("run cfg @0x%x: first=%d count=%d\r\n",
                       (unsigned)STYLE_NET_RUNCFG_ADDR, (int)first, (int)count);
        }
#ifdef STYLE_NET_STREAM
        (void)first;
        (void)count;
        rc = run_continuous_frames();
#else
        rc = style_net_run_passes_from(&ctx, first, count);
#endif
    }
    if (rc != STYLE_NET_OK) {
        halt("run frame", rc);
    }
    bsp_printf("frame complete: %d passes, %d cycles, %d irqs\r\n",
               (int)(ctx.last_pass_id + 1u),
               (int)ctx.last_frame_cycles,
               (int)style_net_irq_count());

    /* Checksum the tensor the last pass wrote so the host can compare against
     * the golden reference over UART, without attaching a debugger.  The
     * per-pixel stride follows the arena layout: align4(oc) bytes. */
    {
        const style_net_pass_t *p = &style_net_pass_table[ctx.last_pass_id];
        const uint32_t stride = (p->oc + 3u) & ~3u;
        const uint32_t len = p->out_h * p->out_w * stride;
        const uint8_t *base =
            (const uint8_t *)(ctx.arena_base + p->output_base);
        uint32_t h = 0x811C9DC5u;
        uint32_t i;

        style_net_cache_invalidate((const void *)base, len);
        for (i = 0u; i < len; ++i) {
            h ^= base[i];
            h = h * 0x01000193u;
        }
        bsp_printf("last output: base=0x%x len=%d fnv1a=0x%x\r\n",
                   (unsigned)(ctx.arena_base + p->output_base),
                   (int)len, (unsigned)h);
    }
#else
    bsp_printf("bring-up complete; define STYLE_NET_RUN_FRAME to run a frame\r\n");
#endif

    while (1) {
    }

    return 0;
}




