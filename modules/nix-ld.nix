# ============================================================================
# modules/nix-ld.nix —— 让「通用 Linux 预编译二进制」能在 NixOS 上运行
# ----------------------------------------------------------------------------
# 背景：
#   NixOS 没有 FHS 目录（无 /lib、/usr/lib 等），而官方预编译二进制的 ELF
#   interpreter 字段指向 /lib64/ld-linux-x86-64.so.2。内核先去加载这个
#   加载器，找不到就报错：
#       Could not start dynamically linked executable: <程序名>
#       NixOS cannot run dynamically linked executables ...
#   常见受害者：mise 安装的 node、uvx / npm / pip 下载的原生二进制、
#   各类官方 Release 页面下载的 AppImage / CLI 工具等。
#
# 原理：
#   nix-ld 提供一个「转发型动态加载器」接管这类程序的启动，再按
#   NIX_LD_LIBRARY_PATH 从 /nix/store 查找运行所需共享库。
#
# 使用注意：
#   1. 重建后需重新登录（环境变量随登录会话注入），必要时重启；
#   2. libraries 只放「通用运行时库」，缺哪补哪，不要把应用包塞进来；
#   3. 某程序仍报缺库时，用 ldd <二进制> 看缺项，再往本列表追加；
#   4. 仅在需要运行预编译二进制时启用，它会略微放宽 Nix 的环境隔离。
# ============================================================================

# pkgs —— 包集合（用于引用提供共享库的包）；... —— 接受其它未声明的模块参数
{pkgs, ...}: {
  programs.nix-ld = {
    enable = true; # 启用 nix-ld：接管 /lib64/ld-linux-x86-64.so.2 的加载请求

    # ------------------------------------------------------------------------
    # 供预编译二进制查找的共享库集合（生成 NIX_LD_LIBRARY_PATH）
    # ------------------------------------------------------------------------
    libraries = with pkgs; [
      glibc # 基础 C 库（libm / libpthread / libdl 等）
      stdenv.cc.cc.lib # libstdc++ / libgcc_s：C++ 程序（如 node）必需
      zlib # 通用压缩库
      openssl # crypto 与 https
      icu # 国际化组件（node 的 Intl 依赖）
      curl # libcurl
      zstd # zstd 压缩（新版包管理器与 CLI 常用）
      xz # xz / lzma 压缩
      bzip2 # bzip2 压缩
      ncurses # 终端交互类程序（TUI）
    ];
  };
}
