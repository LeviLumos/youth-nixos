# zoxide.nix —— zoxide（智能 cd 历史跳转）模块。
# 角色：home/ 用户层软件模块，由 enable.zoxide 开关控制。
# 引用链：flake.nix → home/default.nix → 本文件。
# 数据流：enableZshIntegration 让 home-manager 在 zsh 配置中注入 z/zi
#   命令；刻意不设 --cmd cd，普通 cd 语义不变。
# --- zoxide ---
# Smarter `cd` history. Replaces oh-my-zsh's `z` plugin (removed in zsh.nix);
# provides z/zi. `--cmd cd` is intentionally NOT set: plain `cd` keeps its
# normal meaning, use `z <fragment>` to jump.
_: {
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
