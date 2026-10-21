# just.nix —— just 命令运行器模块：justfile 的现代化 make 替代品。
# 被 default.nix 引入；toolchain-checks.nix 的 document-and-build-tools 检查
#   会执行 justfile 并验证 zsh 补全可用。
{ pkgs }:
{
  packages = [ pkgs.just ];  # 单包模块，结构与其他工具链一致以便 default.nix 统一汇总
  versions.just = pkgs.just.version;
}
