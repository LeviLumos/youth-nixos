# imv.nix —— imv 图片查看器模块（Wayland 原生、键盘驱动）。
# 角色：home/ 用户层软件模块；由 enable.imv 开关控制；安装 pkgs.imv 并
#   通过 xdg.configFile 生成 ~/.config/imv/config。
# 引用链：flake.nix → home/default.nix → 本文件；theme 经 specialArgs 传入。
# 数据流：颜色/字体全部取自全局 theme，使图片黑边与桌面背景融为一体；
#   niri 键位 Alt+i 用 imv 打开图片目录。
# --- imv ---
# Wayland-native image viewer, keyboard-driven and minimal like zathura. Colors
# and font come from the global theme so the letterbox blends with the desktop
# instead of flashing stock black.
#
# Only appearance is set here: imv's built-in binds already cover the useful
# keys (Left/Right = previous/next image, j/k/h/l = pan, +/- = zoom, q = quit,
# f = fullscreen, d = overlay), so none are redefined.
#
# Refs: https://man.archlinux.org/man/imv.5
{
  lib,
  pkgs,
  theme,
  ...
}:
let
  # imv takes a bare 6-digit hex code (no leading '#').
  hex = lib.removePrefix "#";
in
{
  home.packages = [ pkgs.imv ];

  xdg.configFile."imv/config".text = ''
    [options]
    background = ${hex theme.bg}
    overlay = true
    overlay_font = ${theme.font}:${toString theme.font-size-bar}
    overlay_text = $imv_current_file
    overlay_text_color = ${hex theme.fg}
    overlay_background_color = ${hex theme.black}
  '';
}
