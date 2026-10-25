/*
 * Shared interface parameters for the style-transfer accelerator DDR path.
 *
 * Mirrors the generated SoC's io_ddrMasters_0_* port.  If the SoC is
 * regenerated with a different width, update this file to match.
 *
 * See docs/style_net_axi_master_if.md for the full interface definition.
 */

`ifndef STYLE_NET_AXI_IF_VH
`define STYLE_NET_AXI_IF_VH

/* ---------------- AXI4 master widths ----------------
 * Must match the SoC port:
 *     io_ddrMasters_0_aw_payload_addr  [31:0]
 *     io_ddrMasters_0_aw_payload_len   [7:0]
 *     io_ddrMasters_0_aw_payload_id    [3:0]
 *     io_ddrMasters_0_w_payload_data   [127:0]
 *     io_ddrMasters_0_w_payload_strb   [15:0]
 */
`define STYLE_NET_AXI_DATA_W      128
`define STYLE_NET_AXI_STRB_W      (`STYLE_NET_AXI_DATA_W/8)
`define STYLE_NET_AXI_ADDR_W      32
`define STYLE_NET_AXI_ID_W        4
`define STYLE_NET_AXI_LEN_W       8
`define STYLE_NET_AXI_SIZE_W      3
`define STYLE_NET_AXI_BURST_W     2
`define STYLE_NET_AXI_CACHE_W     4
`define STYLE_NET_AXI_PROT_W      3
`define STYLE_NET_AXI_QOS_W       4
`define STYLE_NET_AXI_REGION_W    4

/* ---------------- Transfer shape ---------------- */
/* awsize = 3'b100 -> 16 bytes per beat */
`define STYLE_NET_AXI_BYTES_PER_BEAT  16
`define STYLE_NET_AXI_MAX_BURST       16    /* beats per INCR burst (256 B) */
`define STYLE_NET_AXI_ALIGN           16    /* bytes; every row base is aligned */

/* Fixed AXI attributes used by this design */
`define STYLE_NET_AXI_AWSIZE   3'b100
`define STYLE_NET_AXI_AWBURST  2'b01    /* INCR */
`define STYLE_NET_AXI_AWLOCK   1'b0
`define STYLE_NET_AXI_AWCACHE  4'h0
`define STYLE_NET_AXI_AWPROT   3'h0
`define STYLE_NET_AXI_AWQOS    4'h0
`define STYLE_NET_AXI_AWREGION 4'h0

/* ---------------- DMA error codes (cfg / error_code) ---------------- */
`define STYLE_NET_ERR_BUS      32'd1    /* AXI BRESP/RRESP != OKAY */
`define STYLE_NET_ERR_TIMEOUT  32'd2    /* AXI handshake timed out */
`define STYLE_NET_ERR_RANGE    32'd3    /* address / shape out of the arena */

/* ---------------- Streaming interface shape ----------------
 * IC and OC are runtime values (19 passes use 7 distinct combinations),
 * so the physical widths are sized for the largest layer and masked at
 * run time (see TBD-2 in the interface document).
 */
`define STYLE_NET_MAX_IC       32
`define STYLE_NET_MAX_OC       32
`define STYLE_NET_IN_PIXEL_W   (8*`STYLE_NET_MAX_IC)
`define STYLE_NET_OUT_PIXEL_W  (8*`STYLE_NET_MAX_OC)

`endif
