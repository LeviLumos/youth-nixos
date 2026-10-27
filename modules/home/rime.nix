# =============================================================================
#  输入法用户配置（fcitx5 + Rime）
# -----------------------------------------------------------------------------
#  ① 方案选择：dotfiles/rime/default.custom.yaml → ~/.local/share/fcitx5/rime/
#     Rime 的 default.custom.yaml 会 patch 掉雾凇自带的 default.yaml，
#     把 schema_list 切成 double_pinyin_flypy（小鹤双拼）
#  ② 输入法列表：~/.config/fcitx5/profile —— fcitx5 装好后默认是空的（只有键盘），
#     必须手动加一次才能 ctrl+space 出中文。这里自动写一份（默认 rime + 保留 us）
#     ⚠️ 只在 profile 不存在时写，之后在 configtool 里改的不会被覆盖
#  ③ 主题：dotfiles/fcitx5/theme.conf → ~/.local/share/fcitx5/themes/youth/
#     dotfiles/fcitx5/classicui.conf → ~/.config/fcitx5/conf/（Theme=youth）
#     配色跟随 vars.theme.*，字体跟随 vars.fonts.mono.*
#  ④ 词库：just rime-ice（克隆 github.com/iDvel/rime-ice 到 rime 用户目录）
# =============================================================================
{ lib, pkgs, vars, ... }:
{
  # ---- ① 默认方案 = 小鹤双拼 --------------------------------------------------
  home.file.".local/share/fcitx5/rime/default.custom.yaml".source =
    ../../dotfiles/rime/default.custom.yaml;

  # ---- ③ 主题 + 界面配置 ------------------------------------------------------
  home.file.".local/share/fcitx5/themes/youth/theme.conf".source =
    pkgs.replaceVars ../../dotfiles/fcitx5/theme.conf {
      background = vars.theme.background;
      foreground = vars.theme.foreground;
      accent = vars.theme.accent;
      fontFamily = vars.fonts.mono.family;
      fontSize = toString vars.fonts.mono.size;
    };

  home.file.".config/fcitx5/conf/classicui.conf".source =
    pkgs.replaceVars ../../dotfiles/fcitx5/classicui.conf {
      fontFamily = vars.fonts.mono.family;
      fontSize = toString vars.fonts.mono.size;
    };

  # ---- ② fcitx5 输入法列表：默认 Rime ------------------------------------------
  #  只在文件不存在时写（home.activation 每次 switch 都跑，不能无条件覆盖）
  home.activation.seedFcitx5Profile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    profile="${vars.homeDirectory}/.config/fcitx5/profile"
    if [ ! -f "$profile" ]; then
      mkdir -p "$(dirname "$profile")"
      cat > "$profile" <<'PROFILE_EOF'
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=rime

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=rime
Layout=

[GroupOrder]
0=Default
PROFILE_EOF
      echo "已写入 fcitx5 默认输入法列表（默认 Rime，ctrl+space 切换）"
    fi
  '';
}
