# drawio.nix —— 桌面图表绘制工具 drawio 模块。
# 角色：home/ 用户层软件模块；由 enable.drawio 开关控制（当前为 true）。
# 引用链：flake.nix → home/default.nix → 本文件；仅安装软件包，无主题依赖。
# --- drawio ---
# Desktop diagram editor for flowcharts, architecture diagrams, and more.
{ pkgs, ... }:
{
  home.packages = [ pkgs.drawio ];
}
