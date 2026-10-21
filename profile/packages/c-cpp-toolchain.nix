# c-cpp-toolchain.nix —— C/C++ 工具链模块：GCC(multilib) + LLVM/Clang 19 全家桶。
# 场景：编译原理课程（需要 LLVM/Clang/opt 管线）与 32 位实验（需要 gcc_multi
#   的 multilib）。
# 被 default.nix 以 import ./c-cpp-toolchain.nix { inherit pkgs; } 引入，
#   返回 { packages; versions; }，进入 dev-tools bundle 与 versions.json。
# LLVM 19 for CS323 and GCC multilib for CS315's 32-bit labs.
{ pkgs }:
let
  llvm = pkgs.llvmPackages_19;  # 固定使用 LLVM 19 系列包集
in
# 编译期断言：Clang 主版本必须是 19，防止 nixpkgs 升级后悄悄变版本
assert pkgs.lib.assertMsg (
  # 版本元数据：写入 versions.json，供 koru profile status 展示
  pkgs.lib.versions.major llvm.clang.version == "19"
) "The C/C++ profile requires LLVM/Clang 19";
{
  packages = with pkgs; [
    # Both GCC and Clang provide cc/c++; retain GCC as the default.
    (lib.hiPrio gcc_multi)  # GCC 与 Clang 都提供 cc/c++，用 hiPrio 让 GCC 在 PATH 冲突时胜出
    gnumake  # 构建工具
    cmake  # 构建系统
    ninja
    pkg-config  # 依赖发现
    ccache  # 编译缓存
    gdb  # 调试器
    valgrind  # 内存分析
    mold  # 快速链接器
    flex  # 词法分析生成器
    bison  # 语法分析生成器
    llvm.clang
    llvm.clang-tools  # 含 clangd、clang-format 等语言服务与格式化工具
    llvm.llvm
    llvm.lld  # LLVM 自带链接器
  ];
  versions = {
    gcc = pkgs.gcc_multi.version;
    clang = llvm.clang.version;
    llvm = llvm.llvm.version;
    cmake = pkgs.cmake.version;
    ninja = pkgs.ninja.version;
    gdb = pkgs.gdb.version;
  };
}
