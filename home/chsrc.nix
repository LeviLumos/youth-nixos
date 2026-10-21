# chsrc.nix —— 镜像源切换工具 chsrc 模块 + zsh 包装函数。
# 角色：home/ 用户层软件模块；由 enable.chsrc 开关控制（当前为 true）。
# 引用链：flake.nix → home/default.nix → 本文件。
# 数据流：向 home/zsh.nix 的 initContent（mkAfter 排序）注入同名 zsh 函数，
#   把 -en 标志重排到子命令之后（v0.2.7 的参数位置限制，见行内注释）。
# --- chsrc ---
# Mirror swapper. The CLI defaults to Chinese output; force English via `-en`.
# v0.2.7 shifts the dish position by one per option, so options must sit
# between the subcommand and the dish (`chsrc set -en uv`). A plain alias
# expands to `chsrc -en set uv`, where the leading -en is parsed as the
# command and rejected with "Unknown command `-en`", so a function re-injects
# the flag after the subcommand instead.
{ lib, pkgs, ... }:
{
  home.packages = [ pkgs.chsrc ];

  # mkAfter 保证函数定义在 zsh 初始化末尾，避免被后续覆盖
  programs.zsh.initContent = lib.mkAfter ''
    chsrc() {
      # 无参时透传（打印帮助）
      if (( $# == 0 )); then
        command chsrc
      else
        # 把 -en 插到子命令之后；''${@:2} 是 Nix 转义写法，生成脚本中即 bash 的全部剩余参数
        command chsrc "$1" -en "''${@:2}"
      fi
    }
  '';
}
