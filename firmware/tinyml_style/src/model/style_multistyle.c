#include "style_multistyle.h"

#include "style_net_platform.h"
#include "bsp.h"
#include "soc.h"
#include "spiFlash.h"

#ifdef STYLE_NET_MULTI_STYLE

/*
 * DDR model slots.  Keep these 64 KiB apart: each blob is 53,808 bytes and the
 * accelerator arena starts at 0x04800000.  Loading all three costs no
 * additional FPGA RAM and lets the running firmware switch without a reset.
 */
const style_multistyle_entry_t style_multistyle_entries[STYLE_MULTISTYLE_COUNT] = {
    { '1', "future",  0x04000000u, 0x003A0000u, STYLE_MULTISTYLE_MODEL_BYTES, 0xA5E4CCCBu },
    { '2', "vangogh", 0x04010000u, 0x003B0000u, STYLE_MULTISTYLE_MODEL_BYTES, 0xA1467ECFu },
    { '3', "cubism",  0x04020000u, 0x003C0000u, STYLE_MULTISTYLE_MODEL_BYTES, 0xE0A17F74u },
};

uint32_t style_multistyle_hash(const style_multistyle_entry_t *entry)
{
    const uint8_t *p;
    uint32_t h = 0x811C9DC5u;
    uint32_t i;

    if (entry == 0) {
        return 0u;
    }

    p = (const uint8_t *)entry->model_base;
    style_net_cache_invalidate(p, entry->model_bytes);
    for (i = 0u; i < entry->model_bytes; ++i) {
        h ^= p[i];
        h *= 0x01000193u;
    }
    return h;
}

int style_multistyle_verify(const style_multistyle_entry_t *entry)
{
    if (entry == 0) {
        return -1;
    }
    return (style_multistyle_hash(entry) == entry->fnv1a32) ? 0 : -1;
}

int style_multistyle_prepare(void)
{
    unsigned i;
    int missing = 0;

    for (i = 0u; i < STYLE_MULTISTYLE_COUNT; ++i) {
        if (style_multistyle_verify(&style_multistyle_entries[i]) != 0) {
            missing = 1;
            break;
        }
    }
    if (missing == 0) {
        return 0;
    }

    bsp_printf("loading style models from flash...\r\n");
    spiFlash_init(SYSTEM_SPI_0_IO_CTRL, 0);
    spiFlash_wake(SYSTEM_SPI_0_IO_CTRL, 0);
    spiFlash_exit4ByteAddr(SYSTEM_SPI_0_IO_CTRL, 0);
    for (i = 0u; i < STYLE_MULTISTYLE_COUNT; ++i) {
        const style_multistyle_entry_t *entry = &style_multistyle_entries[i];
        spiFlash_f2m(SYSTEM_SPI_0_IO_CTRL, 0, entry->flash_base,
                     entry->model_base, entry->model_bytes);
        bsp_printf("style model %s: flash 0x%x -> DDR 0x%x\r\n",
                   entry->name, (unsigned)entry->flash_base,
                   (unsigned)entry->model_base);
    }
    return 0;
}
#endif
