# ============================================================================
# home/youth/programs/default.nix —— 应用程序子模块入口
# ----------------------------------------------------------------------------
# 由 home/youth/default.nix 的 `imports = [ ./programs ]` 引入。
#
# 本目录按用途划分：
#   fastfetch.nix      —— 系统信息速览
#   tool.nix           —— 命令行工具（fzf、ripgrep、截图、录屏、剪贴板等）
#   app.nix            —— 图形应用（浏览器、播放器、通讯与笔记软件）
#   development/       —— 开发环境（编辑器、Git 工具、tmux、direnv 等）
# ============================================================================
{
  imports = [
    ./fastfetch.nix # 系统信息速览配置
    ./tool.nix # 命令行工具集
    ./app.nix # 图形应用集
    ./development # 开发环境子目录（含 default.nix）
  ];
}
