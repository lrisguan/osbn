# osbn(OS-BrandNew)

> 一键下载并安装必要的软件，让刚装好的 Linux 系统焕然一新。

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://opensource.org/licenses/GPL-3.0)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)](#支持的发行版)

## 项目简介

**OS-BrandNew** 是一组由 `Makefile` 编排的 Bash 脚本。它把一台刚装好的 Linux 系统，变成开箱即用、顺手舒适的桌面环境——工具链、编辑器、Shell 提示符、GNOME 美化、主题，以及一批常用 GUI 应用——只需要一条命令。

它**不是**发行版安装器，也**不会**在下面清单之外修改你的系统。每一步都是幂等的、可观测的（每个任务独立日志）、可以安全重跑。

## 具体做了什么

| 层面 | 任务 |
| --- | --- |
| **工具链** | 从源码编译安装 **Neovim**；编译 **ble.sh**；安装 **Rust**（rustup）；安装 **Starship**；部署 **LazyVim** 起始配置。 |
| **桌面** | 配置 GNOME 快捷键；安装并启用一批精选的 **GNOME Shell 扩展**（AppIndicator、Dash-to-Dock、Blur-my-Shell、圆角窗口等）；安装 **WhiteSur GTK** 与 **WhiteSur 图标**主题。 |
| **应用** | 下载并安装 **QQ**、**微信**、**WPS**（仅 x64）、**Firefox**、**Thunderbird**、**Google Chrome**，可选安装 **飞书 / Lark**。Firefox 与 Thunderbird 使用官方 tar 包安装到 `/opt`，以便自行更新。 |
| **影音** | 安装 **mpv**，并配置现代风格的 OSC（屏幕控制器）与配套字体。 |
| **清理** | 可选地删除已下载的安装包与临时构建目录。 |

## 支持的发行版

- **包管理器**：`apt`、`dnf`、`pacman`、`zypper`
- **发行版**：Debian / Ubuntu / Linux Mint / Deepin / Pop!_OS，Fedora / RHEL / CentOS / Rocky / AlmaLinux / openSUSE
- **架构**：`x86_64`（`x64`）与 `aarch64` / `arm64`

不支持的发行版或架构会在 preflight 阶段明确报错并退出。

## 快速开始

```bash
git clone https://github.com/lrisguan/osbn.git
cd osbn

# 先预热 sudo，否则并行任务会同时抢占密码输入
sudo -v

# 完整安装，8 路并行，每个目标的输出分组显示
make -j8 --output-sync=target all
```

只跑其中一部分：

```bash
make toolchain -j8     # Neovim、ble.sh、Rust、Starship、LazyVim
make desktop -j8       # GNOME 设置、扩展、主题
make apps -j8          # 下载并安装应用，配置 mpv
```

安装可选的飞书（默认 `no`）：

```bash
make INSTALL_FEISHU=yes -j8 all
```

你也可以使用串行脚本：

```bash
./osbn.sh
```

## 目录结构

```
os-brandnew/
├── Makefile                 # 编排：依赖、并行、stamp
├── config.mk                # 用户可覆盖的配置
├── osbn.sh                  # serial script
├── lib/
│   └── common.sh            # info/warn/error、包管理器检测、install_pkg（带 flock）
├── scripts/
│   ├── 00-preflight.sh      # 发行版/架构检测、sudo 预热、基础依赖
│   ├── 20-neovim.sh         # 从源码编译 Neovim
│   ├── 21-ble.sh            # 编译 ble.sh 并写入 .bashrc
│   ├── 22-rust.sh           # 安装 rustup 工具链
│   ├── 23-starship.sh       # 安装 Starship 提示符
│   ├── 24-lazyvim.sh        # 克隆 LazyVim starter
│   ├── 30-gnome-settings.sh # GNOME 快捷键
│   ├── 31-gnome-extensions.sh # 安装并启用 GNOME 扩展
│   ├── 40-theme-gtk.sh      # WhiteSur GTK 主题
│   ├── 41-theme-icon.sh     # WhiteSur 图标主题
│   ├── 50-download-apps.sh  # 并行下载应用安装包
│   ├── 60-install-apps.sh   # 串行安装（走包管理器）
│   ├── 70-mpv.sh            # mpv + 现代 OSC 配置
│   └── 99-cleanup.sh        # 可选清理
├── .stamps/                 # 每个已完成任务一个文件（自动创建）
└── logs/                    # 每个任务的日志（自动创建）
```

