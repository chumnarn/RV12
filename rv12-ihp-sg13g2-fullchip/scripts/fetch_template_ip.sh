#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/ihp-sg13g2-librelane-template.$$"
REV="0418301723d86133de686ef743cfd668bb3d11d4"

rm -rf "$TMP"
git clone https://github.com/chumnarn/ihp-sg13g2-librelane-template.git "$TMP"
git -C "$TMP" checkout --detach "$REV"

rm -rf "$ROOT/ip"
mkdir -p "$ROOT/ip"
cp -a "$TMP/ip/." "$ROOT/ip/"
rm -rf "$TMP"

echo "Copied IHP template IP into $ROOT/ip"
