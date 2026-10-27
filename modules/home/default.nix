# =============================================================================
#  home-manager 主入口（用户级）
# -----------------------------------------------------------------------------
#  约定：所有用户级 dotfile 统一用 home.file 管理（不用 programs.* 生成），
#        这样配置文件就是 dotfiles/ 下真实可读的文件，便于直接用编辑器改。
#        占位符 @xxx@ 由 pkgs.replaceVars 在构建期替换成 vars.nix 里的值。
# =============================================================================
{ vars, ... }:
{
  imports = [
    ./packages.nix       # 用户级软件包（开发环境 / 应用）
    ./niri.nix           # home.file → ~/.config/niri/config.kdl
    ./kitty.nix          # home.file → ~/.config/kitty/kitty.conf
    ./zsh.nix            # home.file → ~/.zshrc
    ./desktop.nix        # 通知(mako) / 空闲(swayidle) / 托盘(tray-tui)
    ./vscodium.nix       # VSCodium 的 settings/keybindings + 插件安装脚本
    ./rime.nix           # Rime 默认方案 = 雾凇双拼（词库用 just rime-ice 装）
  ];

  home = {
    username = vars.username;
    homeDirectory = vars.homeDirectory;
    stateVersion = vars.stateVersion;
  };

  # 让 home-manager 安装的包出现在 PATH 里（默认已开，显式声明便于理解）
  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables = {
    EDITOR = vars.shell.editor;
    VISUAL = vars.shell.editor;

    # 若需要中文输入法（fcitx5），打开下面几行并在系统包里装 fcitx5 与输入法：
    # GTK_IM_MODULE = "fcitx";
    # QT_IM_MODULE  = "fcitx";
    # XMODIFIERS    = "@im=fcitx";
  };
}
