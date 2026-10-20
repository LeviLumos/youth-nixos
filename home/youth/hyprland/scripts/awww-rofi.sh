#!/usr/bin/env bash
# ============================================================================
# awww-rofi.sh —— 通过 rofi 选择并切换动态壁纸
# ----------------------------------------------------------------------------
# 作用：扫描壁纸目录，用 rofi 弹出带缩略图的壁纸选择器，
#       选中后通过 awww（基于 swww 的动画壁纸工具）带过渡动画切换壁纸。
#
# 使用场景：Noctalia 桌面 Shell 的壁纸按钮绑定到本脚本
#           （安装位置 ~/.config/wallpaper/script/awww-rofi.sh，
#            由 ../scripts/default.nix 声明安装）。
#
# 依赖：
#   awww / awww-daemon  动画壁纸切换工具（配置见 ../../wallpaper/awww.nix）
#   rofi                 选择器 UI（主题见 ../../rofi/）
#   notify-send          桌面通知
#
# 可覆盖的环境变量：
#   WALLPAPER_DIR —— 壁纸目录，默认 ~/.config/wallpaper
#   ROFI_THEME    —— rofi 主题，默认 wallpaper_2_line.rasi（两行式布局）
# ============================================================================

# 严格模式：命令出错立即退出、未定义变量报错、管道失败即失败
set -euo pipefail

# ---------------------------------------------------------------------------
# 配置（${VAR:-默认值} 形式允许用环境变量覆盖）
# ---------------------------------------------------------------------------
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/.config/wallpaper}"       # 壁纸存放目录
ROFI_THEME="${ROFI_THEME:-$HOME/.config/rofi/themes/wallpaper_2_line.rasi}" # 选择器主题

# ---------------------------------------------------------------------------
# 确保 awww 守护进程在运行
# 说明：awww-daemon 负责渲染与动画，若未运行则 awww img 无效；
#       pgrep -x 精确匹配进程名，避免误判其它包含同名子串的进程。
# ---------------------------------------------------------------------------
if ! pgrep -x "awww-daemon" >/dev/null 2>&1; then
  awww-daemon >/dev/null 2>&1 &
  sleep 0.25 # 等待守护进程完成初始化
fi

# ---------------------------------------------------------------------------
# 收集壁纸文件
# mapfile -t 把 find 输出按行读入数组（每行一个元素，无分隔符干扰）
# -L 跟随符号链接；-iname 忽略大小写匹配扩展名
# ---------------------------------------------------------------------------
mapfile -t WALLS < <(find -L "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)
[ ${#WALLS[@]} -eq 0 ] && {
  rofi -e "在 $WALLPAPER_DIR 中未找到壁纸" # -e 直接弹出错误消息框
  exit 1
}

# ---------------------------------------------------------------------------
# 构建 rofi 菜单
# 数据格式：<显示名>\0icon\x1f<图标路径>
#   \0        分隔显示文本与图标字段
#   \x1f      rofi 的字段分隔符（ASCII 单元分隔符）
#   这里直接以原始图片文件作为图标，形成缩略图预览。
# ---------------------------------------------------------------------------
MENU_ITEMS=""
for wp in "${WALLS[@]}"; do
  name=$(basename "$wp")            # 只显示文件名，避免路径过长
  MENU_ITEMS+="$name\0icon\x1f$wp\n"
done

# ---------------------------------------------------------------------------
# 显示 rofi 菜单
# ---------------------------------------------------------------------------
ROFI_CMD=(rofi -dmenu -p "选择壁纸" -show-icons) # -dmenu 列表模式；-show-icons 显示图标列

if [ -n "$ROFI_THEME" ]; then
  ROFI_CMD+=(-theme "$ROFI_THEME") # 应用自定义主题
fi

# printf '%b' 用于把转义序列（\0 \x1f）解析为真实控制字符
CHOICE=$(printf '%b' "$MENU_ITEMS" | "${ROFI_CMD[@]}")

[ -z "$CHOICE" ] && exit 0 # ESC 取消时直接退出，不做任何操作

# ---------------------------------------------------------------------------
# 由文件名反查完整路径（rofi 只返回显示名）
# ---------------------------------------------------------------------------
SELECTED=""
for wp in "${WALLS[@]}"; do
  if [ "$(basename "$wp")" = "$CHOICE" ]; then
    SELECTED="$wp"
    break
  fi
done

if [ -z "$SELECTED" ]; then
  echo "错误: 未找到对应的壁纸文件" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 随机选择过渡动画，避免每次切换效果雷同
# ---------------------------------------------------------------------------
types=(fade grow outer center wipe wave simple left top right bottom any)

# $RANDOM 取随机数后对数组长度取模，得到随机下标
random_transition=${types[$RANDOM % ${#types[@]}]}

# ---------------------------------------------------------------------------
# 切换壁纸
# 参数说明：
#   --transition-type      过渡动画类型
#   --transition-duration  过渡时长（秒）
#   --transition-fps       动画帧率，越高越顺滑
#   --transition-bezier    缓动曲线（0.22,1,0.36,1 为 easeOutQuint，观感柔和）
# ---------------------------------------------------------------------------
awww img "$SELECTED" \
  --transition-type "$random_transition" \
  --transition-duration 2 \
  --transition-fps 144 \
  --transition-bezier 0.22,1,0.36,1

# ---------------------------------------------------------------------------
# 发送桌面通知（以新壁纸作为通知图标）
# ---------------------------------------------------------------------------
if command -v notify-send >/dev/null 2>&1; then
  notify-send "壁纸已切换" "$(basename "$SELECTED") - 效果: $random_transition" -i "$SELECTED"
fi
