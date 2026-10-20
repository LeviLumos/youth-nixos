# ============================================================================
# home/youth/programs/fastfetch.nix —— 系统信息速览（fastfetch）
# ----------------------------------------------------------------------------
# fastfetch 用于替代 neofetch，在终端快速展示系统概况，对应别名 `ff`（见 zsh.nix）。
# 本文件完全采用 JSON 风格配置（fastfetch v2.9+ 支持），配置项可通过
# 下方 $schema 指向的 JSON Schema 在编辑器中获得自动补全。
#
# 结构说明：
#   logo       —— 左侧 Logo 的排版（padding.top = 1 表示顶部空一行）
#   display    —— 全局显示行为（separator = " " 表示字段与内容之间用一个空格分隔）
#   modules    —— 按顺序输出的信息条目，每个条目的 type 决定取什么数据
#
# modules 常见 type 速查（本文件用到的）：
#   title        自定义标题行（format 中 {user-name} {host-name} 为占位符）
#   os           发行版名称
#   kernel       内核版本
#   packages     已安装的包数量
#   uptime       已开机时长
#   localip      本机局域网 IP（compact = true 表示紧凑显示）
#   locale      当前语言与区域
#   shell        当前使用的 Shell
#   terminal     当前终端模拟器
#   terminalfont 终端所用字体
#   lm           桌面环境（注意：实际应为窗口管理器，此处沿用原配置写法）
#   de           桌面环境
#   wm           窗口管理器
#   host         主机型号
#   cpu          CPU 型号（format 中 {1} 为名称、{7} 为频率）
#   gpu          GPU 型号（{1} {2} {3} 为型号 / 显存 / 驱动）
#   disk         磁盘占用
#   memory       内存占用
#   display      显示器分辨率与刷新率（{1}x{2} 为分辨率，{3} 为刷新率）
#   sound        声卡信息
#   colors       终端调色板预览
#   "break"      插入一个空行（用于分区隔）
#
# 注意：keys 与 symbols 中包含 Nerd Font 图标字符，编辑时请勿误删。
# 配色：系统信息蓝色、Shell 会话黄色、硬件信息绿色，通过 keyColor 指定。
# 生成的配置文件位置：~/.config/fastfetch/config.jsonc
# ============================================================================
# 形参使用 `_` 表示不需要任何 home-manager 模块参数
_: {
  programs.fastfetch = {
    enable = true; # 启用 fastfetch

    # ---------------------------------------------------------------------
    # fastfetch 本体设置（JSON 风格）
    # ---------------------------------------------------------------------
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
      logo = {
        padding = {
          top = 1;
        };
      };

      display = {
        separator = " ";
      };

      modules = [
        {
          type = "title";
          key = "╭─";
          format = "{user-name}@{host-name}";
          keyColor = "blue";
        }
        {
          type = "os";
          key = "├─";
          keyColor = "blue";
        }
        {
          type = "kernel";
          key = "├─";
          keyColor = "blue";
        }
        {
          type = "packages";
          key = "├─󰏖";
          keyColor = "blue";
        }
        {
          type = "uptime";
          key = "├─󰅐";
          keyColor = "blue";
        }
        {
          type = "localip";
          key = "├─󰩟";
          compact = true;
          keyColor = "blue";
        }
        {
          type = "locale";
          key = "╰─";
          keyColor = "blue";
        }
        # ---- 分区一结束：系统基本信息 ----
        "break"

        # ---- 分区二开始：会话与桌面环境 ----
        {
          type = "shell";
          key = "╭─";
          keyColor = "yellow";
        }
        {
          type = "terminal";
          key = "├─";
          keyColor = "yellow";
        }
        {
          type = "terminalfont";
          key = "├─";
          keyColor = "yellow";
        }
        {
          type = "lm";
          key = "├─󰧨";
          keyColor = "yellow";
        }
        {
          type = "de";
          key = "├─";
          keyColor = "yellow";
        }
        {
          type = "wm";
          key = "╰─";
          keyColor = "yellow";
        }
        # ---- 分区二结束：会话与桌面环境 ----
        "break"

        # ---- 分区三开始：硬件信息 ----
        {
          type = "host";
          key = "╭─󰌢";
          keyColor = "green";
        }
        {
          type = "cpu";
          key = "├─󰻠";
          format = "{1} @{7}";
          keyColor = "green";
        }
        {
          type = "gpu";
          key = "├─󰍛";
          format = "{1} {2} {3}";
          keyColor = "green";
        }
        {
          type = "disk";
          key = "├─";
          keyColor = "green";
        }
        {
          type = "memory";
          key = "├─󰑭";
          keyColor = "green";
        }
        {
          type = "display";
          key = "├─󰍹";
          format = "{1}x{2} @{3}Hz {6}";
          keyColor = "green";
        }
        {
          type = "sound";
          key = "╰─";
          keyColor = "green";
        }
        {
          type = "colors"; # 调色板预览
          paddingLeft = 10; # 与左侧文字对齐的缩进
          symbol = "circle"; # 使用圆形色块展示颜色
        }
      ];
    };
  };
}
