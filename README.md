# youth-nixos

NixOS 26.05 + niri + dotfiles（flake + home-manager）。

完整说明见 [`doc/系统需求.md`](doc/系统需求.md)。

## 快速开始

```bash
# 1) 克隆
git clone https://github.com/<you>/youth-nixos.git ~/youth-nixos
cd ~/youth-nixos

# 2) 改全局变量（用户名 / 主机名 / 主题 / 字体 / 显卡 / 桌面组件 …）
$EDITOR vars.nix

# 3) 若改了主机名，同步改 hosts 目录名
git mv hosts/ego hosts/<新主机名>

# 4) ★ 生成本机硬件配置（仓库不内置，含磁盘 UUID 等机器信息）
sudo nixos-generate-config --show-hardware-config > hosts/<新主机名>/hardware-configuration.nix

# 5) 构建并切换
sudo nixos-rebuild switch --flake .#<新主机名>
```

## 常用命令（just = 写 CLI 命令的工具）

```bash
just switch   # sudo nixos-rebuild switch --flake .#<hostname>
just test     # 试运行（重启可回退）
just build    # 只构建不切换
just update   # nix flake update
just gc       # 清理 30 天前旧世代
```

## 结构速览

| 路径 | 说明 |
| --- | --- |
| `vars.nix` | **全局变量**，改配置主要改这里 |
| `flake.nix` | flake 入口与 inputs（nixpkgs / home-manager / GitHub520 / zen-browser） |
| `hosts/<hostname>/` | 主机配置 + 引导；`hardware-configuration.nix` 不入库，自动探测 |
| `modules/nixos/` | 系统级模块（含显卡 graphics；输入法 input-method 默认关闭） |
| `modules/home/` | home-manager 用户级模块（全部用 `home.file` 托管 dotfile） |
| `dotfiles/` | 原生 dotfile：niri / kitty / tray-tui / zsh |
| `doc/` | 需求 + 使用手册 + zsh/kitty 详解 |

## 已包含的桌面能力

| 功能 | 软件 |
| --- | --- |
| 窗口管理器 | niri（无圆角 / 3px 间隙 / 活动窗口淡鹅黄边框） |
| 登录管理 | greetd + tuigreet（开机免密直进 niri，`vars.niri.autoLogin`） |
| 系统信息 | fastfetch（niri 开机自动在终端里显示一次） |
| 壁纸 | swaybg |
| 锁屏 | swaylock（`super+alt+l`） |
| 通知 | mako |
| 托盘 | tray-tui（`super+shift+t`，终端内） |
| 输入法 | 默认不安装；装好系统后按 `doc/系统需求.md` 三步开启（水杉 MSIME + fcitx5） |

> 状态栏（waybar）已移除；需要可自行加回，步骤见 `doc/系统需求.md` 第九节。
> 输入法默认关闭：启用后需从 GitHub 拉 `msime` 与 `chinese-ime-lm` 两个仓库，
> 安装阶段易失败，建议进系统后再开。

## 文档

- [`doc/系统需求.md`](doc/系统需求.md)：需求、已确认决策、变量表、安装、二次加工、注意项
- [`doc/whichkey.md`](doc/whichkey.md)：**键位速查**（super+space/t/q/hjkl …）+ 怎么自己改键位
- [`doc/zsh.md`](doc/zsh.md)：zsh 配置详解与扩展方式
- [`doc/kitty.md`](doc/kitty.md)：kitty 配置详解与字体校验
