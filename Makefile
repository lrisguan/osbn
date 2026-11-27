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

SHELL       := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
MAKEFLAGS   += --no-print-directory

-include config.mk

STAMP := .stamps
LOG   := logs
$(shell mkdir -p $(STAMP) $(LOG))

export INSTALL_FEISHU
export CLEANUP

# Common recipe: print message -> execute script -> write log
RUN = echo ">>> $<"; \
      bash $< 2>&1 | tee $(LOG)/$(notdir $(basename $<)).log

# Pre-check (run before rebuilding each make target)
.PHONY: preflight
preflight:
	@bash scripts/00-preflight.sh

# ========== toolchain ==========
.PHONY: toolchain
toolchain: $(STAMP)/neovim $(STAMP)/ble $(STAMP)/rust $(STAMP)/starship $(STAMP)/lazyvim

$(STAMP)/neovim:   scripts/20-neovim.sh   lib/common.sh | preflight
	@$(RUN); touch $@
$(STAMP)/ble:      scripts/21-ble.sh      lib/common.sh | preflight
	@$(RUN); touch $@
$(STAMP)/rust:     scripts/22-rust.sh     lib/common.sh | preflight
	@$(RUN); touch $@
$(STAMP)/starship: scripts/23-starship.sh lib/common.sh | preflight
	@$(RUN); touch $@
$(STAMP)/lazyvim:  scripts/24-lazyvim.sh  lib/common.sh | preflight
	@$(RUN); touch $@

# ========== desktop ==========
.PHONY: desktop
desktop: $(STAMP)/gnome-settings $(STAMP)/gnome-extensions $(STAMP)/theme-gtk $(STAMP)/theme-icon

$(STAMP)/gnome-settings:   scripts/30-gnome-settings.sh   lib/common.sh | preflight
	@$(RUN); touch $@
$(STAMP)/gnome-extensions: scripts/31-gnome-extensions.sh lib/common.sh | preflight
	@$(RUN); touch $@
$(STAMP)/theme-gtk:        scripts/40-theme-gtk.sh        lib/common.sh | preflight
	@$(RUN); touch $@
# Icon depends on gtk; run serially to avoid concurrent GTK config modification
$(STAMP)/theme-icon:       scripts/41-theme-icon.sh       lib/common.sh $(STAMP)/theme-gtk | preflight
	@$(RUN); touch $@

# ========== apps ==========
.PHONY: apps downloads install-apps
apps: $(STAMP)/install-apps $(STAMP)/mpv
downloads: $(STAMP)/downloads
install-apps: $(STAMP)/install-apps

$(STAMP)/downloads:    scripts/50-download-apps.sh lib/common.sh | preflight
	@$(RUN); touch $@
# Install dependency downloads, package manager with global lock -> serial execution
$(STAMP)/install-apps: scripts/60-install-apps.sh  lib/common.sh $(STAMP)/downloads | preflight
	@$(RUN); touch $@
# mpv also installed via package manager -> run serially after install-apps
$(STAMP)/mpv:          scripts/70-mpv.sh           lib/common.sh $(STAMP)/install-apps | preflight
	@$(RUN); touch $@

# ========== top ==========
.PHONY: all clean distclean help
all: toolchain desktop apps

clean:
	rm -rf $(STAMP) $(LOG)

distclean: clean
	@echo "WARN: distclean does NOT remove system packages."
	@echo "      Remove nvim/rust/themes manually if needed."

help:
	@echo "Usage: make [-jN] [target]"
	@echo "  all           full setup (default)"
	@echo "  toolchain     neovim / ble.sh / rust / starship / LazyVim"
	@echo "  desktop       gnome settings / extensions / themes"
	@echo "  apps          download + install apps + mpv"
	@echo "  downloads     only download app packages"
	@echo "  install-apps  only install downloaded packages"
	@echo "  clean         remove stamps & logs"
	@echo ""
	@echo "Options (in config.mk or env):"
	@echo "  INSTALL_FEISHU=yes|no   (default: no)"
	@echo "  CLEANUP=yes|no          (default: yes)"
	@echo ""
	@echo "Examples:"
	@echo "  sudo -v && make -j8 --output-sync=target all"
	@echo "  make toolchain -j8"
	@echo "  rm .stamps/gnome-extensions && make desktop"
