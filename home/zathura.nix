# zathura.nix —— zathura（vim 键位 PDF 阅读器）模块。
# 角色：home/ 用户层软件模块，由 enable.zathura 开关控制。
# 引用链：flake.nix → home/default.nix → 本文件；theme 经 extraSpecialArgs 传入。
# 数据流：配色/字体全部取自 theme（programs.zathura.options 生成
#   ~/.config/zathura/zathurarc），并经 poppler 后端渲染 PDF；
#   selection-clipboard 指向 Wayland 剪贴板。
# --- zathura ---
# Keyboard-driven PDF viewer (vim-like keys, minimal chrome). Colors and font
# come from the global theme so it matches the rest of the desktop.
#
# Refs: https://man.archlinux.org/man/zathurarc.5
{ theme, ... }:
{
  programs.zathura = {
    enable = true;
    options = {
      font = "${theme.font} ${toString theme.font-size-bar}";
      default-bg = theme.bg;
      default-fg = theme.fg;
      statusbar-bg = theme.bg-alt;
      statusbar-fg = theme.fg;
      inputbar-bg = theme.bg;
      inputbar-fg = theme.fg-bright;
      completion-bg = theme.bg-alt;
      completion-fg = theme.fg;
      completion-highlight-bg = theme.accent-yellow;
      completion-highlight-fg = theme.black;
      highlight-color = theme.accent-yellow;
      highlight-active-color = theme.accent-bright;
      # Copying a selection should reach other apps (Wayland clipboard).
      selection-clipboard = "clipboard";
      adjust-open = "best-fit";
      scroll-step = 60;
    };
  };
}
