# ============================================================================
# home/youth/wallpaper/default.nix —— 壁纸子模块入口
# ----------------------------------------------------------------------------
# 本目录负责「动态壁纸」能力：
#   awww.nix —— 安装 awww（基于 swww 的动画壁纸切换工具）
#              并把 image/ 下的所有壁纸安装到 ~/.config/wallpaper/
#
# 壁纸切换入口：
#   - 脚本  ~/.config/wallpaper/script/awww-rofi.sh（由 hyprland/scripts 安装）
#           通过 rofi 选择壁纸并带过渡动画切换
#   - 快捷键 Super+Shift+W（见 hyprland/hypr/hyprland.lua）
#   - Noctalia 桌面 Shell 的壁纸按钮
# ============================================================================
{
  imports = [
    ./awww.nix # awww 动画壁纸工具与壁纸目录安装
  ];
}
