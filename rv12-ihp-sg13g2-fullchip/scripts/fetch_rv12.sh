#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DST="$ROOT/third_party/RV12"
REV="526bd14da6f6eb0bf04460d5d50519f61bcbc84a"

if [[ ! -d "$DST/.git" ]]; then
  rm -rf "$DST"
  git clone --recursive https://github.com/RoaLogic/RV12.git "$DST"
fi

git -C "$DST" fetch --all --tags --prune
git -C "$DST" checkout --detach "$REV"
git -C "$DST" submodule sync --recursive
git -C "$DST" submodule update --init --recursive

echo "RV12 pinned at:"
git -C "$DST" --no-pager log -1 --oneline
echo "AHB3-Lite package pinned at:"
git -C "$DST/submodules/ahb3lite_pkg" --no-pager log -1 --oneline
