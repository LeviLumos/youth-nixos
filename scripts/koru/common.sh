#!/usr/bin/env bash
# koru/common.sh —— 公共库：被 koru.sh source，定义全局路径变量、颜色输出封装、
# 帮助文本、构建前置检查、操作日志、flock 互斥与 generation 列表展示，
# 供 koru/*.sh 复用。
# 关键机制：
#   - koru_run：所有外部命令统一经它执行，输出经 render.py 整理，
#     完整原始日志写 operation.*.log（0600），失败时打印日志路径；
#   - koru_lock：flock 独占锁文件，防止两个 koru 操作交错执行；
#   - koru_repository：构建前置检查（必须在 flake 根执行 + 未跟踪文件告警）。
# Shared state is consumed by the sourced command modules.
# shellcheck disable=SC2034

# 初始化全局环境：统一 locale、定位仓库根/各 profile 路径；
# state 目录存在时 home-manager 走用户 state profile，否则回退到旧路径
koru_init() {
  export LC_ALL=C.UTF-8
  export LANGUAGE=en
  export LANG=C.UTF-8
  repository_root=${KORU_REPO:-$(CDPATH='' cd -- "$script_dir/.." && pwd)}
  render=$script_dir/koru/render.py
  sudo_command=${KORU_SUDO:-sudo}
  proxy_command=${KORU_PROXYCTL:-/run/current-system/sw/bin/proxyctl}
  modules_command=$script_dir/home-modules.sh
  system_profile=/nix/var/nix/profiles/system
  local state_profiles=${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles
  dev_profile=$state_profiles/koru-dev
  if [[ -d $state_profiles ]]; then
    home_profile=$state_profiles/home-manager
  else
    home_profile=/nix/var/nix/profiles/per-user/$(id -un)/home-manager
  fi
  # Direct repository execution also reads colors from the shared theme.
  # 直连仓库执行时从共享主题 system/theme.nix 读取调色板并导出 KORU_COLOR_*，供 render.py 着色
  if [[ -z ${KORU_COLOR_HEADING:-} && -f $repository_root/system/theme.nix ]]; then
    local palette
    palette=$(nix eval --json --file "$repository_root/system/theme.nix")
    export KORU_COLOR_HEADING KORU_COLOR_SUCCESS KORU_COLOR_WARNING
    export KORU_COLOR_ERROR KORU_COLOR_LABEL KORU_COLOR_VALUE KORU_COLOR_MUTED
    KORU_COLOR_HEADING=$(jq -r '."accent-bright"' <<< "$palette")
    KORU_COLOR_SUCCESS=$(jq -r '.accent' <<< "$palette")
    KORU_COLOR_WARNING=$(jq -r '."accent-yellow"' <<< "$palette")
    KORU_COLOR_ERROR=$(jq -r '.ansi.red' <<< "$palette")
    KORU_COLOR_LABEL=$(jq -r '.muted' <<< "$palette")
    KORU_COLOR_VALUE=$(jq -r '.fg' <<< "$palette")
    KORU_COLOR_MUTED=$(jq -r '."muted-alt"' <<< "$palette")
  fi
}

# 统一的终端输出封装：实际渲染交给 render.py，负责宽度裁剪与颜色
koru_line() { python3 "$render" line "$1" "$2"; }
koru_field() { python3 "$render" field "$1" "$2"; }
# 用法错误（退出码 2）与运行错误（退出码 1）
koru_usage() { koru_line error "$1" >&2; exit 2; }
koru_error() { koru_line error "$1" >&2; exit 1; }

# 分层帮助：按是否给定 group/action 打印对应层级的用法说明
koru_help() {
  local group=${1:-} action=${2:-}
  koru_line heading 'Koru CLI'
  if [[ -n $action ]]; then
    koru_line value "Usage: koru $group $action"
    if [[ $action == rollback ]]; then
      koru_line value '  --generation ID  (required)'
    elif [[ $action == enable || $action == disable ]]; then
      koru_line value '  NAME...  (one or more modules)'
    else
      koru_line muted 'No arguments.'
    fi
  else
    koru_line value "Usage: koru ${group:-GROUP} ACTION"
    if [[ -z $group || $group == system || $group == home ]]; then
      koru_line label "${group:-system / home}"
      koru_line value '  build     Build and switch'
      koru_line value '  check     Build without activation'
      koru_line value '  list      List retained generations'
      koru_line value '  rollback  Use --generation ID'
    fi
    if [[ -z $group || $group == home ]]; then
      koru_line label 'home modules'
      koru_line value '  modules   List module switches'
      koru_line value '  enable / disable NAME...'
      koru_line value '  validate  Check module switches'
    fi
    if [[ -z $group || $group == profile ]]; then
      koru_line label 'profile'
      koru_line value '  build     Build and install development tools'
      koru_line value '  check     Build without installation'
      koru_line value '  status    Installed versions and source agreement'
      koru_line value '  list      List retained generations'
      koru_line value '  rollback  Use --generation ID'
    fi
    if [[ -z $group || $group == proxy ]]; then
      koru_line label 'proxy'
      koru_line value '  status / list / refresh'
      koru_line value '  start / stop / autostart'
    fi
    if [[ -z $group ]]; then
      koru_line label 'file'
      koru_line value '  PATH      Share one file via a LAN download QR code'
      koru_line value '  --host IP / --port PORT  (default port 8080)'
      koru_line label 'click'
      koru_line value '  --frequency N  Set clicks per second (default 100)'
      koru_line value '  toggle / start / stop / status'
    fi
    if [[ -z $group || $group == store ]]; then
      koru_line label 'store'
      koru_line value '  status / gc'
    fi
  fi
  koru_line muted 'Use --help at any command level.'
}

# 构建前置检查：必须在 flake.nix 所在目录执行；
# Git flakes 不会打包未跟踪文件，检测到未跟踪的 .nix/scripts/completions
# 时提前告警，避免构建结果与本地不符
koru_repository() {
  [[ -f $repository_root/flake.nix ]] || koru_error 'Configuration repository not found.'
  cd -- "$repository_root" || koru_error 'Cannot enter configuration repository.'
  local untracked
  untracked=$(git ls-files --others --exclude-standard -- '*.nix' 'scripts/*' 'completions/*')
  if [[ -n $untracked ]]; then
    koru_line warning 'Untracked sources are ignored by Git flakes.' >&2
    koru_line warning 'Review git status before building.' >&2
  fi
}

# 运行命令并把输出经 render.py 整理后写到 stderr；完整原始日志写入
# XDG state 下 koru/operation.*.log（0600 权限，可能含敏感路径）；
# 失败时打印日志路径便于排查，并以原退出码退出
koru_run() {
  local log_dir=${XDG_STATE_HOME:-$HOME/.local/state}/koru status=0
  mkdir -p -- "$log_dir"
  chmod 700 -- "$log_dir"
  local log_file
  log_file=$(mktemp "$log_dir/operation.XXXXXXXX.log")
  chmod 600 -- "$log_file"
  "$@" 2>&1 | tee "$log_file" | python3 "$render" logs >&2 || status=$?
  if ((status != 0)); then
    koru_line error "Operation failed (exit $status)." >&2
    koru_line label 'Full log:' >&2
    printf '%s\n' "$log_file" | python3 "$render" logs >&2
    exit "$status"
  fi
}

# 进程级互斥：flock 独占锁文件（优先 XDG_RUNTIME_DIR），
# 防止两个 koru 操作（如同时 build 与 rollback）交错执行
koru_lock() {
  local lock_dir=${XDG_RUNTIME_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/koru}
  mkdir -p -- "$lock_dir"
  exec {koru_lock_fd}>"$lock_dir/koru-operation.lock"
  flock -n "$koru_lock_fd" || koru_error 'Another Koru operation is running.'
}

# 列出 <profile>-<N>-link 保留代，按版本号倒序；当前 profile 指向的代标记星号；
# 便于 rollback 前确认可用代
koru_generations() {
  local profile=$1 link id stamp marker found=false current
  current=$(readlink "$profile" 2>/dev/null || true)
  koru_line heading "$2 generations"
  while IFS= read -r link; do
    [[ -L $link ]] || continue
    found=true
    id=${link##*/}; id=${id#"${profile##*/}-"}; id=${id%-link}
    stamp=$(date --date="@$(stat --format=%Y "$link")" '+%Y-%m-%d %H:%M')
    marker=''
    [[ ${current##*/} != "${link##*/}" ]] || marker=' *'
    koru_line value "  $id$marker  $stamp"
  done < <(printf '%s\n' "$profile"-*-link | sort -V -r)
  if [[ $found == false ]]; then
    koru_line muted 'No retained generations.'
  else
    koru_line muted '* Current profile generation'
  fi
}
