# rust.nix —— Rust 工具链模块：精确版本的 stable 工具链 + 生态辅助工具。
# rust-bin 由 rust-overlay 提供（见 flake.nix inputs），可钉到任意小版本。
# 被 default.nix 引入；profile/flake.nix 内联的 rust-version 检查会校验 rustc
#   精确版本、llvm-profdata 存在，并离线跑一次 cargo llvm-cov。
{ pkgs }:
let
  version = "1.98.1";  # 手动钉版本：保证所有机器上的 rustc 完全一致，不被通道更新漂移
  rust = pkgs.rust-bin.stable.${version}.default.override {
    extensions = [ "llvm-tools-preview" ];  # 额外组件：llvm-tools 提供 llvm-profdata 等，供 llvm-cov 覆盖率使用
  };
in
# 编译期断言：解析到的 rust 版本必须等于钉住的版本
assert pkgs.lib.assertMsg (
  rust.version == version
) "Rust profile requires ${version}, got ${rust.version}";
{
  packages = [
    rust
    pkgs.cargo-deny  # 依赖许可证/漏洞/来源审计
    pkgs.cargo-llvm-cov  # 基于 LLVM 的覆盖率
    pkgs.cocogitto  # Conventional Commits 与版本发布工具
    pkgs.pre-commit  # git 钩子管理框架
  ];
  # 版本元数据：rustc 记录钉住的版本字符串，写入 versions.json
  versions = {
    rustc = version;
    cargo-deny = pkgs.cargo-deny.version;
    cargo-llvm-cov = pkgs.cargo-llvm-cov.version;
    cocogitto = pkgs.cocogitto.version;
    pre-commit = pkgs.pre-commit.version;
  };
}
