# ============================================================================
# home/youth/programs/development/lazygit.nix —— lazygit 终端 Git 界面
# ----------------------------------------------------------------------------
# lazygit 是一个用 Go 编写的终端 Git 客户端，把 add/commit/branch/rebase/stash
# 等操作整合进一个 TUI，显著减少记忆 Git 命令的负担。
#
# 常用键位（默认）：
#   空格     暂存/取消暂存选中项
#   c        提交（随后输入信息，WIP 会被自动暂存）
#   p        推送    f 拉取    b 创建分支
#   q        退出
#
# 生成的配置文件位置：~/.config/lazygit/config.yml
# ============================================================================
# 形参使用 `_` 表示不需要任何 home-manager 模块参数
_: {
  programs.lazygit = {
    enable = true; # 安装 lazygit
    settings = {}; # 预留：可在此写入用户自定义配置（GUI 与 git 配置合并）
  };

  catppuccin.lazygit = {
    enable = true; # 应用 Catppuccin 配色
    accent = "mauve"; # 强调色
    flavor = "mocha"; # 深色主题
  };
}
