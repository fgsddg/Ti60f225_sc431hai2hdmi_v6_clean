#ifndef STYLE_NET_IRQ_H
#define STYLE_NET_IRQ_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Accelerator interrupt plumbing.
 *
 * The accelerator raises a level interrupt when a pass finishes and IRQ_EN is
 * set.  The ISR must clear the accelerator's sticky status before releasing
 * the PLIC claim, otherwise the level re-triggers forever.
 */

/* Store the register base and program the PLIC gateway / threshold.
 * Safe to call before enabling interrupts globally. */
void style_net_irq_init(volatile uint32_t *accel);

/* Call from trap() for CAUSE_MACHINE_EXTERNAL.  Claims, clears the
 * accelerator source, records STATUS and releases the PLIC claim. */
void style_net_irq_handler(void);

/* Number of accelerator interrupts seen so far (monotonic). */
uint32_t style_net_irq_count(void);

/* STATUS captured by the most recent interrupt. */
uint32_t style_net_irq_status(void);

/* Zero the counter / captured status (start of a frame, or tests). */
void style_net_irq_reset(void);

#ifdef STYLE_NET_HOST_TEST
/* Simulate the accelerator IRQ: same bookkeeping as the real ISR. */
void style_net_host_raise_irq(void);
#endif

#ifdef __cplusplus
}
#endif

#endif
