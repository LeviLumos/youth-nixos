# ============================================================================
# home/youth/programs/development/direnv.nix —— 环境变量自动加载
# ----------------------------------------------------------------------------
# direnv 在「进入/离开目录」时自动加载与卸载环境变量，是 NixOS 开发工作流的
# 核心工具之一。
#
# 工作方式：
#   1. 进入带 .envrc 的目录时，执行 `nix-direnv`（即 nix develop 的轻量封装）；
#      若 .envrc 中只是 `use flake` / `layout nix`，direnv 会自动加载该 flake
#      的 devShell，随后 `nix develop` 会在该目录下变得多余。
#   2. 离开目录时自动还原原有环境，避免污染全局。
#
# 生成的配置文件：~/.config/direnv/direnvrc
# 手动授权某个目录：允许时选择「y」，会写入 ~/.local/share/direnv/allow
# ============================================================================
# 形参使用 `_` 表示不需要任何 home-manager 模块参数
_: {
  programs.direnv = {
    enable = true; # 安装 direnv
    nix-direnv.enable = true; # 集成 Nix：执行 .envrc 中的 nix 指令
    enableBashIntegration = true; # 注入 bash 集成钩子
    enableZshIntegration = true; # 注入 zsh 集成钩子
  };
}
