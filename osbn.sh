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

# basic colored output function
info() {
  echo -e "${GREEN}[INFO] $*${NC}"
}
warn() {
  echo -e "${YELLOW}[WARN] $*${NC}"
}
error() {
  echo -e "${RED}[ERRO] $*${NC}" >&2
}

# system dependency
if command -v apt &>/dev/null; then
  PKG_MGR="apt"
elif command -v dnf &>/dev/null; then
  PKG_MGR="dnf"
elif command -v pacman &>/dev/null; then
  PKG_MGR="pacman"
elif command -v zypper &>/dev/null; then
  PKG_MGR="zypper"
else
  echo "unknown package manager"
fi

install_pkg() {
  local pkg="$1"
  if [[ -f "$pkg" ]]; then
    case "$PKG_MGR" in
    apt) sudo apt install -y "$pkg" ;;
    dnf) sudo dnf install -y "$pkg" ;;
    pacman) sudo pacman -U --noconfirm "$pkg" ;;
    zypper) sudo zypper install -y "$pkg" ;;
    esac
  else
    case "$PKG_MGR" in
    apt) sudo apt install -y "$pkg" ;;
    dnf) sudo dnf install -y "$pkg" ;;
    pacman) sudo pacman -S --noconfirm "$pkg" ;;
    zypper) sudo zypper install -y "$pkg" ;;
    esac
  fi
}

remove_pkg() {
  case "$PKG_MGR" in
  apt) sudo apt remove -y "$@" ;;
  dnf) sudo dnf remove -y "$@" ;;
  pacman) sudo pacman -R --noconfirm "$@" ;;
  zypper) sudo zypper remove -y "$@" ;;
  esac
}

. /etc/os-release
# detect pkg type
case "$ID" in
debian | ubuntu | linuxmint | deepin | pop)
  PKG_TYPE="deb"
  ;;
fedora | rhel | centos | rocky | almalinux | opensuse)
  PKG_TYPE="rpm"
  ;;
*)
  error "unknown package type"
  exit 1
  ;;
esac

# detect arch
ARCH=$(uname -m)
case "$ARCH" in
x86_64) ARCH_KEY="x64" ;;
aarch64 | arm64) ARCH_KEY="aarch64" ;;
*)
  error "unsupported architecture" "$ARCH"
  exit 1
  ;;
esac

info "arch=$ARCH_KEY , pkg_type=$PKG_TYPE"

mkdir -p "${HOME}"/tools
# gnome settings
if command -v gsettings; then
  gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"
  gsettings set org.gnome.shell.window-switcher app-icon-mode "both"
fi

# toolchain
TOOLCHAIN_DEPS=("gcc" "git" "curl" "jq" "make" "ninja")
for dep in "${TOOLCHAIN_DEPS[@]}"; do
  if ! command -v "$dep" &>/dev/null; then
    error "Missing dependency: $dep"
    info "installing $dep"
    install_pkg "$dep"
  fi
done

## neovim
git clone --depth=1 https://github.com/neovim/neovim "${HOME}"/tools/neovim
cd "${HOME}"/tools/neovim
make CMAKE_BUILD_TYPE=Release
sudo make install
info "neovim installed"

## neovim config
git clone --depth=1 https://github.com/LazyVim/starter "${HOME}"/.config/nvim/
info "LazyVim configured"

## rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

## nodejs

SHELL_VER=$(gnome-shell --version | awk '{print $3}')
info "Current GNOME Shell version: $SHELL_VER"

# apparence
## gnome shell extensions
GNOME_DEPS=("gnome-extensions")
for dep in "${GNOME_DEPS[@]}"; do
  if ! command -v "$dep" &>/dev/null; then
    error "Missing dependency: $dep"
    exit 1
  fi
done

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
  API_URL="https://extensions.gnome.org/api/v1/extensions/$UUID/"

  # get extension info
  if ! JSON=$(curl -fsSL "$API_URL"); then
    warn "Failed to fetch API for $UUID, skip"
    sleep 2
    continue
  fi

  # get compatible pk with current shell version
  PK=$(echo "$JSON" | jq -r --arg sv "$SHELL_VER" '.shell_version_map[$sv]')
  if [[ "$PK" == "null" || -z "$PK" ]]; then
    warn "$UUID has no compatible version for $SHELL_VER, skip"
    sleep 2
    continue
  fi
  echo "Found pk: $PK"

  ZIP_NAME="${UUID}.shell-extension.zip"
  DL_URL="https://extensions.gnome.org/download-extension/${UUID}.shell-extension.zip?version_tag=${PK}"

  info "Downloading: $DL_URL"
  curl -fSL -# -o "$ZIP_NAME" "$DL_URL"

  # install
  gnome-extensions install --force "$ZIP_NAME"
  info "🔧 Enabling extension $UUID"
  gnome-extensions enable "$UUID"

  rm -f "$ZIP_NAME"
  info "$UUID done"
  sleep 2 # prevent throttling 429
