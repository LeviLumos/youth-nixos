# ============================================================================
# home/youth/noctalia/noctalia.nix —— Noctalia 桌面 Shell
# ----------------------------------------------------------------------------
# 作用：启用 Noctalia（基于 Quickshell 的 Wayland 桌面 Shell），
#       提供状态栏、启动菜单、壁纸与音量控制等聚合面板。
#
# 为什么关闭 systemd 托管：
#   systemd.enable = false 表示不注册为 systemd 用户服务，
#   改为「手动启动」。原因是本机使用 Hyprland 时已在 hyprland.lua 的
#   hyprland.start 事件中手动拉起相关进程，避免重复启动两个实例。
#
# 启动方式：
#   noctalia-shell &        # 手动启动
#   hyprctl reload          # 若在 Hyprland 下修改了配置，可重载后生效
# ============================================================================
# 形参使用 `_` 表示不需要任何 home-manager 模块参数
_: {
  # 手动启动
  programs.noctalia.systemd.enable = false;
  programs.noctalia.enable = true; # 启用 Noctalia（安装程序并注册应用）
}
