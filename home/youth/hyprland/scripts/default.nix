# ============================================================================
# home/youth/hyprland/scripts/default.nix —— 辅助脚本安装
# ----------------------------------------------------------------------------
# 把本目录下的 Shell 脚本安装到各自的配置路径，并赋予可执行权限。
# 说明：
#   - home.file 的键以 "/" 开头表示相对 home 目录的路径；
#   - executable = true 会设置 +x 权限，否则脚本无法被快捷键直接调用。
#
# 脚本清单与安装位置：
#   capture.sh            -> ~/.config/hypr/scripts/capture.sh
#                          截图与录屏的统一入口（由 hyprland.lua 的快捷键调用）
#   wf-recorder-status.sh -> ~/.config/waybar/scripts/wf-recorder-status.sh
#                          供 waybar 状态栏轮询，显示当前是否在录屏
#   awww-rofi.sh          -> ~/.config/wallpaper/script/awww-rofi.sh
#                          通过 rofi 选择并切换动态壁纸（供 Noctalia 壁纸按钮调用）
# ============================================================================
# 形参使用 `_` 表示不需要任何 home-manager 模块参数
_: {
  # ------------------------------------------------------------------------
  # Hyprland 录屏与截图快捷键脚本
  # ------------------------------------------------------------------------
  home.file.".config/hypr/scripts/capture.sh" = {
    source = ./capture.sh; # 脚本来源
    executable = true; # 设置可执行权限（缺少则快捷键会提示 Permission denied）
  };

  #------------- 录制辨识 ------------#
  # ------------------------------------------------------------------------
  # 录屏状态指示脚本（供 waybar 轮询）
  # ------------------------------------------------------------------------
  home.file.".config/waybar/scripts/wf-recorder-status.sh" = {
    source = ./wf-recorder-status.sh; # 脚本来源
    executable = true; # 设置可执行权限
  };

  # ------------------------------------------------------------------------
  # 壁纸切换脚本（rofi 选择器）
  # ------------------------------------------------------------------------
  home.file.".config/wallpaper/script/awww-rofi.sh" = {
    source = ./awww-rofi.sh; # 脚本来源
    executable = true; # 设置可执行权限
  };
}
