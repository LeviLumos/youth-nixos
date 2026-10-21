# console.nix —— Linux 控制台（tty）外观模块。
# 作用：为纯文本终端设置点阵字体（Terminus ter-118n，6x12 高可读小字号）
#   与 Koru Fern 主题的控制台 16 色。
# 导入：由 system/default.nix 显式导入。
# 机制：console.font / console.colors 最终写入 /etc/vconsole.conf，
#   由内核与 systemd 在 tty 初始化时应用（非 systemd 服务）。
# 依赖：theme 经 flake 的 specialArgs 传入。
# --- tty ---
# Linux console (tty): terminus font + Koru Fern palette from the global theme.
{
  pkgs,
  lib,
  theme,
  ...
}:

{
  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-118n.psf.gz";

  console.colors = map (lib.removePrefix "#") theme.console-colors;
}
