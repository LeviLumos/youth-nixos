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

# 查看输入法当前主题 / 已装主题（切换见 vars.nix 的 inputMethod.theme）
ime-theme:
    #!/usr/bin/env bash
    echo "当前主题: $(grep -m1 '^Theme=' "$HOME/.config/fcitx5/conf/classicui.conf" | cut -d= -f2)"
    echo "已装主题: $(ls "$HOME/.local/share/fcitx5/themes" 2>/dev/null | tr '\n' ' ')"
    echo "切换方法: vars.nix 里 inputMethod.theme = \"youth\" | \"default\" | \"dark\"，然后 just switch && just ime-restart"

# 输入法体检：一键收集 fcitx5/Rime 关键状态（主题/方案/简繁不生效时先跑这个）
ime-doctor:
    #!/usr/bin/env bash
    d="$HOME/.local/share/fcitx5/rime"
    echo "== 1. fcitx5 进程 =="
    ps -eo pid,user,lstart,cmd | grep '[f]citx5' | sed 's/^/  /' || echo "  ✗ 没有 fcitx5 进程（fcitx5 -d 启动）"
    # ⚠️ 不能只看进程：老实例可能还占着 D-Bus 名字，新实例会因重名起不来
    dbus_pid="$(busctl --user status org.fcitx.Fcitx5 2>/dev/null | grep -m1 '^PID' | awk '{print $2}')"
    if [ -n "$dbus_pid" ]; then
      echo "  ✓ D-Bus 名字持有者 PID=$dbus_pid（$(ps -o lstart= -p "$dbus_pid" 2>/dev/null)）"
      echo "    ⚠️ 若这个 PID 启动时间早于你最后一次 just switch，它用的还是旧配置：kill -9 $dbus_pid 后 fcitx5 -d"
    else
      echo "  ✗ D-Bus 上 org.fcitx.Fcitx5 无人持有 —— fcitx5 实际不可用"
    fi
    echo "== 1.5 会话环境（手动从终端起 fcitx5 常缺这个，会导致 Wayland 应用用不了输入法）=="
    echo "  WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-<空>}  DISPLAY=${DISPLAY:-<空>}"
    [ -n "${WAYLAND_DISPLAY:-}" ] || echo "  ✗ 没有 WAYLAND_DISPLAY —— 别手动 fcitx5 -d，重新登录让会话拉起"
    echo "  msime 残留: $(pgrep -af msime-linux-clipboard | head -1 || echo 无)"
    echo "== 2. 界面主题 =="
    f="$HOME/.config/fcitx5/conf/classicui.conf"
    if [ -f "$f" ]; then
      echo "  $(grep -m1 '^Theme=' "$f")  （→ $(readlink -f "$f")）"
    else echo "  ✗ 缺 $f —— just switch 没部署上"; fi
    t="$HOME/.local/share/fcitx5/themes/youth/theme.conf"
    if [ -f "$t" ]; then grep -m3 '^Color' "$t" | sed 's/^/  /'; else echo "  ✗ 缺 $t"; fi
    echo "== 3. Rime 方案文件 =="
    for x in default.custom.yaml double_pinyin_flypy.custom.yaml double_pinyin_flypy.schema.yaml; do
      [ -f "$d/$x" ] && echo "  ✓ $x" || echo "  ✗ 缺 $x（$x 含 schema 说明 just rime-ice 没跑）"
    done
    echo "  当前方案: $(grep -m1 'schema:' "$d/default.custom.yaml" 2>/dev/null | sed 's/^ *//')"
    echo "== 4. 已保存的开关状态 (user.yaml) =="
    if [ -f "$d/user.yaml" ]; then cat "$d/user.yaml" | sed 's/^/  /'; else echo "  无 user.yaml"; fi
    echo "== 5. fcitx5 输入法列表 (profile) =="
    grep -E 'DefaultIM|^Name=|Name=rime' "$HOME/.config/fcitx5/profile" 2>/dev/null | sed 's/^/  /' || echo "  ✗ 缺 profile —— rm 后 just switch 重写"
    echo "== 6. 最近一次 Rime 部署时间 =="
    ls -ld --time-style=+%F\ %T "$d/build" 2>/dev/null | awk '{print "  "$6" "$7}' || echo "  ✗ 无 build 目录（还没部署成功过）"

# 输入法恢复出厂（只清 Rime 的开关记忆与部署缓存，不动用户词库 *.userdb）
# 用法：主题/简繁/方案改了却不生效、或反复出现繁体时跑一次
ime-reset:
    #!/usr/bin/env bash
    set -euo pipefail
    d="$HOME/.local/share/fcitx5/rime"
    # 按完整命令行杀（-x 严格名匹配逮不到某些老进程）；顺带清掉水杉时代的
    # msime 剪贴板监视进程（命令行里也含 fcitx5 字样，一并死掉正合适）
    pkill -9 -f fcitx5 2>/dev/null || true
    sleep 1
    if busctl --user status org.fcitx.Fcitx5 >/dev/null 2>&1; then
      echo "✗ D-Bus 名字仍被持有，杀不干净 —— 跑 busctl --user status org.fcitx.Fcitx5 看 PID"; exit 1
    fi
    rm -f "$d/user.yaml"        # 清掉「繁体」等被记住的开关状态
    rm -rf "$d/build"           # 强制 Rime 重新部署（重读所有 custom.yaml 补丁）
    fcitx5 -d >/dev/null 2>&1 || true
    echo "已重置并重启 fcitx5，等几秒让 Rime 部署完，Ctrl+Space 试试（应为：深色候选栏 + 简体）"

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
