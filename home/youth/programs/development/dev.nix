# ============================================================================
# home/youth/programs/development/dev.nix —— 语言与编译工具链
# ----------------------------------------------------------------------------
# 直接安装常用语言的运行时、版本管理器与构建工具。
# 说明：此处安装的是「全局可用」的版本，适合随手编译与运行脚本；
#       若某个项目需要特定版本，推荐用 flake.nix 定义 devShell，
#       再配合 direnv 自动切换（见 direnv.nix）。
#
# 注意：多数语言工具只包含运行时与包管理器，不含 LSP（语言服务器）；
#       LSP 通常在各自的 nvim 配置中单独声明。
# ============================================================================

# 模块参数：pkgs —— 包集合（用于引用具体版本的包）；... —— 接受其它未声明的参数
{pkgs, ...}: {
  home.packages = with pkgs; [
    # ---- 文档排版 ----
    typst # Typst：Rust 编写的现代标记排版系统，可编译 PDF

    # ---- JavaScript / TypeScript 生态 ----
    nodejs_24 # Node.js 24 运行时（含 npm）
    pnpm_10 # pnpm 10：快速、节省磁盘的包管理器

    # ---- Rust 生态 ----
    # 说明：此处安装 nixpkgs 提供的 Rust 工具链（非 rustup 管理器），
    #       便于离线与统一版本；如需 rustup 自行管理工具链需另外配置。
    # rustc # Rust 编译器
    # cargo # Rust 包管理器与构建工具
    # rustfmt # Rust 代码格式化工具

    # ---- Go ----
    # go # Go 语言工具链

    # ---- Python ----
    python314 # Python 3.14 解释器
    uv # uv：极速的 Python 包与项目管理器（可替代 pip/venv/poetry）

    # ---- C / C++ 编译与调试 ----
    gcc15 # GCC 15 编译器（C/C++/Fortran）
    gdb # GNU 调试器
    pkg-config # 库编译时的依赖探测工具（autotools 生态必备）
    cmake # 跨平台构建系统生成器
    gnumake # Make 构建工具
    ninja # Ninja：比 make 更快的构建执行器
    mise
  ];

  # config about git
  programs.git = {
    userName = "LeviLumos";
    userEmail = "v22to.me@gmail.com";
  };
}