done

## icon and gtk theme
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git "${HOME}"/tools/
cd "${HOME}"/tools/WhiteSur-gtk-theme/
./insatll.sh -l
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git "${HOME}"/tools/
cd "${HOME}"/tools/WhiteSur-icon-theme/
./install.sh
# update theme cache
gtk-update-icon-cache -q -t "$HOME/.local/share/icons" 2>/dev/null || true

## terminal
info "start to polish terminal"

### starship
curl -sS https://starship.rs/install.sh | sh

### ble.sh
git clone h--recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git "${HOME}"/tools/
cd "${HOME}"/tools
make -C ble.sh
echo 'source -- ~/tools/ble.sh/out/ble.sh' >>"${HOME}"/.bashrc

# apps
## QQ
QQ_PKG="${HOME}/Downloads/linuxqq_${ARCH}.${PKG_TYPE}"
if [[ "$ARCH_KEY" == "x64" ]]; then
  QQ_URL=$(curl -s --fail https://im.qq.com/rainbow/linuxQQDownload |
    grep -o 'params= {.*};' |
    sed -E 's/params= (.*);/\1/' |
    jq -r ".x64DownloadUrl")
  curl -fSL -# "$QQ_URL" -o "${QQ_PKG}"
  install_pkg "$QQ_PKG"
elif [[ "$ARCH_KEY" == "aarch64" ]]; then
  QQ_URL=$(curl -s --fail https://im.qq.com/rainbow/linuxQQDownload |
    grep -o 'params= {.*};' |
    sed -E 's/params= (.*);/\1/' |
    jq -r ".armDownloadUrl")
  curl -fSL -# "$QQ_URL" -o "${QQ_PKG}"
  install_pkg "$QQ_PKG"
else
  error "no package for target architecture."
fi

