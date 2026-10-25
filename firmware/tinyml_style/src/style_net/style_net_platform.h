#ifndef STYLE_NET_PLATFORM_H
#define STYLE_NET_PLATFORM_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Platform seam for the style-transfer accelerator driver.
 *
 * Two builds share this header:
 *   - RISC-V firmware (default): maps onto the Sapphire SoC BSP.
 *   - Host unit test (-DSTYLE_NET_HOST_TEST): deterministic stubs, so the
 *     scheduler logic can be exercised on a PC without a board.
 */

/* 32-bit MMIO accessors.  Always volatile: the accelerator registers must not
 * be cached in a CPU register across a poll loop. */
uint32_t style_net_mmio_read(const volatile uint32_t *reg);
void     style_net_mmio_write(volatile uint32_t *reg, uint32_t value);

/*
 * Cache maintenance for the DMA-visible activation arena.
 *
 * style_net_cache_flush()      CPU writes -> visible to the accelerator DMA.
 * style_net_cache_invalidate() accelerator DMA writes -> visible to the CPU.
 *
 * Both take the whole cache on this platform (single instruction), which is
 * cheaper than walking a 12 MB arena line by line.
 */
void style_net_cache_flush(const void *addr, uint32_t bytes);
void style_net_cache_invalidate(const void *addr, uint32_t bytes);

/* Monotonic free-running counter (CLINT mtime).  Used for timeouts and for
 * per-frame cycle accounting. */
uint64_t style_net_time_now(void);

/* Called once per polling iteration while waiting for the accelerator.
 * On the board this is a safe NOP today (switch to WFI once the interrupt
 * path is proven); on the host it dispatches the registered test hook so a
 * blocking wait can be unit tested. */
void style_net_idle(void);

#ifdef STYLE_NET_HOST_TEST
/* Hook invoked from style_net_idle(); used to simulate the accelerator
 * finishing during a blocking wait. */
void style_net_host_set_wait_hook(void (*hook)(void));
#endif

#ifdef STYLE_NET_HOST_TEST
/* Instrumentation used by the host scheduler test. */
void     style_net_host_reset_counters(void);
uint32_t style_net_host_flush_count(void);
uint32_t style_net_host_invalidate_count(void);
#endif

#ifdef __cplusplus
}
#endif

#endif
