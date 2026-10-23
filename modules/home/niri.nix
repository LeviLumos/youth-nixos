# =============================================================================
#  niri 配置：home.file 管理 ~/.config/niri/config.kdl
# -----------------------------------------------------------------------------
#  源文件：dotfiles/niri/config.kdl（真实 KDL 文件，占位符 @xxx@ 在构建期替换）
#  变量来源：vars.nix（niri.* / theme.* / desktop.*）
# =============================================================================
{ pkgs, vars, ... }:
{
  home.file.".config/niri/config.kdl".source =
    pkgs.replaceVars ../../dotfiles/niri/config.kdl {
      # 注意：下面每个键都必须对应文件里出现的 @键@，多一个少一个都会构建失败
      gaps = toString vars.niri.gaps;
      borderWidth = toString vars.niri.borderWidth;
      cornerRadius = toString vars.niri.cornerRadius;
      activeBorder = vars.theme.activeBorder;
      inactiveBorder = vars.theme.inactiveBorder;
      urgentBorder = vars.theme.urgentBorder;
      layout = vars.xkb.layout;
      xkbOptions = vars.xkb.options;
      terminal = vars.niri.terminal;
      launcher = vars.niri.launcher;
      wallpaperTool = vars.desktop.wallpaperTool;
      wallpaper = vars.desktop.wallpaper;
      locker = vars.desktop.locker;
      tray = vars.desktop.tray;
    };
}
