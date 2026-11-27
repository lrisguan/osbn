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

if command -v starship &>/dev/null; then
  info "starship already installed: $(starship --version | head -1)"
  exit 0
fi

curl -sS https://starship.rs/install.sh | sh
info "starship installed"
