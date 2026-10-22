# =============================================================================
#  kitty 配置：home.file 管理 ~/.config/kitty/kitty.conf
# -----------------------------------------------------------------------------
#  源文件：dotfiles/kitty/kitty.conf，占位符 @xxx@ 由 replaceVars 替换
#  详细说明见 doc/kitty.md
# =============================================================================
{ pkgs, vars, ... }:
{
  home.file.".config/kitty/kitty.conf".source =
    pkgs.replaceVars ../../dotfiles/kitty/kitty.conf {
      fontFamily = vars.fonts.mono.family;
      fontSize = toString vars.fonts.mono.size;
      accent = vars.theme.accent;
      background = vars.theme.background;
      foreground = vars.theme.foreground;
      cursor = vars.theme.cursor;
    };
}
