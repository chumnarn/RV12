# RV12 + LibreLane + IHP SG13G2 — Full-Chip Implementation Guide

## 1. Goal

Build a reproducible RV12 RV32 full-chip ASIC implementation using the IHP SG13G2 open PDK
and LibreLane 3.x. The first milestone is intentionally conservative: prove that the complete
RV12 source set elaborates, simulates, synthesizes, places, routes, and reaches GDSII behind a
real IHP pad ring.

## 2. Why the AHB3-Lite top is used

RV12 already provides `riscv_top_ahb3lite.sv`. The upstream AHB filelist establishes the
required compilation order for packages, core modules, cache/no-cache modules, PMA/PMP logic,
BIU and the AHB wrapper. Keeping that boundary avoids invasive changes to the processor.

The physical wrapper configures:
- MXLEN=32
- ALEN=32
- no MMU/FPU/RVC
- RVM enabled
- BPU disabled for a smaller first implementation
- no instruction/data cache
- PC_INIT=0

## 3. PMA configuration

RV12's physical-memory-attribute checker rejects unmatched accesses. Therefore the integration
provides one TOR PMA region from address 0 up to 0x1000_0000 with read/write/execute enabled.
This covers the boot ROM and local RAM in the baseline design.

## 4. Baseline memory system

### Instruction side

A tiny synthesizable ROM returns:

```text
0x00000000 : 0x0000006f    jal x0, 0
```

This creates an instruction-fetch loop that is sufficient for bring-up. The remaining ROM
space returns NOPs.

### Data side

A 64-word x 32-bit synthesizable RAM is attached to the RV12 data AHB interface. Byte enables
are generated from HSIZE and HADDR.

This is not the final production memory architecture. It is a low-risk stage-1 target.

## 5. IHP full-chip wrapper

`rtl/chip_top.sv` instantiates:
- `sg13g2_IOPadIn` for clock, reset and eight external inputs
- `sg13g2_IOPadOut30mA` for eight status outputs
- core VDD/VSS pads
- IO VDD/VSS pads

The eight input pads are mapped to:
- ext_in[0] -> NMI
- ext_in[1] -> timer interrupt
- ext_in[2] -> software interrupt
- ext_in[6:3] -> external interrupts
- ext_in[7] -> spare/observable loopback bit

The outputs expose debug/bus activity for first-silicon observability.

## 6. Environment

Recommended:

```bash
nix develop
librelane --version
```

The project flake pins LibreLane 3.0.0.

Verify the PDK:

```bash
librelane --pdk ihp-sg13g2 --flow Chip librelane/config.yaml --to Yosys.Synthesis
```

## 7. Fetch RV12

```bash
make setup
```

The script checks out RV12 and initializes its pinned submodules (including `ahb3lite_pkg`):

```text
526bd14da6f6eb0bf04460d5d50519f61bcbc84a
```

Do not synthesize against an unpinned moving branch while debugging the physical flow.

## 8. Bring in the bondpad IP

`make setup` also fetches the pinned reference template and copies its `ip/` directory.
To repeat only this step:

```bash
./scripts/fetch_template_ip.sh
```

The required paths are:

```text
ip/bondpad_70x70_novias/gds/bondpad_70x70_novias.gds
ip/bondpad_70x70_novias/lef/bondpad_70x70_novias.lef
```

## 9. Lint

```bash
make lint
```

Expected result: no fatal Verilator errors. Warnings from generic upstream constructs should be
reviewed, not blindly suppressed.

## 10. RTL simulation

```bash
make sim
```

The simulation:
1. holds reset low for five cycles,
2. releases reset,
3. runs for 100 cycles,
4. checks for instruction-side activity,
5. prints PASS and exits.

The default boot ROM continually executes `jal x0,0`.

## 11. Synthesis-only milestone

```bash
make synth
```

Inspect:

```text
librelane/runs/rv12_synth/
```

Key checks:
- all RV12 packages elaborate,
- `riscv_top_ahb3lite` exists under `u_core/u_rv12`,
- no unintended black boxes,
- clock is recognized,
- synthesis cell count is plausible,
- no latch explosion,
- memory arrays do not explode beyond the target die capacity.

