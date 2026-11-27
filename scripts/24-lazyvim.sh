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

NVIM_CONF="${HOME}/.config/nvim"

if [[ -d "$NVIM_CONF" && -n "$(ls -A "$NVIM_CONF" 2>/dev/null)" ]]; then
  info "nvim config exists, skip (rm -rf ${NVIM_CONF} to redo)"
  exit 0
fi

git clone --depth=1 https://github.com/LazyVim/starter "$NVIM_CONF"
info "LazyVim starter installed to ${NVIM_CONF}"
