PROJ_NAME=tinyml_style
PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../..)
STANDALONE = $(PROJECT_ROOT)/embedded_sw/my_soc/software/standalone
BSP ?= efinix/EfxSapphireSoc

# SoC definition: take the headers / linker script from the BSP generated
# with this project's own my_soc IP, not from the TinyML hello-world SoC
# that STANDALONE was borrowed from.  bsp.mk uses "BSP_PATH ?=", so setting
# it here overrides the default derivation.
BSP_PATH = $(PROJECT_ROOT)/embedded_sw/my_soc/bsp/efinix/EfxSapphireSoc
RISCV_BIN ?= D:/Efinity/efinity-riscv-ide-2026.1/toolchain/bin/riscv-none-elf-
DEBUG=no
DEBUG_OG=no
BENCH=yes

# Production defaults for this clean project.
STYLE_NET_RUN_FRAME ?= 19
STYLE_NET_STREAM ?= 1
STYLE_NET_MULTI_STYLE ?= 1

SRCS = $(wildcard src/*.c) \
       $(wildcard src/*.cc) \
       $(wildcard src/*.cpp) \
       $(wildcard src/*.S) \
       $(wildcard src/common/*.c) \
       $(wildcard src/model/*.cc) \
       $(wildcard src/model/*.c) \
       $(wildcard src/style_net/*.cc) \
       $(wildcard src/style_net/*.c) \
       src/common/start.S \
       src/common/trap.S

# Multi-style image: three 53,808-byte model blobs live in separate DDR slots
# and are preloaded by OpenOCD.  The firmware only embeds the catalog, cutting
# the image well below the 124 KiB RISC-V RAM window.  UART 1/2/3 switches at
# a frame boundary without rebuilding or reloading the FPGA bitstream.
ifneq ($(STYLE_NET_MULTI_STYLE),)
SRCS := $(filter-out src/model/style_model_data.c,$(SRCS))
CFLAGS += -DSTYLE_NET_MULTI_STYLE
else
SRCS := $(filter-out src/model/style_multistyle.c,$(SRCS))
endif

CFLAGS += -DOPTIMIZE_X -funroll-loops -mdiv \
          -I. -Isrc -Isrc/model -Isrc/style_net \
          -ffunction-sections \
          -fdata-sections \
          -fno-common \
          -fomit-frame-pointer \
          -ffreestanding \
          -g \
          -fno-builtin

CXXFLAGS += -std=c++11 \
            -fstrict-aliasing \
            -fno-rtti \
            -fno-exceptions \
            -fno-threadsafe-statics \
            -fmessage-length=0

include ${STANDALONE}/common/bsp.mk
include ${STANDALONE}/common/riscv64-unknown-elf.mk
include ${STANDALONE}/common/tinyml_standalone.mk

RISCV_CXX := $(RISCV_BIN)gcc
LDFLAGS += -Wl,--no-warn-rwx-segments
LIBS+=${STANDALONE}/common/tinyml_lib.a -lm

# Efinity RISC-V IDE 2026.1 ships GCC 13, which requires an explicit Zicsr
# extension for CSR instructions (mcause/mie/mstatus).  The shared TinyML BSP
# makefile still assumes the older toolchain default, so pin the arch here.
# The later -march wins over the one appended by riscv64-unknown-elf.mk.
CFLAGS  += -march=rv32im_zicsr
LDFLAGS += -march=rv32im_zicsr

# Board frame run: `make STYLE_NET_RUN_FRAME=2` runs only the first two passes
# (the L5 q_in -> q1 bring-up check); `make STYLE_NET_RUN_FRAME=19` runs the
# whole 19-pass frame.  Default build stays at the L1-L4 bring-up.
ifneq ($(STYLE_NET_RUN_FRAME),)
CFLAGS += -DSTYLE_NET_RUN_FRAME -DSTYLE_NET_RUN_PASSES=$(STYLE_NET_RUN_FRAME)
endif

# Automatic frame loop: wait for a complete q_in frame, run all passes into the
# inactive q_out bank, then publish that bank at the next video VS.
ifneq ($(STYLE_NET_STREAM),)
CFLAGS += -DSTYLE_NET_STREAM
endif

# Board bring-up trace: `make all STYLE_NET_RUN_FRAME=2 STYLE_NET_TRACE=1`
# prints one short line per step of the pass flow over UART (see
# style_net_scheduler.c).  Off by default, so normal builds are unaffected.
ifneq ($(STYLE_NET_TRACE),)
CFLAGS += -DSTYLE_NET_TRACE
endif

# Minimal per-pass profile: only print `P<id> cyc=<hex>` after each pass.
# Much smaller than STYLE_NET_TRACE, which adds the [A]..[F] checkpoints.
ifneq ($(STYLE_NET_PROFILE_MIN),)
CFLAGS += -DSTYLE_NET_PROFILE_MIN
endif

# Board A/B hook: wait for one complete q_in frame and then for RUNCFG magic.
ifneq ($(STYLE_NET_WAIT_RUNCFG),)
CFLAGS += -DSTYLE_NET_WAIT_RUNCFG
endif

# Completion-wait timeout, in CLINT mtime ticks.  The firmware default is
# 200000000; a short value makes a stuck pass print [F] rc=timeout quickly
# instead of spinning for minutes, which is what an L5 bring-up run wants.
#   make all STYLE_NET_RUN_FRAME=2 STYLE_NET_TRACE=1 STYLE_NET_TIMEOUT_CYCLES=20000000
# Firmware-only: no bitstream rebuild needed.
ifneq ($(STYLE_NET_TIMEOUT_CYCLES),)
CFLAGS += -DSTYLE_NET_DEFAULT_TIMEOUT_CYCLES=$(STYLE_NET_TIMEOUT_CYCLES)
endif

# Bring-up escape hatch: STYLE_NET_NO_IRQ=1 runs the passes with the accelerator
# interrupt disabled, so wait_done() polls STATUS instead of taking the PLIC
# interrupt.  Isolates the datapath from the IRQ/PLIC plumbing.  Firmware-only.
ifneq ($(STYLE_NET_NO_IRQ),)
CFLAGS += -DSTYLE_NET_USE_IRQ=0
endif

# Trace cadence: [W] prints once per (STYLE_NET_TRACE_SPIN_MASK+1) polls.
# The default 0x7FF gives ~40 lines per pass; a big value gives a handful, so
# the whole run fits in one paste.  Firmware-only.
ifneq ($(STYLE_NET_TRACE_SPIN_MASK),)
CFLAGS += -DSTYLE_NET_TRACE_SPIN_MASK=$(STYLE_NET_TRACE_SPIN_MASK)
endif

# Diagnostic: force every pass flags word (see style_net_scheduler.c).
ifneq ($(STYLE_NET_FLAGS_OVERRIDE),)
CFLAGS += -DSTYLE_NET_FLAGS_OVERRIDE=$(STYLE_NET_FLAGS_OVERRIDE)
endif

# Diagnostic: start at pass N instead of pass 0 (see style_net_scheduler.c).
ifneq ($(STYLE_NET_FIRST_PASS),)
CFLAGS += -DSTYLE_NET_FIRST_PASS=$(STYLE_NET_FIRST_PASS)
endif

# Logic-analyser capture: `make all STYLE_NET_RUN_FRAME=2 STYLE_NET_TRACE=1 \
#   STYLE_NET_START_DELAY_CYCLES=2000000000`
# holds START off for that many CLINT ticks.  100 MHz -> 1 tick = 10 ns, so
# 2000000000 ~ 20 s, which is the comfortable figure: the board shares one
# FTDI/JTAG chain between OpenOCD and the Efinity logic analyser, so the sequence
# is
#   1. OpenOCD: load + resume      (firmware prints [A]..[D2] then [D3] and waits)
#   2. detach OpenOCD              (hands the JTAG back)
#   3. Efinity debugger: set the trigger, Arm, and LEAVE IT OPEN
#   4. the hold-off expires -> [D4] -> START -> the analyser triggers and stores
#   5. read the waveform
# Off by default.
ifneq ($(STYLE_NET_START_DELAY_CYCLES),)
CFLAGS += -DSTYLE_NET_START_DELAY_CYCLES=$(STYLE_NET_START_DELAY_CYCLES)
endif





