# eza.nix —— 现代 ls 替代品 eza 模块（图标/树形/git 状态列目录）。
# 角色：home/ 用户层软件模块；由 enable.eza 开关控制（当前为 true）。
# 引用链：flake.nix → home/default.nix → 本文件；alias 由 home/zsh.nix 定义。
# --- eza ---
# Modern `ls` replacement (aliases live in home/zsh.nix).
{ pkgs, ... }:
{
  home.packages = [ pkgs.eza ];
}
