# nodejs.nix —— Node.js 工具链模块：Node.js 22（LTS，自带 npm/npx/corepack）。
# 被 default.nix 引入；toolchain-checks.nix 的 nodejs 检查校验主版本为 v22。
# 关联：home/codex.nix 用 npm 安装 Codex CLI，需要本工具链提供 npm。
{ pkgs }:
# 编译期断言：主版本必须为 22，锁定 LTS 大版本
assert pkgs.lib.assertMsg (
  pkgs.lib.versions.major pkgs.nodejs_22.version == "22"
) "The Node.js profile requires Node.js 22";
{
  packages = [ pkgs.nodejs_22 ];
  versions.nodejs = pkgs.nodejs_22.version;
}
