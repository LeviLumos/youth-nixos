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

# 临时开 zram swap：不用重建、不占磁盘，立刻生效（重启失效）
# 长期方案是配置里的 zramSwap（modules/nixos/system.nix），但它要等这次重建成功才生效
swap-on:
    sudo modprobe zram
    sudo zramctl --find --size 8G
    sudo mkswap /dev/zram0
    sudo swapon -p 100 /dev/zram0
    free -h

# 关掉临时 zram swap
swap-off:
    sudo swapoff /dev/zram0

# 低内存构建：一次只构建一个 derivation、每个只用 2 核
# （编译 Rust 之类被 OOM kill 时用；比 just switch 慢，但不容易被杀）
switch-safe:
    sudo nixos-rebuild switch --flake . --option max-jobs 1 --option cores 2

# 只构建，不切换
build:
    sudo nixos-rebuild build --flake .

# 看内存 / swap（判断是否 OOM 的现场证据）
mem:
    free -h; swapon --show

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

# 看磁盘余量与 /nix/store 占用（构建报 No space left on device 时先看这个）
store-size:
    df -h / /nix /tmp 2>/dev/null; ls -lh /swapfile 2>/dev/null; du -sh /nix/store 2>/dev/null

# 清旧世代 + store 去重（磁盘告急时先跑它）
free-disk:
    sudo nix-collect-garbage -d
    nix store optimise
    df -h / /nix

# （重新）生成本机硬件配置到 hosts/<hostname>/
hw:
    sudo nixos-generate-config --show-hardware-config > hosts/{{ hostname }}/hardware-configuration.nix

# 壁纸：立刻随机换一张（从 ~/Pictures/wallpapers 里抽）
wallpaper:
    systemctl --user restart wallpaper.service

# 壁纸：临时指定某一张（不进轮换池；想固定就把它单独放进壁纸池并关掉轮换）
# 用法：just wallpaper-set ~/Downloads/xxx.jpg
wallpaper-set img:
    #!/usr/bin/env bash
    set -euo pipefail
    systemctl --user stop wallpaper.service
    ln -sfn "{{ img }}" "$HOME/Pictures/wallpaper.jpg"   # 锁屏背景跟着变
    nohup swaybg -i "{{ img }}" --mode fill >/dev/null 2>&1 &
    echo "已设为：{{ img }}（重新登录或 just wallpaper 后回到轮换）"

# 重启输入法 fcitx5（改了方案/词库后让它重新加载；不行就重新登录）
ime-restart:
    fcitx5 -rd || fcitx5 -d

# 安装/更新雾凇拼音 rime-ice（方案 + 词库）到 Rime 用户目录
# 前提：输入法已启用（vars.inputMethod.enable = true），且机器能访问 github.com
#       （克隆用的是 git over https，和平时 git pull 一样，不碰 raw.githubusercontent.com）
# 默认方案由 dotfiles/rime/default.custom.yaml 指定为雾凇双拼（nix 部署，无需手动改）
rime-ice:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="$HOME/.local/share/fcitx5/rime"
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    git clone --depth 1 https://github.com/iDvel/rime-ice "$tmp/rime-ice"
    mkdir -p "$dir"
    # 拷入全部方案与词库（default.custom.yaml 是 nix 软链，仓库里没有同名文件，不会覆盖）
    (cd "$tmp/rime-ice" && tar cf - --exclude=.git --exclude=README.md .) | (cd "$dir" && tar xf -)
    # 重启 fcitx5 触发 Rime 重新部署
    fcitx5 -rd >/dev/null 2>&1 || fcitx5 -d >/dev/null 2>&1 || true
    echo "完成：稍等几秒 Rime 部署完，Ctrl+Space 切换到雾凇双拼"

# 按清单安装 VSCodium 插件（读 ~/.config/VSCodium/extensions.txt）
code-ext:
    vscodium-install-extensions

# 校验 Maple Mono 字体族名（改 vars.fonts.mono.family 用）
font-check:
    fc-list | grep -i maple

# 查看 niri 支持的所有 action（改键位用）
niri-actions:
    niri msg action
