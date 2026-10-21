# bat.nix —— cat 的增强替代（语法高亮 + git 变更标记）模块。
# 角色：home/ 用户层软件模块；由 enable.bat 开关控制（当前为 true）。
# 引用链：flake.nix → home/default.nix → 本文件；theme 经 specialArgs 传入
#   （本文件未直接用 theme，靠 ansi 主题间接继承终端的 Koru Fern 调色板）。
# 数据流：cat/catp 等 alias 定义在 home/zsh.nix；颜色随终端 ANSI 色与
#   system/theme.nix 自动同步，本模块自身零主题数据。
# --- bat ---
# cat with syntax highlighting + git changes. `theme = "ansi"` reuses the
# terminal's 16 ANSI colors, which are already the Koru Fern palette, so it
# stays in sync with system/theme.nix for free. Aliases (cat/catp) live in zsh.nix.
_: {
  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
      # 行号 + git 变更标记 + 文件头信息
      style = "numbers,changes,header";
    };
  };
}
