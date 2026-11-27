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

DL_DIR="${HOME}/Downloads"
QQ_PKG="${DL_DIR}/linuxqq_${ARCH}.${PKG_TYPE}"
WECHAT_PKG="${DL_DIR}/WeChatLinux_${ARCH}.${PKG_TYPE}"
WPS_PKG="${DL_DIR}/wps-linux-${ARCH}.${PKG_TYPE}"
FIREFOX_PKG="${DL_DIR}/firefox.tar.xz"
THUNDERBIRD_PKG="${DL_DIR}/thunderbird.tar.xz"
FEISHU_PKG="${DL_DIR}/Feishu-linux_${ARCH}.${PKG_TYPE}"

install_if_exists() {
  local name="$1" pkg="$2"
  if [[ -f "$pkg" ]]; then
    info "installing $name: $pkg"
    install_pkg "$pkg"
  else
    warn "$name pkg not found ($pkg), skip"
  fi
}

# ---------- QQ ----------
install_if_exists QQ "$QQ_PKG"

# ---------- WeChat ----------
install_if_exists WeChat "$WECHAT_PKG"

# ---------- WPS ----------
if [[ "$ARCH_KEY" == "x64" ]]; then
  install_if_exists WPS "$WPS_PKG"
else
  info "skip WPS: no personal package for $ARCH"
  info "see https://365.wps.cn/download365 if needed"
fi

# ---------- Firefox ----------
if [[ -f "$FIREFOX_PKG" ]]; then
  warn "uninstall system firefox"
  remove_pkg firefox firefox-esr 2>/dev/null || true
  sudo tar -xf "$FIREFOX_PKG" -C /opt/
  sudo chown -R "$USER":"$USER" /opt/firefox
  info "firefox -> /opt/firefox"
else
  warn "firefox pkg not found, skip"
fi

# ---------- Thunderbird ----------
if [[ -f "$THUNDERBIRD_PKG" ]]; then
  warn "uninstall system thunderbird"
  remove_pkg thunderbird thunderbird-esr 2>/dev/null || true
  sudo tar -xf "$THUNDERBIRD_PKG" -C /opt/
  sudo chown -R "$USER":"$USER" /opt/thunderbird
  info "thunderbird -> /opt/thunderbird"
else
  warn "thunderbird pkg not found, skip"
fi

# ---------- Chrome ----------
install_pkg google-chrome || warn "google-chrome install failed (need external repo)"

# ---------- Feishu ----------
if [[ "${INSTALL_FEISHU:-no}" == "yes" ]]; then
  install_if_exists Feishu "$FEISHU_PKG"
fi

info "install-apps done"
