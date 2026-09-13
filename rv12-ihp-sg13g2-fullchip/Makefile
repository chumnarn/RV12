SHELL := /usr/bin/env bash
PROJECT_ROOT := $(abspath .)
RV12_DIR := $(PROJECT_ROOT)/third_party/RV12
LL_CFG := $(PROJECT_ROOT)/librelane/config.yaml

.PHONY: help setup check lint sim synth chip clean

help:
	@echo "Targets:"
	@echo "  setup  - fetch pinned RV12"
	@echo "  check  - verify source tree"
	@echo "  lint   - Verilator lint for RV12 core wrapper"
	@echo "  sim    - Verilator binary simulation"
	@echo "  synth  - LibreLane through Yosys.Synthesis"
	@echo "  chip   - complete LibreLane Chip flow"
	@echo "  clean  - remove simulation/build outputs"

setup:
	./scripts/fetch_rv12.sh
	./scripts/fetch_template_ip.sh
	./scripts/check_tree.sh

check:
	./scripts/check_tree.sh

# Derive the source order from the upstream file list and then append local wrappers.
# Verilator is used because RV12 relies on SystemVerilog packages/types.
lint: check
	cd $(RV12_DIR)/rtl && \
	verilator --lint-only -Wall -Wno-fatal --timing \
	  $(RV12_DIR)/submodules/ahb3lite_pkg/rtl/verilog/ahb3lite_pkg.sv \
	  $$(sed 's#^#/#' filelist_ahb3lite.f | sed "s#^/#$(RV12_DIR)/rtl/#") \
	  $(PROJECT_ROOT)/rtl/rv12_boot_rom.sv \
	  $(PROJECT_ROOT)/rtl/rv12_data_ram.sv \
	  $(PROJECT_ROOT)/rtl/rv12_chip_core.sv \
	  --top-module rv12_chip_core

sim: check
	rm -rf build/sim
	mkdir -p build/sim
	cd $(RV12_DIR)/rtl && \
	verilator --binary --timing -Wall -Wno-fatal \
	  $(RV12_DIR)/submodules/ahb3lite_pkg/rtl/verilog/ahb3lite_pkg.sv \
	  $$(sed 's#^#/#' filelist_ahb3lite.f | sed "s#^/#$(RV12_DIR)/rtl/#") \
	  $(PROJECT_ROOT)/rtl/rv12_boot_rom.sv \
	  $(PROJECT_ROOT)/rtl/rv12_data_ram.sv \
	  $(PROJECT_ROOT)/rtl/rv12_chip_core.sv \
	  $(PROJECT_ROOT)/sim/tb_rv12_chip_core.sv \
	  --top-module tb_rv12_chip_core \
	  --Mdir $(PROJECT_ROOT)/build/sim
	$(PROJECT_ROOT)/build/sim/Vtb_rv12_chip_core

synth: check
	librelane --pdk ihp-sg13g2 --flow Chip $(LL_CFG) \
	  --run-tag rv12_synth --to Yosys.Synthesis

chip: check
	librelane --pdk ihp-sg13g2 --flow Chip $(LL_CFG) \
	  --run-tag rv12_fullchip

clean:
	rm -rf build librelane/runs
