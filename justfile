# just —— 写 CLI 命令的工具（已在 home.packages 中安装 pkgs.just）
# 用法：just <命令>，例如 just switch

# 当前主机名（应与 vars.nix 里的 hostname 一致）
hostname := `hostname`

# 列出所有命令
default:
    @just --list

# 试运行（不写入引导，重启可回退）
test:
    sudo nixos-rebuild test --flake .

# 正式切换（写入引导项）
switch:
    sudo nixos-rebuild switch --flake .

# 只构建，不切换
build:
    sudo nixos-rebuild build --flake .

# 更新 flake 依赖
update:
    nix flake update

# 手动回收：删掉 7 天前的旧世代（与 vars.nixGc.deleteOlderThan 保持一致）
gc:
    sudo nix-collect-garbage --delete-older-than 7d

# 激进回收：只保留当前世代（磁盘告急时用）
gc-all:
    sudo nix-collect-garbage -d

# 只删空目录里的旧 profile 世代（不动 store，最温和）
gc-old:
    sudo nix-collect-garbage --delete-old

# 查看下次自动 GC 时间 + 定时器状态
gc-status:
    systemctl list-timers nix-gc nix-optimise

# 查看 /nix 占用与磁盘余量
store-size:
    du -sh /nix/store 2>/dev/null; df -h /nix

# （重新）生成本机硬件配置到 hosts/<hostname>/
hw:
    sudo nixos-generate-config --show-hardware-config > hosts/{{ hostname }}/hardware-configuration.nix

# 水杉输入法首次配置：下载词库并加入 fcitx5
# ⚠️ 需先启用输入法（vars.inputMethod.enable=true）
ime-setup:
    msime-linux-setup --download

# 校验 Maple Mono 字体族名（改 vars.fonts.mono.family 用）
font-check:
    fc-list | grep -i maple

# 查看 niri 支持的所有 action（改键位用）
niri-actions:
    niri msg action
