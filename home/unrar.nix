# unrar.nix —— unrar（RAR 解压器）模块。
# 角色：home/ 用户层纯安装模块，由 enable.unrar 开关控制。
# 引用链：flake.nix → home/default.nix → 本文件。
# 数据流：仅安装 pkgs.unrar；因 RAR7 格式 7zz 读不了，属于按需补位的
#   解压工具，与 unzip、zsh 的 extract 插件共同覆盖归档格式。
# --- unrar ---
# RAR extractor. Needed once for the course-provided Labsetup.rar, which uses
# the RAR7 format that 7zz cannot read.
{ pkgs, ... }:
{
  home.packages = [ pkgs.unrar ];
}
