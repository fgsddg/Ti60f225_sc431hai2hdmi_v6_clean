#include "style_net_irq.h"

#include "style_net_accel.h"
#include "style_net_memory_map.h"
#include "style_net_platform.h"

#ifndef STYLE_NET_HOST_TEST
#include "bsp.h"
#include "riscv.h"
#include "plic.h"

/* Trap vector installed by the application (trap.S).  It must be written
 * to mtvec before any interrupt is enabled. */
extern void trap_entry(void);
#endif

static volatile uint32_t *s_accel;
static volatile uint32_t  s_irq_count;
static volatile uint32_t  s_irq_status;

/* Capture the accelerator STATUS, then deassert the level interrupt.
 * IRQ_EN is kept set so the next pass still raises the line. */
static void irq_service(void)
{
    if (s_accel == NULL) {
        return;
    }

    s_irq_status = style_net_mmio_read(s_accel + STYLE_NET_REG_STATUS / 4u);
    style_net_mmio_write(s_accel + STYLE_NET_REG_CTRL / 4u,
                         STYLE_NET_CTRL_IRQ_EN | STYLE_NET_CTRL_CLEAR);
    s_irq_count++;
}

uint32_t style_net_irq_count(void)
{
    return s_irq_count;
}

uint32_t style_net_irq_status(void)
{
    return s_irq_status;
}

void style_net_irq_reset(void)
{
    s_irq_count = 0u;
    s_irq_status = 0u;
}

void style_net_irq_init(volatile uint32_t *accel)
{
    s_accel = accel;

#ifndef STYLE_NET_HOST_TEST
    /* Install the trap vector FIRST.  On an external interrupt the CPU
     * jumps to mtvec, whose reset value is 0 -- enabling the PLIC
     * before this meant the first interrupt ran off to address 0 and
     * wedged the board. */
    csr_write(mtvec, trap_entry);

    /* Dedicated gateway for the accelerator, lowest threshold so it can
     * preempt nothing. */
    plic_set_threshold(BSP_PLIC, BSP_PLIC_CPU_0, 0);
    plic_set_priority(BSP_PLIC, STYLE_NET_PLIC_IRQ_ID, 1u);
    plic_set_enable(BSP_PLIC, BSP_PLIC_CPU_0, STYLE_NET_PLIC_IRQ_ID, 1u);

    /* Machine external interrupts.  MPP=M keeps mret returning to
     * machine mode, matching the reference userInterruptDemo. */
    csr_set(mie, MIE_MEIE);
    csr_write(mstatus, csr_read(mstatus) | MSTATUS_MPP | MSTATUS_MIE);
#endif
}

void style_net_irq_handler(void)
{
#ifndef STYLE_NET_HOST_TEST
    uint32_t claim = plic_claim(BSP_PLIC, BSP_PLIC_CPU_0);
    /* Safety valve: a stuck level interrupt must not wedge the CPU.
     * 1024 is far above the one claim a single pass can produce. */
    uint32_t guard = 1024u;

    while (claim != 0u && guard-- != 0u) {
        if (claim == (uint32_t)STYLE_NET_PLIC_IRQ_ID) {
            irq_service();
        }
        plic_release(BSP_PLIC, BSP_PLIC_CPU_0, claim);
        claim = plic_claim(BSP_PLIC, BSP_PLIC_CPU_0);
    }
#endif
}

#ifdef STYLE_NET_HOST_TEST
void style_net_host_raise_irq(void)
{
    irq_service();
}
#endif
