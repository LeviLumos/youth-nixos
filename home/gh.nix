# gh.nix —— GitHub CLI 模块。
# 角色：home/ 用户层软件模块；由 enable.gh 开关控制（当前为 true）。
# 引用链：flake.nix → home/default.nix → 本文件。
# 数据流：home/git.nix 的凭据助手经 lib.getExe 调用本包的 gh。
# --- gh ---
# GitHub CLI.
{ pkgs, ... }:
{
  home.packages = [ pkgs.gh ];
}
