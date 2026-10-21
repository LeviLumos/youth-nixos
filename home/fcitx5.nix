# fcitx5.nix —— 输入法 fcitx5 用户配置模块（Rime + Koru Fern 主题）。
# 角色：home/ 用户层软件模块；由 enable.fcitx5 开关控制（当前为 true）。
# 引用链：flake.nix → home/default.nix → 本文件；theme 经 specialArgs 传入。
# 依赖/数据流：
#   - fcitx5 本体与 rime-ice 方案由系统层 system/fcitx5-rime.nix 安装，
#     本文件只写用户层配置（profile / default.custom.yaml / classicui.conf
#     / custom 主题）；
#   - 主题背景 panel.svg 经 rsvg-convert 构建期渲染为 panel.png，
#     颜色取自 system/theme.nix；字体与全局 theme.font 一致。
# --- fcitx5 ---
# Input method user config: custom Koru Fern theme (generated from the
# global theme), Rime (rime-ice) input method, Maple Mono font.
{ pkgs, theme, ... }:
let
  # Panel: dark surface with a subdued fern border. Warning colors remain
  # reserved for actual warnings rather than decorative chrome.
  panel-svg = pkgs.writeText "panel.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 80 80">
      <rect x="3" y="3" width="74" height="74" rx="12" ry="12" fill="${theme.bg}"/>
      <rect x="3" y="3" width="74" height="74" rx="12" ry="12" fill="none" stroke="${theme.accent-yellow}" stroke-width="2"/>
    </svg>
  '';

  # Render the SVG to PNG once at build time.
  panel-png = pkgs.runCommand "panel.png" {
    buildInputs = [ pkgs.librsvg ];
  } "rsvg-convert -w 80 -h 80 ${panel-svg} -o $out";
in
{
  # profile 固定输入法组：us 键盘 + rime，默认输入法 rime
  xdg.configFile."fcitx5/profile".text = ''
    [Groups/0]
    # Group Name
    Name=Default
    # Layout
    Default Layout=us
    # Default Input Method
    DefaultIM=rime

    [Groups/0/Items/0]
    # Name
    Name=keyboard-us
    # Layout
    Layout=

    [Groups/0/Items/1]
    # Name
    Name=rime
    # Layout
    Layout=

    [GroupOrder]
    0=Default
  '';

  # Rime only needs the user layer: the scheme ships in the system-side
  # fcitx5-rime wrapper (rime-ice), so this activates it and keeps the
  # 7-candidate page the old pinyin engine used.
  xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      __include: rime_ice_suggestion:/
      menu/page_size: 7
      ascii_composer/switch_key/Shift_L: commit_code
      ascii_composer/switch_key/Shift_R: commit_code
  '';

  # Framework-level input-method switching (normally Ctrl+Space) commits the
  # raw Latin composition instead of the previewed Chinese candidate.
  xdg.configFile."fcitx5/conf/rime.conf".text = ''
    SwitchInputMethodBehavior=CommitRawInput
  '';

  xdg.configFile."fcitx5/conf/classicui.conf".text = ''
    Theme=custom
    Font=${theme.font} ${toString theme.font-size}
    Vertical Candidate List=False
  '';

  # Theme files (fonts/colors follow the global theme).
  xdg.dataFile."fcitx5/themes/custom/theme.conf".text = ''
    [Metadata]
    Name=Koru Fern
    Version=1
    Author=koru
    Description=Dark fern theme with a subdued border

    [InputPanel]
    NormalColor=${theme.fg}
    # Keep the selected candidate readable through text color only; the
    # transparent highlight removes the selection box/background.
    HighlightCandidateColor=${theme.accent-yellow}
    HighlightColor=${theme.accent-yellow}
    HighlightBackgroundColor=#00000000
    FullWidthHighlight=False

    [InputPanel/Background]
    Image=panel.png
    Color=#00000000
    BorderColor=#ffffff00
    BorderWidth=0

    [InputPanel/Background/Margin]
    Left=18
    Right=18
    Top=18
    Bottom=18

    [InputPanel/Highlight]
    Image=
    Color=#00000000
    BorderColor=#ffffff00
    BorderWidth=0

    [InputPanel/Highlight/Margin]
    Left=8
    Right=8
    Top=6
    Bottom=6

    [InputPanel/ContentMargin]
    Left=8
    Right=8
    Top=6
    Bottom=6

    [InputPanel/TextMargin]
    Left=6
    Right=6
    Top=4
    Bottom=4

    [InputPanel/PrevPage]
    Image=

    [InputPanel/NextPage]
    Image=

    [InputPanel/ShadowMargin]
    Left=0
    Right=0
    Top=0
    Bottom=0
  '';

  xdg.dataFile."fcitx5/themes/custom/panel.png" = {
    source = panel-png;
  };
}
