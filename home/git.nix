# git.nix —— Git 版本控制模块（gh 凭据助手）。
# 角色：home/ 用户层软件模块；由 enable.git 开关控制（当前为 true）。
# 引用链：flake.nix → home/default.nix → 本文件。
# 数据流：凭据助手依赖 home/gh.nix 安装的 gh（lib.getExe 在构建期解析出
#   确定的 store 路径，随重建自动更新，避免手写 ~/.gitconfig 中的陈旧路径）。
# --- git ---
# Version control. The gh credential helper is declared here rather than
# hand-written into ~/.gitconfig: a literal /nix/store path to gh goes stale the
# moment gh is updated, while this is regenerated on every rebuild.
{ lib, pkgs, ... }:
{
  programs.git = {
    enable = true;
    settings.credential = {
      # ! 前缀表示 shell 命令形式的凭据助手
      "https://github.com".helper = "!${lib.getExe pkgs.gh} auth git-credential";
      "https://gist.github.com".helper = "!${lib.getExe pkgs.gh} auth git-credential";
    };
  };
}
