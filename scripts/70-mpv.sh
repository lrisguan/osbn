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

install_pkg mpv || warn "mpv install failed, will still write config"

mkdir -p "${HOME}/.config/mpv/scripts" "${HOME}/.local/share/fonts"

OSC_LUA="${HOME}/.config/mpv/scripts/modern.lua"
if [[ ! -f "$OSC_LUA" ]]; then
  curl -fSL -# https://raw.githubusercontent.com/maoiscat/mpv-osc-modern/main/modern.lua \
    -o "$OSC_LUA" || warn "mpv osc download failed"
fi

MPV_FONT="${HOME}/.local/share/fonts/Material-Design-Iconic-Font.ttf"
if [[ ! -f "$MPV_FONT" ]]; then
  curl -fSL -# https://raw.githubusercontent.com/maoiscat/mpv-osc-modern/main/Material-Design-Iconic-Font.ttf \
    -o "$MPV_FONT" || warn "mpv font download failed"
fi

cat >"${HOME}/.config/mpv/mpv.conf" <<'EOF'
osc = no
border = no
geometry=50%:50%
autofit-larger=90%x90%
keepaspect-window=yes
keep-open=yes
no-keepaspect

idle=yes

video-align-x=0
video-align-y=0
video-scale-x=1.0
video-scale-y=1.0

force-seekable=yes
hr-seek=yes
script-opts=osc-seekbarkeyframes=no

hwdec=auto-safe
EOF

info "mpv configured"
