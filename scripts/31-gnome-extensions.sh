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

if ! command -v gnome-extensions &>/dev/null || ! command -v gnome-shell &>/dev/null; then
  warn "gnome-extensions/gnome-shell not found, skip"
  exit 0
fi

SHELL_VER=$(gnome-shell --version | awk '{print $3}')
SHELL_MAJOR=$(echo "$SHELL_VER" | cut -d. -f1)
info "GNOME Shell version: $SHELL_VER"

EXT_UUIDS=(
  "appindicatorsupport@rgcjonas.gmail.com"
  "ding@rastersoft.com"
  "rounded-window-corners@fxgn"
  "blur-my-shell@aunetx"
  "kimpanel@kde.org"
  "system-monitor@gnome-shell-extensions.gcampax.github.com"
  "dash-to-dock@micxgx.gmail.com"
  "logomenu@aryan_k"
  "user-theme@gnome-shell-extensions.gcampax.github.com"
)

for UUID in "${EXT_UUIDS[@]}"; do
  echo -e "\n===== Processing: $UUID ====="

  # Already enabled -> skip (to force update: rm .stamps/gnome-extensions)
  if gnome-extensions list --enabled 2>/dev/null | grep -qx "$UUID"; then
    info "$UUID already enabled, skip"
    continue
  fi

  API_URL="https://extensions.gnome.org/api/v1/extensions/$UUID/"
  if ! JSON=$(curl -fsSL "$API_URL"); then
    warn "Failed to fetch API for $UUID, skip"
    sleep 2
    continue
  fi

  PK=$(echo "$JSON" | jq -r --arg sv "$SHELL_VER" --arg sm "$SHELL_MAJOR" \
    '.shell_version_map[$sv] // .shell_version_map[$sm]')
  if [[ "$PK" == "null" || -z "$PK" ]]; then
    warn "$UUID no compatible version for $SHELL_VER, skip"
    sleep 2
    continue
  fi

  ZIP_NAME="${UUID}.shell-extension.zip"
  DL_URL="https://extensions.gnome.org/download-extension/${UUID}.shell-extension.zip?version_tag=${PK}"
  info "Downloading: $DL_URL"
  curl -fSL -# -o "$ZIP_NAME" "$DL_URL"

  gnome-extensions install --force "$ZIP_NAME" || warn "install $UUID failed"
  gnome-extensions enable "$UUID" || warn "enable $UUID failed (relogin may help)"
  rm -f "$ZIP_NAME"
  info "$UUID done"
  sleep 2
done
