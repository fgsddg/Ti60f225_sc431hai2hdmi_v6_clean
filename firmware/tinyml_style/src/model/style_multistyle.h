#ifndef STYLE_MULTISTYLE_H
#define STYLE_MULTISTYLE_H

#include <stdint.h>

/*
 * Runtime-selectable 128x96 models.
 *
 * The firmware image deliberately does not embed the 53,808-byte model blobs:
 * the RISC-V software RAM window is only 124 KiB, while one blob plus the
 * program already occupies most of it.  Instead, OpenOCD preloads the three
 * blobs into non-overlapping DDR slots and the firmware switches model_base at
 * a frame boundary.  All three models share the same 19-pass table/layout.
 */
typedef struct {
    char        key;          /* UART selector: 1/2/3 */
    const char *name;
    uintptr_t   model_base;   /* 64 KiB-aligned DDR slot */
    uint32_t    flash_base;   /* model slot in configuration flash */
    uint32_t    model_bytes;
    uint32_t    fnv1a32;      /* guards against a missing/wrong image load */
} style_multistyle_entry_t;

#define STYLE_MULTISTYLE_COUNT 3u
#define STYLE_MULTISTYLE_MODEL_BYTES 53808u

extern const style_multistyle_entry_t style_multistyle_entries[STYLE_MULTISTYLE_COUNT];

/* Hash the blob already present at the entry's DDR slot. */
uint32_t style_multistyle_hash(const style_multistyle_entry_t *entry);

/* Return 0 when the slot contains the expected blob, -1 otherwise. */
int style_multistyle_verify(const style_multistyle_entry_t *entry);

/* Keep JTAG-preloaded models when valid; otherwise load all three from flash. */
int style_multistyle_prepare(void);

#endif