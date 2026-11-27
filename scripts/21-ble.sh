#!/bin/bash

#
# osbn
# Copyright (C) 2026 lrisguan
#
# This program is released under the terms of the GPL v3.0 LICENSE.
# See https://opensource.org/licenses/GPL-3.0 for more information.
#
# Project homepage: https://github.com/lrisguan/osbn
# Description: Shell script to auto download necessary softwares to make your new linux brandnew.
#

set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

BLE_DIR="${HOME}/tools/ble.sh"

if [[ -f "${BLE_DIR}/out/ble.sh" ]]; then
  info "ble.sh already built"
else
  [[ -d "$BLE_DIR/.git" ]] || git clone --recursive --depth 1 --shallow-submodules \
    https://github.com/akinomyoga/ble.sh.git "$BLE_DIR"
  make -C "$BLE_DIR" -j"$(nproc)"
fi

LINE='source ~/tools/ble.sh/out/ble.sh'
if ! grep -qxF "$LINE" "${HOME}/.bashrc" 2>/dev/null; then
  echo "$LINE" >>"${HOME}/.bashrc"
  info "added ble.sh to ~/.bashrc"
fi
info "ble.sh installed"
