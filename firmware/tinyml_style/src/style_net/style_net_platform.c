#include "style_net_platform.h"

/* ==========================================================================
 * Host build (unit test / CI)
 * ========================================================================== */
#ifdef STYLE_NET_HOST_TEST

static uint32_t s_flush_count;
static void (*s_wait_hook)(void);
static uint32_t s_invalidate_count;
static uint64_t s_time;

void style_net_host_reset_counters(void)
{
    s_flush_count = 0u;
    s_invalidate_count = 0u;
    s_time = 0u;
}

uint32_t style_net_host_flush_count(void) { return s_flush_count; }

void style_net_host_set_wait_hook(void (*hook)(void)) { s_wait_hook = hook; }
uint32_t style_net_host_invalidate_count(void) { return s_invalidate_count; }

uint32_t style_net_mmio_read(const volatile uint32_t *reg) { return *reg; }
void style_net_mmio_write(volatile uint32_t *reg, uint32_t value) { *reg = value; }

void style_net_cache_flush(const void *addr, uint32_t bytes)
{
    (void)addr;
    (void)bytes;
    s_flush_count++;
}

void style_net_cache_invalidate(const void *addr, uint32_t bytes)
{
    (void)addr;
    (void)bytes;
    s_invalidate_count++;
}

/* The host timer advances on every read so the scheduler timeout path is
 * exercised deterministically without sleeping. */
uint64_t style_net_time_now(void) { return s_time++; }

void style_net_idle(void)
{
    if (s_wait_hook != NULL) {
        s_wait_hook();
    }
}

/* ==========================================================================
 * RISC-V firmware build (Sapphire SoC BSP)
 * ========================================================================== */
#else

#include "bsp.h"
#include "vexriscv.h"

uint32_t style_net_mmio_read(const volatile uint32_t *reg)
{
    return *reg;
}

void style_net_mmio_write(volatile uint32_t *reg, uint32_t value)
{
    *reg = value;
}

/*
 * IMPORTANT - open hardware item.
 *
 * The Sapphire BSP exposes only a D-cache *invalidate* (vexriscv.h:
 * data_cache_invalidate_all / data_cache_invalidate_address), not a clean /
 * write-back.  On a write-back D-cache an invalidate discards dirty lines,
 * so it must NOT be used to publish CPU stores to the accelerator DMA.
 *
 * Until that is resolved on the board, the activation arena is expected to be
 * either
 *   (a) produced by the FPGA video pipeline (not written by the CPU), or
 *   (b) mapped through a non-cacheable window,
 * and STYLE_NET_ARENA_UNCACHED is defined to 1 so these hooks compile to a
 * no-op instead of silently destroying data.
 *
 * If the D-cache turns out to be write-through on this SoC, set
 * STYLE_NET_ARENA_UNCACHED to 0 and both hooks map onto the invalidate.
 */
#ifndef STYLE_NET_ARENA_UNCACHED
#define STYLE_NET_ARENA_UNCACHED 1
#endif

void style_net_cache_flush(const void *addr, uint32_t bytes)
{
    (void)addr;
    (void)bytes;
#if STYLE_NET_ARENA_UNCACHED
    /* Arena bypasses the D-cache: nothing to write back. */
#else
    /* Write-through cache: invalidate is sufficient and also drops any
     * stale read lines the CPU may still hold. */
    data_cache_invalidate_all();
#endif
}

void style_net_cache_invalidate(const void *addr, uint32_t bytes)
{
    (void)addr;
    (void)bytes;
#if !STYLE_NET_ARENA_UNCACHED
    /* Accelerator writes are visible to the CPU only after the stale lines
     * are dropped. */
    data_cache_invalidate_all();
#endif
}

uint64_t style_net_time_now(void)
{
    return clint_getTime(BSP_CLINT);
}

void style_net_idle(void)
{
    /* Safe on both interrupt and polling paths.  Replace with a WFI
     * once the accelerator IRQ is verified on the board. */
    __asm__ volatile ("nop");
}

#endif
