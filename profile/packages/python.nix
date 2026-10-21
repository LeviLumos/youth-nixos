# python.nix —— Python 工作流模块：uv（包/解释器/虚拟环境管理）+ Ruff
# （lint+format）。
# 被 default.nix 引入；toolchain-checks.nix 的 python 检查验证 ruff 可用、
#   uv 可用 nix 解释器建 venv 并运行脚本。
# 设计取舍：解释器与依赖交给 uv 按项目管理，仓库只锁 uv/ruff 二进制本身；
#   注意锁 uv 并不能锁各项目内下载的 Python 版本。
# uv manages project interpreters/dependencies; Ruff remains a Nix-built binary.
# Locking uv does not lock the Python versions it downloads for projects.
{ pkgs }:
{
  packages = [
    pkgs.uv
    pkgs.ruff
    # 设计取舍：解释器与依赖交给 uv 按项目管理，仓库只锁 uv/ruff 二进制本身；
    # 注意锁 uv 并不能锁各项目内下载的 Python 版本
  ];
  versions = {
    uv = pkgs.uv.version;
    ruff = pkgs.ruff.version;
  };
}