## WeChat
WECHAT_PKG="${HOME}/Downloads/WeChatLinux_${ARCH}.${PKG_TYPE}"
if [[ "$ARCH_KEY" == "x64" ]]; then
  WECHAT_URL=$(curl -s --fail https://linux.weixin.qq.com/en | grep -oE 'https://[^"]+WeChatLinux_x86_64.'"${PKG_TYPE}")
  curl -fSL -# "$WECHAT_URL" -o "$WECHAT_PKG"
  install_pkg "$WECHAT_PKG"
elif [[ "$ARCH_KEY" == "aarch64" ]]; then
  WECHAT_URL=$(curl -s https://linux.weixin.qq.com/en | grep -oE 'https://[^"]+WeChatLinux_aarch64.'"${PKG_TYPE}")
  curl -fSL -# "$WECHAT_URL" -o "$WECHAT_PKG"
  install_pkg "$WECHAT_PKG"
else
  error "no package for target architecture."
fi

## wps
WPS_PKG="${HOME}/Downloads/wps-linux-${ARCH}.${PKG_TYPE}"
if [[ "$ARCH_KEY" == "x64" ]]; then
  WPS_URL=$(curl -s https://linux.wps.cn/ | grep -oP 'https://wps-linux.*?\.'"${PKG_TYPE}")
  curl -fSL -# "$WPS_URL" -o "$WPS_PKG"
  install_pkg "$WPS_PKG"
else
  error "no personal wps package for target architecture."
  error "if you still nened to download, please go to: https://365.wps.cn/download365 instead"
fi

## firefox

### uninstall system's firefox
warn "uninstall the system's firefox, so that firefox can update itself without using system package manager"
sudo "${PKG_MGR}" remove firefox
sudo "${PKG_MGR}" remove firefox-esr

### re-install firfox
info "re-install firefox through firefox's offical website"
FIREFOX_PKG="${HOME}/Downloads/firefox.tar.xz"
if [[ "$ARCH_KEY" == "x64" ]]; then
  curl -fSL -# "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" -o "$FIREFOX_PKG"
elif [[ "$ARCH_KEY" == "aarch64" ]]; then
  curl -fSL -# "https://download.mozilla.org/?product=firefox-latest&os=linux-aarch64&lang=en-US" -o "$FIREFOX_PKG"
else
  error "no package for target architecture."
fi
sudo tar -xf "$FIREFOX_PKG" -C /opt/
sudo chown -R "$USER":"$USER" /opt/firefox

## thunderbird

### uninstall system's thunderbird
warn "uninstall the system's thunderbird, so that thunderbird can update itself without using system package manager"
sudo "${PKG_MGR}" remove thunderbird
sudo "${PKG_MGR}" remove thunderbird-esr

### re-install thunderbird
info "re-install thunderbird through thunderbird's offical website"
THUNDERBIRD_PKG="${HOME}/Downloads/thunderbird.tar.xz"
if [[ "$ARCH_KEY" == "x64" ]]; then
  curl -fSL -# "https://download.mozilla.org/?product=thunderbird-latest&os=linux64&lang=en-US" -o "$THUNDERBIRD_PKG"
elif [[ "$ARCH_KEY" == "aarch64" ]]; then
  curl -fSL -# "https://download.mozilla.org/?product=thunderbird-latest&os=linux-aarch64&lang=en-US" -o "$THUNDERBIRD_PKG"
else
  error "no package for target architecture."
fi
sudo tar -xf "$THUNDERBIRD_PKG" -C /opt
sudo chown -R "$USER":"$USER" /opt/thunderbird

## google chrome
sudo "$PKG_MGR" install google-chrome

## feishu
read -rp "Do you need to install feishu(larkshell) to collaborate [Y/N]" FEISHU_ANSWER
case $FEISHU_ANSWER in
Y | y)
  case "${ARCH}:${PKG_TYPE}" in
  "x86_64:deb") FEISHU_PLATFORM_ID "10" ;;
  "x86_64:rpm") FEISHU_PLATFORM_ID "11" ;;
  "aarch64:deb") FEISHU_PLATFORM_ID "12" ;;
  "aarch64:rpm") FEISHU_PLATFORM_ID "13" ;;
  *) error "unsupported architecture:package type: ${ARCH}, ${PKG_TYPE}" ;;
  esac
  FEISHU_API="https://www.feishu.cn/api/package_info"
  FEISHU_PKG="${HOME}/Downloads/Feishu-linux_${ARCH}.${PKG_TYPE}"
  FEISHU_URL=$(curl -fsSL "${FEISHU_API}?platform=${FEISHU_PLATFORM_ID}" | jq -r '.data.download_link')
  curl -SfL -# "$FEISHU_URL" -o "$FEISHU_PKG"
  sudo "$PKG_MGR" install "$FEISHU_PKG"
  ;;
N | n)
  warn "OK, skip"
  ;;
*)
  error "error choice"
  ;;
esac

## mpv

### install mpv
sudo "$PKG_MGR" install mpv

### customize mpv
mkdir -p "${HOME}"/.config/mpv
mkdir -p "${HOME}"/.config/mpv/scripts/

#### download osc config
curl -fSL -# https://raw.githubusercontent.com/maoiscat/mpv-osc-modern/main/modern.lua -o "${HOME}"/.config/mpv/scripts/modern.lua

#### download font
curl -fSL -# https://raw.githubusercontent.com/maoiscat/mpv-osc-modern/main/Material-Design-Iconic-Font.ttf -o "${HOME}"/.local/share/fonts/Material-Design-Iconic-Font.ttf

#### mpv config
cat >"${HOME}"/.config/mpv/mpv.conf <<'EOF'
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

# remove intermedia things
read -rp "Whether to remove the intermedia things like the downloaded packages and so on [Y/N]:" REMOVE_ANSWER
case $REMOVE_ANSWER in
Y | y)
  warn "removing $HOME/tools/neovim/"
  rm -rf "$HOME/tools/neovim/"
  warn "removing $HOME/tools/WhiteSur-gtk-theme/"
  rm -rf "$HOME/tools/WhiteSur-gtk-theme/"
  warn "removing $HOME/tools/WhiteSur-icon-theme/"
  rm -rf "$HOME/tools/WhiteSur-icon-theme/"

  for PKG in "$QQ_PKG" "$WECHAT_PKG" "$WPS_PKG" "$FEISHU_PKG" "$FIREFOX_PKG" "$THUNDERBIRD_PKG"; do
    warn "removing $PKG"
    rm -f "$PKG"
  done
  ;;
N | n)
  info "OK, skip remove"
  ;;
*)
  error "error choice"
  ;;
esac

info "All done. Enjoy!"
info "Issues: https://github.com/lrisguan/osbn/issues"
