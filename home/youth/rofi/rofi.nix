# ============================================================================
# home/youth/rofi/rofi.nix —— rofi 安装与配置文件分发
# ----------------------------------------------------------------------------
# 本文件不修改 rofi 的行为，只负责：
#   1. 安装 rofi 程序；
#   2. 把仓库中的 .rasi 配置文件安装到 ~/.config/rofi/ 下对应位置。
#
# 配置文件清单：
#   ~/.config/rofi/config.rasi                     全局默认配置
#   ~/.config/rofi/themes/custom-theme.rasi        基础视觉主题
#   ~/.config/rofi/themes/app.rasi                 应用启动器 / 窗口切换器
#   ~/.config/rofi/themes/screenshot.rasi          截图录屏菜单
#   ~/.config/rofi/themes/wallpaper_2_line.rasi    壁纸选择器
#
# 注意：这些文件由 home-manager 管理，直接修改会在下次重建时被覆盖。
# ============================================================================

# 模块参数：pkgs —— 包集合；... —— 接受其它未声明的参数
{pkgs, ...}: {
  home.packages = with pkgs; [
    rofi # 应用启动器 / 窗口切换器
  ];

  # ------------------------------------------------------------------------
  # 配置文件安装
  # 说明：home.file 的键以 "." 开头表示相对 home 目录（~/.config/...）
  # ------------------------------------------------------------------------
  home.file.".config/rofi/config.rasi".source = ./config.rasi; # 全局默认配置

  # 各场景主题（由启动命令通过 -theme 参数指定）
  home.file.".config/rofi/themes/custom-theme.rasi".source = ./themes/custom-theme.rasi; # 基础主题
  home.file.".config/rofi/themes/wallpaper_2_line.rasi".source = ./themes/wallpaper_2_line.rasi; # 壁纸选择
  home.file.".config/rofi/themes/screenshot.rasi".source = ./themes/screenshot.rasi; # 截图录屏
  home.file.".config/rofi/themes/app.rasi".source = ./themes/app.rasi; # 应用启动
}