## Make 目标

| 目标 | 说明 |
| --- | --- |
| `all` | `toolchain` + `desktop` + `apps`（默认） |
| `toolchain` | Neovim、ble.sh、Rust、Starship、LazyVim |
| `desktop` | GNOME 设置、扩展、GTK 与图标主题 |
| `apps` | 下载并安装全部应用，然后配置 mpv |
| `downloads` | 只下载安装包，不安装 |
| `install-apps` | 只安装已下载的安装包 |
| `clean` | 删除 `.stamps/` 与 `logs/`（**不会**卸载任何软件） |
| `distclean` | 在 `clean` 基础上提示需手动删除的目录 |
| `help` | 显示用法与选项 |

单独重跑某个任务：

```bash
rm .stamps/gnome-extensions && make desktop
```

## 配置项

配置在 `config.mk` 中（也可以通过环境变量传入）：

| 变量 | 默认值 | 含义 |
| --- | --- | --- |
| `INSTALL_FEISHU` | `no` | 设为 `yes` 则下载并安装飞书 / Lark。 |
| `CLEANUP` | `yes` | 设为 `no` 则保留下载的安装包与构建目录。 |

## 并行处理说明

- **默认并行**：彼此独立的任务（`neovim`、`ble.sh`、`rust`、`starship`、`lazyvim`）通过 `make -jN` 并发执行；每个编译步骤内部还会使用 `-j$(nproc)`。
- **并行下载**：所有应用安装包在 `50-download-apps.sh` 内并发下载。
- **串行安装**：`60-install-apps.sh` 与 `70-mpv.sh` 串行执行，因为 `apt`/`dnf`/`pacman`/`zypper` 都有**全局锁**。此外，所有 `install_pkg` / `remove_pkg` 调用都包了 `flock`，即便临时并行调用也安全。
- **GNOME 扩展保持串行**：extensions.gnome.org 的 API 有限流，脚本在每次请求之间主动 `sleep`。
- **主题保持串行**：两个主题安装脚本都会修改 GTK 配置，同时跑会冲突。

使用 `make -jN --output-sync=target` 可以让每个目标的输出成块显示，避免日志交错。

## 幂等与重跑

- 每个任务成功后会在 `.stamps/` 下生成一个文件，后续 `make` 会跳过已完成的任务。
- 每个脚本自身也做了前置检查（例如"`nvim` 是否已在 `PATH` 中？"、"`~/.config/nvim` 是否已存在？"），所以删掉 stamp 再重跑也是安全的。
- 彻底重来：`make clean && make -j8 all`。

## 注意事项

- 运行 `make -j` **之前**务必先 `sudo -v` 预热密码，否则并行任务会同时弹出密码提示。
- **Google Chrome** 通过系统包管理器安装。如果你的发行版没有 `google-chrome` 包，请先添加 Google 官方源，或修改 `scripts/60-install-apps.sh`。
- **WPS** 个人版仅提供 `x64` 包；`aarch64` 上会跳过并给出提示。
- **飞书 / Lark** 使用未公开的下载 API，可能随时失效；失败不会中断整体流程。
- **Firefox** 与 **Thunderbird** 使用 Mozilla 官方 tar 包安装到 `/opt`，并先卸载系统包，以便浏览器自行更新。
- GNOME 扩展步骤需要有正在运行的 GNOME Shell 会话；无头机器上会自动跳过。

## 参与贡献

欢迎在 <https://github.com/lrisguan/osbn/issues> 提交 Issue 或 Pull Request。

## 许可证

以 **GPL v3.0** 发布，完整文本见 <https://opensource.org/licenses/GPL-3.0>。
