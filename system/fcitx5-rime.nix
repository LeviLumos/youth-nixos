# fcitx5-rime.nix —— 系统级输入法框架（Fcitx5 + Rime/雾凇拼音）。
# 作用：安装 Fcitx5 框架、Rime 引擎（内嵌 rime-ice 数据，免手动下载词库）
#   与 GTK/Qt 图形支持模块，并注入全局输入法环境变量。
# 导入：由 system/default.nix 显式导入。
# 机制：i18n.inputMethod 由 NixOS 模块安装软件包并设置系统级 IM 环境变量；
#   Wayland 前端模式使 fcitx5 直接对接 Wayland 合成器（Niri）。
# 依赖：用户级的 Rime 配置/主题/词库在 home/fcitx5.nix（home-manager 层）。
# --- input-method ---
# Fcitx5 input method framework (system side: engine + install + IM env vars).
# The Chinese engine is Rime with the rime-ice scheme; per-user theme, profile
# and Rime config live in home/fcitx5.nix.
{ pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      # Rime engine; rime-ice (Wu Song) becomes its shared data dir, so no
      # GitHub fetch or manual dictionary copying is needed at runtime.
      (fcitx5-rime.override { rimeDataPkgs = [ rime-ice ]; })
      fcitx5-gtk
      qt6Packages.fcitx5-configtool
    ];
  };

  environment.variables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "fcitx";
  };
}
