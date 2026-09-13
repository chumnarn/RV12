# RV12 Full-Chip Implementation with LibreLane 3.x and IHP SG13G2

This project is a reproducible full-chip scaffold for the Roa Logic RV12 RISC-V CPU using
LibreLane 3.x and the IHP Open PDK SG13G2.

## Design intent

- CPU: Roa Logic RV12, RV32 configuration
- CPU bus: AMBA 3 AHB-Lite instruction + data master interfaces
- Boot: small synthesizable on-chip ROM
- Data memory: small synthesizable on-chip RAM
- Physical top: IHP SG13G2 IO pads
- Flow: LibreLane `Chip` flow, YAML config v3
- Target clock: 50 MHz (20 ns)
- Reset: active-low external pad

The project deliberately keeps the first full-chip target small and deterministic. It does
not require an SRAM macro or firmware toolchain to reach synthesis/P&R. After the base flow
is stable, replace the synthesizable RAM with the IHP 1Kx32 SRAM macro and replace the boot
ROM contents with application firmware.

## Pinned upstream revisions

- RV12: `526bd14da6f6eb0bf04460d5d50519f61bcbc84a`
- Reference IHP/LibreLane template: `0418301723d86133de686ef743cfd668bb3d11d4`

## Quick start

```bash
git clone <this-project>
cd rv12-ihp-sg13g2-fullchip

# Fetch pinned RV12 + submodules and the reference bondpad IP
make setup

# Enter LibreLane 3.0 environment
nix develop

# Static checks
make lint

# Core simulation
make sim

# Synthesis only
make synth

# Full-chip RTL-to-GDSII
make chip
```

If you already use an IIC-OSIC-TOOLS/LibreLane environment, `nix develop` is optional as
long as LibreLane 3.x and the `ihp-sg13g2` PDK are installed.

## Project tree

```text
.
├── README.md
├── Makefile
├── flake.nix
├── rtl/
│   ├── rv12_chip_core.sv
│   ├── rv12_boot_rom.sv
│   ├── rv12_data_ram.sv
│   └── chip_top.sv
├── sim/
│   └── tb_rv12_chip_core.sv
├── librelane/
│   ├── config.yaml
│   └── chip_top.sdc
├── scripts/
│   ├── fetch_rv12.sh
│   └── check_tree.sh
├── third_party/
│   └── RV12/                 # created by make setup
└── docs/
    └── FULL_CHIP_GUIDE.md
```

## Important licensing note

RV12 source files remain governed by the license in the upstream RV12 repository. This
project does not re-license or duplicate the upstream CPU source; `make setup` fetches the
pinned upstream revision into `third_party/RV12`.
