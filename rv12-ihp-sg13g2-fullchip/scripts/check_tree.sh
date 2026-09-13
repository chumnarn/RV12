#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RV12="$ROOT/third_party/RV12"

required=(
  submodules/ahb3lite_pkg/rtl/verilog/ahb3lite_pkg.sv
  rtl/filelist_ahb3lite.f
  rtl/verilog/pkg/riscv_rv12_pkg.sv
  rtl/verilog/pkg/riscv_state_20240411_pkg.sv
  rtl/verilog/pkg/riscv_pma_pkg.sv
  rtl/verilog/ahb3lite/biu_ahb3lite.sv
  rtl/verilog/ahb3lite/riscv_top_ahb3lite.sv
)

for f in "${required[@]}"; do
  test -f "$RV12/$f" || { echo "Missing $RV12/$f" >&2; exit 1; }
done

echo "RV12 source tree looks complete."

test -f "$ROOT/ip/bondpad_70x70_novias/gds/bondpad_70x70_novias.gds" || {
  echo "Missing bondpad GDS. Run ./scripts/fetch_template_ip.sh" >&2; exit 1;
}
test -f "$ROOT/ip/bondpad_70x70_novias/lef/bondpad_70x70_novias.lef" || {
  echo "Missing bondpad LEF. Run ./scripts/fetch_template_ip.sh" >&2; exit 1;
}
echo "Bondpad IP looks complete."
