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

NVIM_DIR="${HOME}/tools/neovim"

if command -v nvim &>/dev/null; then
  info "nvim already installed: $(command -v nvim)"
  exit 0
fi

if [[ ! -d "$NVIM_DIR/.git" ]]; then
  git clone --depth=1 https://github.com/neovim/neovim "$NVIM_DIR"
fi

make -C "$NVIM_DIR" CMAKE_BUILD_TYPE=Release -j"$(nproc)"
sudo make -C "$NVIM_DIR" install
info "neovim installed: $(nvim --version | head -1)"
