# ============================================================================
# home/youth/programs/development/default.nix —— 开发环境子模块入口
# ----------------------------------------------------------------------------
# 由 home/youth/programs/default.nix 的 `imports = [ ./development ]` 引入。
#
# 本目录内容：
#   direnv.nix   —— 环境变量自动加载（进入目录自动执行 nix develop）
#   vscodium.nix —— VSCodium（VS Code 的开源构建版本）
#   zed.nix      —— Zed 编辑器
#   neovide.nix  —— Neovim 的 GUI 前端
#   tmux.nix     —— 终端复用器（会话持久化 + CPU 监控）
#   lazygit.nix  —— Git 终端图形界面
#   dev.nix      —— 语言工具链（Node/Python/Go/Rust/C 编译工具）
#   vim.nix      —— vim（系统救援用）与 neovim（日常主力编辑器）
#
# 另注：flake.nix 中通过 home.packages 直接引入了 CookNixvim，
#       neovim 的完整插件配置由该独立仓库提供。
# ============================================================================
{
  imports = [
    ./direnv.nix # 环境变量自动加载
    ./vscodium.nix # VSCodium
    # ./zed.nix # Zed 编辑器
    ./neovide.nix # Neovim GUI 前端
    # ./tmux.nix # 终端复用器
    ./lazygit.nix # Git 图形界面
    ./dev.nix # 语言工具链
    ./vim.nix # vim / neovim 基础配置
  ];
}
