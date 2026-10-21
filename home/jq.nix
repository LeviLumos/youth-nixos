# jq.nix —— jq（JSON 处理器）模块。
# 角色：home/ 用户层最简单的纯安装模块之一，由 enable.jq 开关控制。
# 引用链：flake.nix → home/default.nix → 本文件。
# 数据流：仅把 pkgs.jq 加入 home.packages，无配置文件；shell 层（koru 脚本、
#   补全脚本等）按需在 PATH 中调用它。
# --- jq ---
# JSON processor (handy in the shell; power-profile uses a pinned copy from the
# system layer).
{ pkgs, ... }:
{
  home.packages = [ pkgs.jq ];
}
