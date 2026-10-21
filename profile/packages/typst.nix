# typst.nix —— Typst 模块：现代化标记式排版引擎（PDF 生成）。
# 被 default.nix 引入；toolchain-checks.nix 的 document-and-build-tools 检查
#   会实际编译一个 .typ 文件并验证产出非空 PDF。
{ pkgs }:
{
  packages = [ pkgs.typst ];  # 单包模块，结构与其他工具链一致以便 default.nix 统一汇总
  versions.typst = pkgs.typst.version;
}
