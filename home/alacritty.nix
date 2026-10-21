# alacritty.nix —— Alacritty 终端模拟器模块。
# 角色：home/ 用户层软件模块；由 home/modules-enables.nix 的 enable.alacritty
#   控制（当前为 false，默认不安装）。
# 引用链：flake.nix → home/default.nix（自动发现并 imports）→ 本文件；
#   theme/username 经 flake.nix 的 specialArgs 传入。
# 数据流：全部字体与 16 色 ANSI 调色板取自 system/theme.nix（经 specialArgs
#   注入的 theme），改一处主题即整体换肤；Super+J/K/L 键位转换出的
#   Meta-j/k/l 与 home/zsh.nix 中绑定的 fzf 组件配合。
# --- alacritty ---
# Terminal emulator. All colors/fonts come from the global theme
# (system/theme.nix), so the whole palette changes from a single place.
{ theme, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = theme.font;
        };
        bold = {
          family = theme.font;
        };
        italic = {
          family = theme.font;
        };
        size = theme.font-size;
      };

      window = {
        padding = {
          # 左右/上下内边距 15px，视觉留白
          x = 15;
          y = 15;
        };
        dynamic_title = true;
      };

      scrolling = {
        # 10000 行回滚历史；滚轮倍率 3 行/格
        history = 10000;
        multiplier = 3;
      };

      mouse.hide_when_typing = true;

      # Win (Super) never reaches the shell on its own, so translate
      # Win+J/K/L into ESC j/k/l (Meta-j/k/l) here; zsh binds those to the fzf
      # widgets (see home/zsh.nix). `chars` with \uXXXX is expanded by
      # home-manager's normalizeAlacrittyEscapes into a real escape byte.
      keyboard.bindings = [
        {
          key = "J";
          mods = "Super";
          chars = "\\u001bj";
        }
        {
          key = "K";
          mods = "Super";
          chars = "\\u001bk";
        }
        {
          key = "L";
          mods = "Super";
          chars = "\\u001bl";
        }
      ];

      # Selecting text copies it to the clipboard immediately (Wayland wl-copy).
      selection.save_to_clipboard = true;

      # Beam cursor: matches the fern accent, easier to spot than a block.
      cursor.style = {
        shape = "Beam";
        blinking = "On";
      };

      # 以下色值全部取自 theme，无本地硬编码色值
      colors = {
        primary = {
          background = theme.bg;
          foreground = theme.fg;
        };
        cursor = {
          text = theme.cursor;
          cursor = theme.accent;
        };
        selection = {
          text = theme.cursor;
          background = theme.accent-bg;
        };
        normal = {
          black = theme.ansi.black;
          red = theme.ansi.red;
          green = theme.ansi.green;
          yellow = theme.ansi.yellow;
          blue = theme.ansi.blue;
          magenta = theme.ansi.magenta;
          cyan = theme.ansi.cyan;
          white = theme.ansi.white;
        };
        bright = {
          black = theme.ansi-bright.black;
          red = theme.ansi-bright.red;
          green = theme.ansi-bright.green;
          yellow = theme.ansi-bright.yellow;
          blue = theme.ansi-bright.blue;
          magenta = theme.ansi-bright.magenta;
          cyan = theme.ansi-bright.cyan;
          white = theme.ansi-bright.white;
        };
      };
    };
  };
}
