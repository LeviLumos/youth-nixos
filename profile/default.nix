# profile/default.nix —— 开发工具集的“安装清单”汇总入口。
# 角色：以 { pkgs, rosPkgs } 为参数，逐个 import packages/ 下的工具链模块，
#   每个模块统一返回 { packages = [...]; versions = { ... }; } 结构：
#   packages 是要安装的派生列表，versions 是要记录的版本元数据。
# 被谁引用：
#   - profile/flake.nix 中 tools = import ./default.nix 把所有 packages/ 模块
#     打包为一个 buildEnv（packages.x86_64-linux.dev-tools），并把全部 versions
#     写成 share/koru-dev/versions.json；
#   - profile/toolchain-checks.nix 基于 bundle 做编译/运行验证；
#   - scripts/koru/profile.sh 通过 nix profile install/upgrade 安装 bundle，
#     其 status 子命令读取 versions.json 展示各工具版本。
# rosPkgs 来自 ROS overlay 自带的独立 nixpkgs 修订，仅供 ros2 模块使用。
# Explicit install inventory. Each entry owns its packages and version metadata.
{ pkgs, rosPkgs }:
{
  c-cpp-toolchain = import ./packages/c-cpp-toolchain.nix { inherit pkgs; };  # C/C++ 工具链（GCC multilib + LLVM/Clang 19）
  java-toolchain = import ./packages/java-toolchain.nix { inherit pkgs; };  # JDK 21
  just = import ./packages/just.nix { inherit pkgs; };  # just 命令运行器
  nodejs = import ./packages/nodejs.nix { inherit pkgs; };  # Node.js 22
  openmpi = import ./packages/openmpi.nix { inherit pkgs; };  # OpenMPI 并行环境
  python = import ./packages/python.nix { inherit pkgs; };  # uv + Ruff（Python 工作流）
  ros2 = import ./packages/ros2.nix { inherit rosPkgs; };  # ROS 2 Humble（使用 rosPkgs 而非 pkgs）
  rust = import ./packages/rust.nix { inherit pkgs; };  # Rust 稳定版 + 生态工具
  typst = import ./packages/typst.nix { inherit pkgs; };  # Typst 排版引擎
}
