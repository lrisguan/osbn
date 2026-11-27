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

DIR="${HOME}/tools/WhiteSur-icon-theme"

if [[ -d "$DIR/.git" ]]; then
  info "WhiteSur-icon-theme exists, pull"
  git -C "$DIR" pull --ff-only || warn "pull failed, use existing"
else
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$DIR"
fi

(cd "$DIR" && bash ./install.sh)
gtk-update-icon-cache -q -t "${HOME}/.local/share/icons" 2>/dev/null || true
info "WhiteSur icon theme installed"
