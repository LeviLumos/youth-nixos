#!/usr/bin/env bash
# koru.sh —— Koru CLI 主入口：解析 group/action 两级子命令并分发到 koru/*.sh。
# file 与 click 两个工具型子命令因参数风格特殊，直接 exec 交给 koru/file.py
#   与 koru/click.py；其余 group 先校验合法性，再 source koru/<group>.sh
#   并调用 koru_<group> 入口函数。
# 部署方式：由 lib/koru-package.nix 打包进 koru 包（writeShellApplication，
#   PATH 受控 + shellcheck），仓库根固定为 ~/.config/nixos。
# 全局约定：操作日志在 ${XDG_STATE_HOME:-~/.local/state}/koru/，写操作经
#   common.sh 的 koru_lock 互斥。
set -euo pipefail

script_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/koru/common.sh
source "$script_dir/koru/common.sh"
koru_init

# Utility commands take their own arguments, unlike the maintenance groups.
# 工具型子命令：参数结构与其他 group 不同，提前分流
if [[ ${1:-} == file ]]; then
  shift
  exec python3 "$script_dir/koru/file.py" "$@"
fi
# 同上：click 子命令
if [[ ${1:-} == click ]]; then
  shift
  exec python3 "$script_dir/koru/click.py" "$@"
fi

# 第一级子命令（group）白名单校验，空则打印总帮助
group=${1:-}
action=${2:-}
case $group in
  '') koru_help; exit 0 ;;
  -h | --help) (($# == 1)) || koru_usage 'Unexpected arguments.'; koru_help; exit 0 ;;
  system | home | profile | proxy | store) ;;
  *) koru_usage "Unknown group: $group" ;;
esac
# 第二级子命令（action）白名单校验；非法组合直接 usage 退出
case $action in
  '' | -h | --help)
    (($# <= 2)) || koru_usage 'Unexpected arguments.'
    koru_help "$group"; exit 0 ;;
esac
shift 2
case "$group:$action" in
  home:modules | home:enable | home:disable | home:validate) ;;
  profile:build | profile:check | profile:status | profile:list | profile:rollback) ;;
  system:build | system:check | system:list | system:rollback | home:build | home:check | home:list | home:rollback | proxy:status | proxy:list | proxy:refresh | proxy:start | proxy:stop | proxy:autostart | store:gc | store:status) ;;
  *) koru_usage "Unknown command: $group $action" ;;
esac
if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  (($# == 1)) || koru_usage 'Unexpected arguments.'
  koru_help "$group" "$action"; exit 0
fi
# 按动作类型校验剩余参数：rollback 必须 --generation 正整数；
# enable/disable 需至少一个合法模块名；其余不接受参数
generation=''
# Command modules consume this array after argument validation.
# shellcheck disable=SC2034
module_names=()
if [[ $action == rollback ]]; then
  case ${1:-} in
    --generation) (($# == 2)) || koru_usage 'Use --generation ID.'; generation=$2 ;;
    --generation=*) (($# == 1)) || koru_usage 'Unexpected arguments.'; generation=${1#*=} ;;
    *) koru_usage 'Use --generation ID.' ;;
  esac
  [[ $generation =~ ^[1-9][0-9]*$ ]] || koru_usage 'Generation must be a positive integer.'
elif [[ $action == enable || $action == disable ]]; then
  (($# > 0)) || koru_usage 'At least one module name is required.'
  for name in "$@"; do
    [[ $name =~ ^[A-Za-z0-9][A-Za-z0-9-]*$ ]] || koru_usage "Invalid module name: $name"
  done
  # shellcheck disable=SC2034
  module_names=("$@")
else
  (($# == 0)) || koru_usage 'This command takes no arguments.'
fi
# source 对应命令模块并执行入口函数 koru_<group>
# shellcheck source=/dev/null
source "$script_dir/koru/$group.sh"
"koru_$group" "$action"
# list/status/modules 属于查询输出，不再补打印 Done
case $action in
  list | status | modules) ;;
  *) koru_line success 'Done.' ;;
esac
