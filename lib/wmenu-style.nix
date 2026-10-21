# wmenu-style.nix —— wmenu（Wayland 菜单/启动器）的统一样式参数串：从主题
# 调色板生成一份共享的命令行选项，保证 niri 启动器与剪贴板选择器等各处外观
# 一致。
# 由 home/niri/application-launcher.nix 与 home/clipboard-history.nix 分别以
#   wmenu-opts = import <此文件> { inherit lib theme; } 导入，
#   结果字符串直接拼接进 wmenu 命令行。
# Shared wmenu arguments derived from the palette.
{ lib, theme }:
let
  hex = lib.removePrefix "#";  # wmenu 的颜色参数不吃井号前缀，先剥掉
in
"-f \"${theme.font} ${toString theme.font-size-bar}\" -N ${hex theme.bg} -n ${hex theme.fg} -M ${hex theme.black} -m ${hex theme.accent-yellow} -S ${hex theme.accent-yellow} -s ${hex theme.bg}"  # -f 字体/字号；-N/-n 普通项背景/文字色；-M/-m 输入区背景/文字色（文字用强调黄）；-S/-s 选中项背景/文字色（黄底 + 背景色字，形成高亮反色）
