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

if [[ "${CLEANUP:-yes}" != "yes" ]]; then
  info "CLEANUP=$CLEANUP, skip"
  exit 0
fi

warn "cleanup intermediate files"

for dir in \
  "${HOME}/tools/neovim" \
  "${HOME}/tools/WhiteSur-gtk-theme" \
  "${HOME}/tools/WhiteSur-icon-theme"; do
  if [[ -d "$dir" ]]; then
    info "removing $dir"
    rm -rf "$dir"
  fi
done

DL_DIR="${HOME}/Downloads"
for f in \
  "${DL_DIR}/linuxqq_${ARCH}.${PKG_TYPE}" \
  "${DL_DIR}/WeChatLinux_${ARCH}.${PKG_TYPE}" \
  "${DL_DIR}/wps-linux-${ARCH}.${PKG_TYPE}" \
  "${DL_DIR}/Feishu-linux_${ARCH}.${PKG_TYPE}" \
  "${DL_DIR}/firefox.tar.xz" \
  "${DL_DIR}/thunderbird.tar.xz"; do
  if [[ -f "$f" ]]; then
    info "removing $f"
    rm -f "$f"
  fi
done

info "cleanup done"
