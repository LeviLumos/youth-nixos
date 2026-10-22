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

# 清理 30 天前的旧世代
gc:
    sudo nix-collect-garbage --delete-older-than 30d

# （重新）生成本机硬件配置到 hosts/<hostname>/
hw:
    sudo nixos-generate-config --show-hardware-config > hosts/{{ hostname }}/hardware-configuration.nix

# 水杉输入法首次配置：下载词库并加入 fcitx5
ime-setup:
    msime-linux-setup --download

# 校验 Maple Mono 字体族名（改 vars.fonts.mono.family 用）
font-check:
    fc-list | grep -i maple

# 查看 niri 支持的所有 action（改键位用）
niri-actions:
    niri msg action