If the 64x32 RAM is mapped inefficiently, reduce WORDS to 16 for the first P&R run.

## 12. Full-chip run

```bash
make chip
```

This invokes:

```bash
librelane --pdk ihp-sg13g2 --flow Chip librelane/config.yaml \
  --run-tag rv12_fullchip
```

## 13. Floorplan

Initial dimensions:

```yaml
DIE_AREA:  [0, 0, 2200, 2200]
CORE_AREA: [420, 420, 1780, 1780]
PL_TARGET_DENSITY_PCT: 30
```

These are starting values, not silicon sign-off values. After synthesis, calculate:

```text
utilization = synthesized standard-cell area / core placement area
```

Aim for a first-route target around 25–40% for this relatively complex CPU, then tighten.

## 14. Timing

Initial clock:

```text
50 MHz = 20 ns
```

Constraints include:
- clock uncertainty 0.25 ns
- input delay 2 ns
- output delay 4 ns

Do not start the first full-chip attempt at an aggressive RV12 frequency. Establish a clean
physical baseline first, then sweep 50/75/100 MHz.

## 15. Pad ring

The config explicitly lists all pad instances on four sides. If LibreLane reports that a named
pad cannot be found, inspect synthesized hierarchy:

```bash
grep -R "g_in" librelane/runs/rv12_fullchip/*synthesis* -n | head
```

Generated-array instance escaping is important:

```yaml
"g_in\\[0\\].u_pad"
```

## 16. PDN

The baseline enables:
- core ring
- 15 µm ring width
- 5 µm spacing
- ring-to-pad connection

Core supply: `VDD/VSS`.
IO supply: `IOVDD/IOVSS` through IHP pad cells.

## 17. Validation checklist

A successful first milestone requires all of the following:

- [ ] `make setup` pins exact RV12 revision
- [ ] `make lint` no fatal errors
- [ ] `make sim` PASS
- [ ] synthesis no unresolved black boxes
- [ ] floorplan has legal pad ring
- [ ] placement completes
- [ ] CTS completes
- [ ] routing completes
- [ ] antenna check reviewed
- [ ] LVS clean
- [ ] KLayout/Magic DRC reviewed
- [ ] setup/hold timing reports reviewed
- [ ] final GDS/OASIS generated

## 18. Recommended stage-2 upgrade: IHP SRAM macro

After the baseline full-chip route is stable, replace `rv12_data_ram` with
`RM_IHPSG13_1P_1024x32_c2_bm_bist`.

Required physical views in the current IHP flow are typically:
- GDS
- LEF
- Liberty for typ/fast/slow
- Verilog macro/model

Add a `MACROS:` block to `config.yaml`, provide a fixed or guided macro placement, and add the
macro's power connections. Validate synthesis black-boxing separately before starting P&R.

## 19. Recommended stage-3 upgrade: real firmware

Replace the boot ROM's single JAL instruction with a generated SystemVerilog case table or ROM
hex converter.

Suggested sequence:
1. compile `start.S + main.c` using a RISC-V GCC toolchain,
2. link at address 0x00000000,
3. `objcopy -O binary`,
4. convert words to `rv12_boot_rom.sv`,
5. run RTL simulation,
6. only then rerun synthesis/P&R.

## 20. Debug strategy

When a run fails, isolate by stage:

```bash
make lint
make sim
make synth
make chip
```

For LibreLane, use a new `--run-tag` for each experiment and change only one class of variable
at a time: source/elaboration, timing, floorplan, PDN, placement density, routing.

## 21. Known integration risks

1. RV12 uses substantial SystemVerilog package/type features; Slang is enabled for synthesis.
2. The RV12 upstream license is non-commercial unless separately agreed; confirm suitability
   before tapeout or commercial deployment.
3. The synthesizable RAM is only a bring-up device and may map inefficiently.
4. Exact IO/bondpad library content depends on the installed IHP PDK revision.
5. The initial die dimensions are deliberately conservative and must be recalibrated from PPA.
