#!/usr/bin/env bash
# ============================================================================
# toggle-power-profile.sh —— 电源模式查询与切换
# ----------------------------------------------------------------------------
# 被 Waybar 的 custom/powerprofile 模块调用（见 ../waybar.nix），用于显示
# 当前电源模式并在点击时循环切换。
#
# 依赖：power-profiles-daemon（系统级服务在 configuration.nix 中启用），
#       通过 powerprofilesctl 命令进行查询与设置。
#
# 用法：
#   toggle-power-profile.sh get      查询当前模式，输出 Waybar 所需的 JSON
#   toggle-power-profile.sh toggle   切换到下一个模式（省电 -> 平衡 -> 性能）
#
# 可用模式：
#   power-saver  节能（限制频率、节能策略）
#   balanced     平衡（默认）
#   performance  性能（提升频率，耗电与发热更高）
#
# 安装位置：~/.config/waybar/scripts/toggle-power-profile.sh
#           （由 ../waybar.nix 中的 home.file 声明并设置可执行权限）
# ============================================================================

# 严格模式：命令出错立即退出、未定义变量报错、管道失败即失败
set -euo pipefail

# ---------------------------------------------------------------------------
# 配置数据
# ---------------------------------------------------------------------------
profiles=("power-saver" "balanced" "performance")          # power-profiles-daemon 的模式名
# icons=("" "" "")  # Nerd Font 图标（备选方案，取消注释可换回图标显示）
icons=("节能" "平衡" "性能")                                 # 状态栏中显示的短文字
labels=("省电模式" "平衡模式" "性能模式")                      # 悬浮提示中显示的完整名称

# 查询当前模式（输出 power-saver / balanced / performance）
current=$(powerprofilesctl get)

# ---------------------------------------------------------------------------
# 按子命令分发
# ---------------------------------------------------------------------------
case "$1" in
"get")
  # 查询模式：输出 JSON，字段需与 Waybar 的 return-type = "json" 对应
  #   text    —— 直接显示在状态栏上的内容
  #   tooltip —— 鼠标悬浮时显示的提示
  for i in "${!profiles[@]}"; do
    if [[ "$current" == "${profiles[i]}" ]]; then
      echo "{\"text\":\"${icons[i]} \", \"tooltip\":\"当前模式：${labels[i]}\"}"
      exit
    fi
  done
  # 理论上不会走到这里；保底输出未知状态，避免状态栏显示空白
  echo "{\"text\":\"?\", \"tooltip\":\"未知模式\"}"
  ;;

"toggle")
  # 切换模式：找到当前模式的下标，循环到下一个（末尾回到开头）
  for i in "${!profiles[@]}"; do
    if [[ "$current" == "${profiles[i]}" ]]; then
      next=$(((i + 1) % ${#profiles[@]}))   # 取模实现循环
      powerprofilesctl set "${profiles[next]}"
      exit
    fi
  done
  powerprofilesctl set balanced # 保底：若当前模式不在列表中则回到平衡模式
  ;;
esac