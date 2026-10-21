# unzip.nix —— unzip（ZIP 解压器）模块。
# 角色：home/ 用户层纯安装模块，由 enable.unzip 开关控制。
# 引用链：flake.nix → home/default.nix → 本文件。
# 数据流：仅安装 pkgs.unzip，与 unrar、zsh extract 插件共同覆盖常见归档格式。
# --- unzip ---
# Extract .zip archives (companion to the zip packer).
{ pkgs, ... }:
{
  home.packages = [ pkgs.unzip ];
}
