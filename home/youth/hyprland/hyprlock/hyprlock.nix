# ============================================================================
# home/youth/hyprland/hyprlock/hyprlock.nix —— 锁屏程序配置
# ----------------------------------------------------------------------------
# hyprlock 是 Hyprland 生态的锁屏程序，基于 swww 实现，支持模糊、
# 动画与模块化布局，且与 hyprland 的动画曲线保持一致。
#
# 调用方式：
#   hyprlock                      直接启动
#   hyprlock --lock               仅上锁（休眠时用）
#   hyprlock --dpms-off           上锁并关闭屏幕
#
# 配合 wlogout 中的「锁屏」按钮使用（见 ../wlogout/wlogout.nix）。
# ============================================================================

# 模块参数：pkgs —— 包集合；... —— 接受其它未声明的参数
{pkgs, ...}: {
  home.packages = with pkgs; [
    hyprlock # 锁屏程序本体
  ];

  programs.hyprlock.enable = true; # 注册 hyprlock 命令与桌面项

  # 把主题配置安装到 ~/.config/hypr/hyprlock.conf
  # 说明：路径以 "/" 开头表示相对于 home 目录，即 ~/.config/hypr/hyprlock.conf
  home.file."/.config/hypr/hyprlock.conf".source = ./hyprlock.conf;
}