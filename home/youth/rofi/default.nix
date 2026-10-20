# ============================================================================
# home/youth/rofi/default.nix —— rofi 子模块入口
# ----------------------------------------------------------------------------
# rofi 是轻量级的应用启动器 / 窗口切换器，运行速度快、主题可完全自定义。
#
# 本目录提供一份「基础配置 + 多套场景主题」：
#   rofi.nix                  安装 rofi 并分发配置文件
#   config.rasi               全局默认配置（快捷键、显示行为等）
#   themes/custom-theme.rasi 基础视觉主题（被 config.rasi 引用）
#   themes/app.rasi           应用启动器主题（Super+D）
#   themes/screenshot.rasi    截图/录屏菜单主题（capture.sh 使用）
#   themes/wallpaper_2_line.rasi 壁纸选择器主题（awww-rofi.sh 使用）
#
# 使用方式：
#   rofi -show drun    -theme ~/.config/rofi/themes/app.rasi  # 应用启动器
#   rofi -show window  -theme ~/.config/rofi/themes/app.rasi  # 窗口切换器
# ============================================================================
{
  imports = [
    ./rofi.nix # rofi 安装与配置分发
  ];
}
