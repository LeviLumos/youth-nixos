# ripgrep.nix —— ripgrep（现代 grep 替代品）模块。
# 角色：home/ 用户层纯安装模块，由 enable.ripgrep 开关控制。
# 引用链：flake.nix → home/default.nix → 本文件。
# 数据流：仅安装 pkgs.ripgrep，供命令行与编辑器类工具按 PATH 调用。
# --- ripgrep ---
# Modern `grep` replacement.
{ pkgs, ... }:
{
  home.packages = [ pkgs.ripgrep ];
}
