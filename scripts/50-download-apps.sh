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
mkdir -p "$DL_DIR"

QQ_PKG="${DL_DIR}/linuxqq_${ARCH}.${PKG_TYPE}"
WECHAT_PKG="${DL_DIR}/WeChatLinux_${ARCH}.${PKG_TYPE}"
WPS_PKG="${DL_DIR}/wps-linux-${ARCH}.${PKG_TYPE}"
FIREFOX_PKG="${DL_DIR}/firefox.tar.xz"
THUNDERBIRD_PKG="${DL_DIR}/thunderbird.tar.xz"
FEISHU_PKG="${DL_DIR}/Feishu-linux_${ARCH}.${PKG_TYPE}"

# Already downloaded and non-empty -> skip (idempotent; to re-download: delete file or rm .stamps/downloads)
need_dl() { [[ -s "$1" ]]; }

download_qq() {
  need_dl "$QQ_PKG" && {
    info "QQ pkg exists, skip"
    return 0
  }
  local url
  url=$(curl -s --fail https://im.qq.com/rainbow/linuxQQDownload |
    grep -o 'params= {.*};' | sed -E 's/params= (.*);/\1/' |
    jq -r ".${ARCH_KEY}DownloadUrl")
  [[ -n "$url" && "$url" != "null" ]] || {
    warn "QQ url parse failed"
    return 1
  }
  curl -fSL -# "$url" -o "$QQ_PKG"
  info "QQ downloaded"
}

download_wechat() {
  need_dl "$WECHAT_PKG" && {
    info "WeChat pkg exists, skip"
    return 0
  }
  local pat url
  if [[ "$ARCH_KEY" == "x64" ]]; then
    pat='https://[^"]+WeChatLinux_x86_64.'"${PKG_TYPE}"
  else
    pat='https://[^"]+WeChatLinux_aarch64.'"${PKG_TYPE}"
  fi
  url=$(curl -s --fail https://linux.weixin.qq.com/en | grep -oE "$pat" | head -1)
  [[ -n "$url" ]] || {
    warn "WeChat url parse failed"
    return 1
  }
  curl -fSL -# "$url" -o "$WECHAT_PKG"
  info "WeChat downloaded"
}

download_wps() {
  [[ "$ARCH_KEY" == "x64" ]] || {
    info "no personal WPS for $ARCH, skip"
    return 0
  }
  need_dl "$WPS_PKG" && {
    info "WPS pkg exists, skip"
    return 0
  }
  local url
  url=$(curl -s https://linux.wps.cn/ | grep -oP 'https://wps-linux.*?\.'"${PKG_TYPE}" | head -1)
  [[ -n "$url" ]] || {
    warn "WPS url parse failed"
    return 1
  }
  curl -fSL -# "$url" -o "$WPS_PKG"
  info "WPS downloaded"
}

download_firefox() {
  need_dl "$FIREFOX_PKG" && {
    info "firefox exists, skip"
    return 0
  }
  local os=linux64
  [[ "$ARCH_KEY" == "aarch64" ]] && os=linux-aarch64
  curl -fSL -# "https://download.mozilla.org/?product=firefox-latest&os=${os}&lang=en-US" -o "$FIREFOX_PKG"
  info "firefox downloaded"
}

download_thunderbird() {
  need_dl "$THUNDERBIRD_PKG" && {
    info "thunderbird exists, skip"
    return 0
  }
  local os=linux64
  [[ "$ARCH_KEY" == "aarch64" ]] && os=linux-aarch64
  curl -fSL -# "https://download.mozilla.org/?product=thunderbird-latest&os=${os}&lang=en-US" -o "$THUNDERBIRD_PKG"
  info "thunderbird downloaded"
}

download_feishu() {
  [[ "${INSTALL_FEISHU:-no}" == "yes" ]] || {
    info "feishu disabled, skip"
    return 0
  }
  need_dl "$FEISHU_PKG" && {
    info "feishu exists, skip"
    return 0
  }
  local platform_id
  case "${ARCH}:${PKG_TYPE}" in
  "x86_64:deb") platform_id="10" ;;
  "x86_64:rpm") platform_id="11" ;;
  "aarch64:deb") platform_id="12" ;;
  "aarch64:rpm") platform_id="13" ;;
  *)
    warn "unsupported arch:pkg_type for feishu: ${ARCH}:${PKG_TYPE}"
    return 0
    ;;
  esac
  local url
  url=$(curl -fsSL "https://www.feishu.cn/api/package_info?platform=${platform_id}" |
    jq -r '.data.download_link')
  [[ -n "$url" && "$url" != "null" ]] || {
    warn "Feishu url parse failed"
    return 1
  }
  curl -fSL -# "$url" -o "$FEISHU_PKG"
  info "feishu downloaded"
}

# ---------- parallel download ----------
info "parallel downloading packages..."
pids=()
fail=0
for fn in download_qq download_wechat download_wps \
  download_firefox download_thunderbird download_feishu; do
  $fn &
  pids+=($!)
done
for pid in "${pids[@]}"; do
  wait "$pid" || fail=1
done

if ((fail)); then
  warn "some downloads failed; install step will skip missing files"
fi
info "download phase done"
