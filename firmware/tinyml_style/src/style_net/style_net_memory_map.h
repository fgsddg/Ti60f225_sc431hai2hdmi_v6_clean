#ifndef STYLE_NET_MEMORY_MAP_H
#define STYLE_NET_MEMORY_MAP_H

/*
 * Platform defaults for the first integration.  Override these macros from
 * the TinyML board configuration once the final address map is fixed.
 */

#ifndef STYLE_NET_MODEL_BASE
#define STYLE_NET_MODEL_BASE 0x04000000u
#endif

#ifndef STYLE_NET_ARENA_BASE
#define STYLE_NET_ARENA_BASE 0x04800000u
#endif

#ifndef STYLE_NET_ACCEL_BASE
#define STYLE_NET_ACCEL_BASE 0xf8100000u
#endif

/* Transient int32 conv-output scratch used by the p0/p1 raw validation.
 * The configured 960x1080x32-bit 3-frame buffer spans
 * 0x01000000..0x01BDDE00. Board tests showed that neither 0x02000000 nor
 * 0x02800000 is safe for transient scratch (stale image data appeared there),
 * so use 0x03000000, still below model (0x04000000) and arena (0x04800000). */
#ifndef STYLE_NET_RAW_SCRATCH_BASE
#define STYLE_NET_RAW_SCRATCH_BASE 0x03000000u
#endif

/* Double-buffered final q_out rasters.  BANK0 is the historical accelerator
 * output address (arena + STYLE_NET_OFFSET_Q_OUT).  BANK1 sits just past the
 * activation arena, so a completed frame remains on screen while the next
 * frame is written to the other bank. */
#ifndef STYLE_NET_QOUT_BANK0_ADDR
#define STYLE_NET_QOUT_BANK0_ADDR 0x04AC8800u
#endif
#ifndef STYLE_NET_QOUT_BANK1_ADDR
#define STYLE_NET_QOUT_BANK1_ADDR 0x04B20000u
#endif

/*
 * PLIC gateway the accelerator IRQ line is wired to.
 *
 * The generated Sapphire SoC for this project exposes userInterruptA at PLIC
 * gateway 16, and it does not instantiate the Efinix TinyML accelerator
 * (CustomInstruction = 0), so gateway 16 is free.  The top level wires
 *     style_accel_apb.irq  ->  <soc>.userInterruptA
 * Change this to match whatever the generated SoC IP exposes.
 */
#ifndef STYLE_NET_PLIC_IRQ_ID
#define STYLE_NET_PLIC_IRQ_ID 16u
#endif

#endif
