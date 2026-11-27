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

if ! command -v gsettings &>/dev/null; then
  warn "gsettings not found, skip"
  exit 0
fi

gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']" ||
  warn "set show-desktop failed"
gsettings set org.gnome.shell.window-switcher app-icon-mode "both" ||
  warn "set app-icon-mode failed"

info "gnome settings applied"
