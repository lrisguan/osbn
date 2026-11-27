# osbn(OS-BrandNew)

> Automatically download and install the essential software to make a fresh Linux installation feel brand new.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://opensource.org/licenses/GPL-3.0)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)](#supported-systems)

## Overview

**OS-BrandNew** is a collection of Bash scripts orchestrated by a `Makefile`. It turns a freshly installed Linux system into a comfortable, ready-to-work desktop environment — toolchain, editor, shell prompt, GNOME tweaks, themes, and a set of common GUI applications — with a single command.

It is **not** a distro installer, and it does **not** touch your system configuration beyond what is explicitly listed below. Every step is idempotent, observable (per-task logs), and can be re-run safely.

## What it does

| Layer | Tasks |
| --- | --- |
| **Toolchain** | Build & install **Neovim** from source; build **ble.sh**; install **Rust** (rustup); install **Starship**; set up **LazyVim** starter config. |
| **Desktop** | GNOME keybindings; install & enable a curated list of **GNOME Shell extensions** (AppIndicator, Dash-to-Dock, Blur-my-Shell, Rounded Window Corners, etc.); install **WhiteSur GTK** and **WhiteSur icon** themes. |
| **Apps** | Download and install **QQ**, **WeChat**, **WPS** (x64 only), **Firefox**, **Thunderbird**, **Google Chrome**, and optionally **Feishu / Lark**. Firefox and Thunderbird are installed from the official tarballs into `/opt` so they can self-update. |
| **Media** | Install **mpv** and apply a modern OSC (on-screen controller) with bundled fonts. |
| **Cleanup** | Optionally remove downloaded packages and temporary build directories. |

## Supported systems

- **Package managers**: `apt`, `dnf`, `pacman`, `zypper`
- **Distributions**: Debian / Ubuntu / Linux Mint / Deepin / Pop!_OS, Fedora / RHEL / CentOS / Rocky / AlmaLinux / openSUSE
- **Architectures**: `x86_64` (`x64`) and `aarch64` / `arm64`

Unsupported distros or architectures cause an early, explicit failure in the preflight step.

## Quick start

```bash
git clone https://github.com/lrisguan/osbn.git
cd osbn

# Warm up sudo first — parallel jobs would otherwise race for the password prompt.
sudo -v

# Full setup, 8 parallel jobs, output grouped per target.
make -j8 --output-sync=target all
```

Run only part of the setup:

```bash
make toolchain -j8     # Neovim, ble.sh, Rust, Starship, LazyVim
make desktop -j8       # GNOME settings, extensions, themes
make apps -j8          # download + install apps, mpv
```

Enable the optional Feishu install (default: `no`):

```bash
make INSTALL_FEISHU=yes -j8 all
```

Also you can use the serial script:

```bash
./osbn.sh
```

## Directory layout

```
os-brandnew/
├── Makefile                 # orchestration: dependencies, parallelism, stamps
├── config.mk                # user-overridable options
├── osbn.sh                  # serial script
├── lib/
│   └── common.sh            # info/warn/error, PKG_MGR detection, install_pkg (flock)
├── scripts/
│   ├── 00-preflight.sh      # distro/arch detection, sudo warm-up, base deps
│   ├── 20-neovim.sh         # build Neovim from source
│   ├── 21-ble.sh            # build ble.sh + hook into .bashrc
│   ├── 22-rust.sh           # install rustup toolchain
│   ├── 23-starship.sh       # install Starship prompt
│   ├── 24-lazyvim.sh        # clone LazyVim starter
│   ├── 30-gnome-settings.sh # GNOME keybindings
│   ├── 31-gnome-extensions.sh # install & enable GNOME Shell extensions
│   ├── 40-theme-gtk.sh      # WhiteSur GTK theme
│   ├── 41-theme-icon.sh     # WhiteSur icon theme
│   ├── 50-download-apps.sh  # parallel download of app packages
│   ├── 60-install-apps.sh   # serial install via package manager
│   ├── 70-mpv.sh            # mpv + modern OSC config
│   └── 99-cleanup.sh        # optional cleanup
├── .stamps/                 # one file per completed task (auto-created)
└── logs/                    # per-task logs (auto-created)
```

## Make targets

| Target | Description |
| --- | --- |
| `all` | `toolchain` + `desktop` + `apps` (default) |
| `toolchain` | Neovim, ble.sh, Rust, Starship, LazyVim |
| `desktop` | GNOME settings, extensions, GTK & icon themes |
| `apps` | Download + install all apps, then configure mpv |
| `downloads` | Only download app packages (no install) |
| `install-apps` | Only install previously downloaded packages |
| `clean` | Remove `.stamps/` and `logs/` (does **not** uninstall anything) |
| `distclean` | `clean` + print a reminder about manual removal |
| `help` | Show usage and options |

Re-run a single task:

```bash
rm .stamps/gnome-extensions && make desktop
```

## Configuration

Options live in `config.mk` (or can be passed as environment variables):

| Variable | Default | Meaning |
| --- | --- | --- |
| `INSTALL_FEISHU` | `no` | Set to `yes` to download and install Feishu / Lark. |
| `CLEANUP` | `yes` | Set to `no` to keep downloaded packages and build dirs. |

## How parallel execution works

- **Parallel by default**: independent tasks (`neovim`, `ble.sh`, `rust`, `starship`, `lazyvim`) run concurrently with `make -jN`. Each compiler step also uses `-j$(nproc)` internally.
- **Parallel downloads**: all application packages are fetched concurrently inside `50-download-apps.sh`.
- **Serialized installs**: `60-install-apps.sh` and `70-mpv.sh` run serially because `apt`/`dnf`/`pacman`/`zypper` take a **global lock**. Additionally, every `install_pkg` / `remove_pkg` call is wrapped in `flock` so ad-hoc parallel invocations remain safe.
- **GNOME extensions stay serial**: the extensions.gnome.org API rate-limits requests; the script deliberately sleeps between calls.
- **Themes stay serial**: both theme installers modify GTK configuration.

Use `make -jN --output-sync=target` to keep each target's output grouped together.

## Idempotence & re-runs

- Each successful task touches a file under `.stamps/`. Subsequent `make` invocations skip completed tasks.
- Every script also checks its own preconditions (e.g. "is `nvim` already on `PATH`?", "does `~/.config/nvim` already exist?") so removing a stamp and re-running is safe.
- To force a full rebuild: `make clean && make -j8 all`.

## Notes & caveats

- `sudo -v` **before** running `make -j` is strongly recommended. Without it, parallel jobs may each prompt for a password.
- **Google Chrome** is installed through the system package manager. If your distro has no `google-chrome` package, add Google's official repository first, or edit `scripts/60-install-apps.sh`.
- **WPS** personal edition is only available for `x64`. On `aarch64` the step is skipped with a message.
- **Feishu / Lark** uses an undocumented download API and may break without notice; the failure is non-fatal.
- **Firefox** and **Thunderbird** are installed from Mozilla's official tarballs to `/opt`, and the system packages are removed first so the browsers can self-update.
- The GNOME extensions step requires a running GNOME Shell session; on headless machines it is skipped.

## Contributing

Issues and pull requests are welcome at <https://github.com/lrisguan/osbn/issues>.

## License

Released under the **GPL v3.0**. See <https://opensource.org/licenses/GPL-3.0> for the full text.
