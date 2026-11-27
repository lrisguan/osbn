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

info "preflight: os=$ID arch=$ARCH pkg_mgr=$PKG_MGR pkg_type=$PKG_TYPE"

# Warm up sudo (used by subsequent parallel tasks)
sudo -v || {
  error "sudo is required"
  exit 1
}

mkdir -p "${HOME}/tools" "${HOME}/Downloads" \
  "${HOME}/.local/share/fonts" "${HOME}/.config/mpv/scripts"

DEPS=(gcc git curl jq make ninja)
MISSING=()
for dep in "${DEPS[@]}"; do
  command -v "$dep" &>/dev/null || MISSING+=("$dep")
done
if ((${#MISSING[@]})); then
  warn "installing missing deps: ${MISSING[*]}"
  for dep in "${MISSING[@]}"; do install_pkg "$dep"; done
fi

if command -v gnome-shell &>/dev/null; then
  info "gnome-shell: $(gnome-shell --version)"
else
  warn "gnome-shell not found; desktop tweaks will be skipped"
fi

info "preflight OK"
