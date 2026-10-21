# fastfetch.nix —— fastfetch 系统信息卡片模块（Koru Fern 主题）。
# 角色：home/ 用户层软件模块；由 enable.fastfetch 开关控制（当前为 true）。
# 引用链：flake.nix → home/default.nix → 本文件；theme 经 specialArgs 传入。
# 依赖/数据流：logo 取自 ../assets/fastfetch/koru-logo.png（写入
#   ~/.config/fastfetch/）；keyColor/outputColor 全部来自 system/theme.nix；
#   66 列分隔线与 CPU 行、卡片分隔的列宽对齐（见行内注释）。
# 消费方：home/niri.nix 的启动面板（kitty + fastfetch）与 zsh 别名。
# --- fastfetch ---
# Koru Fern system card for the half-width startup dashboard. Kitty renders the
# supplied transparent PNG, while the system data stays in a vertical card.
{ theme, ... }:
let
  # Use the supplied artwork directly, preserving its colours and alpha channel.
  logo-png = ../assets/fastfetch/koru-logo.png;

  # Match the full 66-column width used by the CPU line and card separators.
  # genList 生成 66 个减号，与 CPU 行及卡片分隔线的 66 列宽度一致
  separatorDashes = builtins.concatStringsSep "" (builtins.genList (_: "-") 66);
in
{
  xdg.configFile."fastfetch/koru-logo.png".source = logo-png;

  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        # "kitty" silently renders no image on kitty 0.48 (fastfetch 2.67);
        # "kitty-direct" embeds the pixels in the escape and works.
        type = "kitty-direct";
        source = "${logo-png}";
        # The supplied PNG has a transparent square canvas.
        # Set only the width so fastfetch derives the height from the square
        # source instead of stretching it into a fixed rectangle.
        width = 30;
        position = "top";
        padding.left = 19;
        padding.bottom = 0;
      };

      display = {
        separator = "  ";
        # 键名列宽 12，统一左列对齐
        key.width = 12;
      };

      modules = [
        {
          type = "title";
          format = "{#3}{user-name}{#} @ {#2}{host-name}{#}";
          keyColor = theme.accent-yellow;
          outputColor = theme.fg;
        }
        {
          type = "custom";
          format = "{#2}${separatorDashes}{#}";
        }
        {
          type = "os";
          key = "OS";
          keyColor = theme.accent;
          outputColor = theme.fg;
        }
        {
          type = "kernel";
          key = "Kernel";
          keyColor = theme.accent;
          outputColor = theme.fg;
        }
        {
          type = "uptime";
          key = "Uptime";
          keyColor = theme.accent;
          outputColor = theme.fg;
        }
        {
          type = "packages";
          key = "Packages";
          keyColor = theme.accent-yellow;
          outputColor = theme.fg;
        }
        {
          type = "shell";
          key = "Shell";
          keyColor = theme.accent-yellow;
          outputColor = theme.fg;
        }
        {
          type = "brightness";
          key = "Brightness";
          keyColor = theme.accent-yellow;
          outputColor = theme.fg;
        }
        {
          type = "cpu";
          key = "CPU";
          keyColor = theme.ansi.cyan;
          outputColor = theme.fg;
        }
        {
          type = "memory";
          key = "Memory";
          keyColor = theme.ansi.cyan;
          outputColor = theme.fg;
        }
        {
          type = "disk";
          key = "Disk";
          keyColor = theme.ansi.cyan;
          outputColor = theme.fg;
        }
        {
          type = "battery";
          key = "Battery";
          keyColor = theme.accent-yellow;
          outputColor = theme.fg;
        }
        {
          type = "localip";
          key = "Network";
          keyColor = theme.ansi.cyan;
          outputColor = theme.fg;
        }
        {
          type = "custom";
          format = "{#2}${separatorDashes}{#}";
        }
        {
          # 结尾色块圆点行，展示当前调色板
          type = "colors";
          symbol = "circle";
          keyColor = theme.muted;
        }
      ];
    };
  };
}
