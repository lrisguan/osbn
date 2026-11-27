#!/bin/bash
# All scripts source this file
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
info() { echo -e "${GREEN}[INFO] $*${NC}"; }
warn() { echo -e "${YELLOW}[WARN] $*${NC}"; }
error() { echo -e "${RED}[ERRO] $*${NC}" >&2; }

# ---------- Package Manager ----------
if command -v apt &>/dev/null; then
  PKG_MGR="apt"
elif command -v dnf &>/dev/null; then
  PKG_MGR="dnf"
elif command -v pacman &>/dev/null; then
  PKG_MGR="pacman"
elif command -v zypper &>/dev/null; then
  PKG_MGR="zypper"
else
  error "unknown package manager"
  exit 1
fi

# ---------- Distribution / Package Type ----------
. /etc/os-release
case "$ID" in
debian | ubuntu | linuxmint | deepin | pop) PKG_TYPE="deb" ;;
fedora | rhel | centos | rocky | almalinux | opensuse*) PKG_TYPE="rpm" ;;
*)
  error "unknown package type for ID=$ID"
  exit 1
  ;;
esac

# ---------- Architecture ----------
ARCH=$(uname -m)
case "$ARCH" in
x86_64) ARCH_KEY="x64" ;;
aarch64 | arm64) ARCH_KEY="aarch64" ;;
*)
  error "unsupported architecture: $ARCH"
  exit 1
  ;;
esac

# ---------- Package Manager Operations (with flock to avoid race in make -j) ----------
install_pkg() {
  local pkg="$1"
  (
    flock -x 9
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
  ) 9>"/tmp/osbn-pkg.lock"
}

remove_pkg() {
  (
    flock -x 9
    case "$PKG_MGR" in
    apt) sudo apt remove -y "$@" ;;
    dnf) sudo dnf remove -y "$@" ;;
    pacman) sudo pacman -R --noconfirm "$@" ;;
    zypper) sudo zypper remove -y "$@" ;;
    esac
  ) 9>"/tmp/osbn-pkg.lock"
}
