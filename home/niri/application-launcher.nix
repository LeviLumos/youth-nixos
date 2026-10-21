# application-launcher.nix —— 应用启动器模块：wmenu-frecency（按使用频率排序）。
# 是什么：home-manager 模块，安装自制 wmenu-frecency 包装脚本与 wmenu 选单；
#   脚本仿照 wmenu-run 枚举 PATH 下全部可执行文件，但按
#   “使用次数 / (1 + 距上次使用天数)” 的 frecency 评分排序。
# 角色与引用：被 home/niri.nix 导入；niri.nix 将可执行名 wmenu-frecency
#   作为 menu 变量传入 keybindings.nix，绑定到 Alt+d，是桌面默认启动入口。
# 依赖/数据流：
#   - theme（system/theme.nix，经 flake specialArgs 传入）经 lib/wmenu-style.nix
#     生成 wmenu 颜色/字体参数，与 home/clipboard-history.nix 共享；
#   - 运行时使用历史存于 ~/.cache/wmenu/history（制表符分隔：次数、时间戳、程序名）。
# Niri application launcher with frecency ordering.
{
  lib,
  pkgs,
  theme,
  ...
}:
let
  # 脚本运行期依赖的 coreutils/gawk 所在目录（拼为 PATH 前缀）
  # Coreutils + gawk for the frecency wrapper, prepended to PATH at run time
  # (the wrapper later execs the picked app, so the original PATH is kept).
  scriptPath = lib.makeBinPath [
    pkgs.coreutils
    pkgs.gawk
  ];
  # wmenu 外观参数：颜色/字体来自全局 theme；纯 wmenu 保持 stdin 顺序，frecency 排序才成立
  # wmenu styling (colors/font from the global theme), shared with
  # clipboard-history.nix via lib/module-discovery.nix. Plain `wmenu` preserves the order of its
  # stdin, so the frecency wrapper below can rank by usage.
  wmenu-opts = import ../../lib/wmenu-style.nix { inherit lib theme; };

  # 核心脚本本体：frecency = 次数 / (1 + 距上次使用天数)
  # Frecency launcher: lists the same $PATH executables wmenu-run would, but
  # ranks them by usage so recently/frequently used apps come first. Score =
  # count / (1 + days since last use). History lives in ~/.cache/wmenu/history.
  wmenu-frecency = pkgs.writeShellScriptBin "wmenu-frecency" ''
    # 严格模式：任何一步失败立即退出，避免写出半更新的历史文件
    set -eu
    # Frecency scoring leans on coreutils + gawk; pin them instead of trusting
    # the ambient PATH. Keep the ambient PATH too so the picked app below can
    # still be exec'd from the user profile, but remember it: the candidate
    # list must mirror wmenu-run's, so the pinned tool dirs (whose coreutils
    # ships `[`) must not leak into it.
    ambient_path=$PATH
    export PATH=${scriptPath}:$PATH

    # 历史文件位置：~/.cache/wmenu/history（制表符分隔：次数、时间戳、程序名）
    cache="''${XDG_CACHE_HOME:-$HOME/.cache}/wmenu"
    history="$cache/history"
    mkdir -p "$cache"
    touch "$history"

    # Candidate list: non-hidden executables in $PATH, deduplicated. Skip `[`
    # and `test` (coreutils' own aliases, present in /run/current-system/sw/bin):
    # they are not launchable apps and just exit non-zero.
    # 生成候选列表：与 wmenu-run 相同地枚举 PATH 可执行文件并去重
    list=$(mktemp)
    trap 'rm -f "$list"' EXIT
    IFS=: read -ra dirs <<<"$ambient_path"
    for d in "''${dirs[@]}"; do
      [ -d "$d" ] || continue
      for f in "$d"/*; do
        case "''${f##*/}" in
          "[" | test) continue ;;
        esac
        if [ -x "$f" ] && [ ! -d "$f" ]; then printf '%s\n' "''${f##*/}"; fi
      done
    done | sort -u > "$list"

    # 从历史文件读出使用表（次数、最后使用时间戳）到关联数组
    # Usage table from the history file (count, last-used epoch, name).
    declare -A count last
    while IFS=$'\t' read -r c l n; do
      [ -n "''${n:-}" ] || continue
      count["$n"]="$c"
      last["$n"]="$l"
    done < "$history"

    # 计算每个候选的分数，降序排序后交给 wmenu 展示；未选中则退出
    now=$(date +%s)
    selection=$(
      while IFS= read -r name; do
        c="''${count["$name"]:-0}"
        l="''${last["$name"]:-0}"
        age=$(( (now - l) / 86400 ))
        printf '%d\t%s\n' "$(( c * 1000 / (1 + age) ))" "$name"
      done < "$list" | sort -srn -k1,1 | cut -f2- | ${lib.getExe pkgs.wmenu} ${wmenu-opts}
    ) || exit 0
    [ -n "$selection" ] || exit 0

    # Record the choice (count++, timestamp=now), then run it.
    # 记录本次选择：次数 +1、时间戳更新；新程序则追加记录
    tmp=$(mktemp)
    awk -F '\t' -v name="$selection" -v now="$now" '
      $3 == name { print $1 + 1 "\t" now "\t" name; found = 1; next }
      { print }
      END { if (!found) print "1\t" now "\t" name }
    ' "$history" > "$tmp"
    mv "$tmp" "$history"

    # 用 /bin/sh 执行选中的名字（它只是可执行文件名，不是桌面文件）
    exec /bin/sh -c "$selection"
  '';
in
{
  home.packages = [
    wmenu-frecency
    pkgs.wmenu
  ];
}
