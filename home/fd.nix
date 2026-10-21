# fd.nix —— 现代 find 替代品 fd 模块。
# 角色：home/ 用户层软件模块；由 enable.fd 开关控制（当前为 true）。
# 引用链：flake.nix → home/default.nix → 本文件。
# 数据流：本包同时是 fzf 默认的文件/目录命令，且被 lib/home-module-dependencies.nix
#   声明为 fzf 的硬依赖，禁用时 fzf 所在求值会失败。
# --- fd ---
# Modern `find` replacement; also fzf's default file/dir command.
{ pkgs, ... }:
{
  home.packages = [ pkgs.fd ];
}
