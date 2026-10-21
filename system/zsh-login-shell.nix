# zsh-login-shell.nix —— 系统层登录 shell 解释器（zsh）。
# 作用：让 /etc/passwd 中用户 shell 指向 zsh，并安装基础 zsh 运行时，
#   保证无 home-manager generation 生效时（如全新 TTY 登录）也有可用 shell。
# 导入：由 system/default.nix 显式导入（机器层）。
# 机制：programs.zsh.enable 注册 zsh 到环境 + 设置用户默认 shell + 写入
#   /etc/zshenv、/etc/zshrc 全局骨架。
# 依赖：交互层配置（p10k、插件、别名）在 home/zsh.nix（home-manager 层）。
# --- shell ---
# Login shell interpreter (system side). Enabled at the machine layer, not in
# the host file, so every device shares it; the interactive config (p10k,
# plugins, aliases) is the user layer in home/zsh.nix. Keeping the
# interpreter here means a TTY login has a working shell with no home-manager
# generation active.
{
  programs.zsh.enable = true;
}
