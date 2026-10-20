# ============================================================================
# home/youth/hyprland/waybar/waybar.nix —— Waybar 状态栏配置
# ----------------------------------------------------------------------------
# Waybar 是 Wayland 常用的状态栏，基于 GTK，以 JSON 风格配置描述布局。
#
# 本配置的主界面结构（mainBar）：
#   左侧 group/container  -> Logo + 工作区切换器 + 分隔图标
#   中间                  -> Cava 音频频谱可视化
#   右侧                  -> 时钟 + 录屏指示 + group/main + 系统托盘
#                          group/main 内含：电源模式 / 音量 / CPU / 蓝牙
#
# 配套文件：
#   style.css                     —— 外观样式（背景、圆角、悬停效果）
#   toggle-power-profile.sh       —— 电源模式查询与切换（被 custom/powerprofile 调用）
#   ../scripts/wf-recorder-status.sh —— 录屏状态检测（由 scripts/default.nix 安装）
#
# 图标说明：配置中 format 与 format-icons 使用的是 Nerd Font 私有区图标字符
#          （在编辑器中显示为不可见或方块），依赖 configuration.nix 中安装的
#          nerd-fonts，编辑时请勿误删或替换为普通字符。
#
# 交互约定：
#   左键 = 主要动作（打开面板/切换状态）
#   右键 = 次要动作（静音、蓝牙开关等）
#   滚轮 = 增减（音量、工作区切换）
# ============================================================================
# 模块参数：pkgs —— 包集合（用于引用状态栏依赖的图形工具）；... —— 接受其它未声明的参数
{pkgs, ...}: {
    # ------------------------------------------------------------------------
    # 状态栏依赖的 GUI 工具
    # ------------------------------------------------------------------------
    home.packages = with pkgs; [
      pavucontrol # 图形化音量控制面板（点击音量图标时弹出）
      networkmanagerapplet # NetworkManager 托盘图标（有线/无线网络菜单）
    ];

    programs.waybar = {
      enable = true; # 安装并启用 Waybar

      # ---------------------------------------------------------------------
      # 主状态栏
      # ---------------------------------------------------------------------
      settings = {
        mainBar = {
          # ---- 整体外观 ----
          layer = "top"; # 置于最上层，不被普通窗口遮挡
          position = "top"; # 停靠屏幕顶部
          height = 35; # 状态栏高度（像素）

          # ---- 布局模块（数组顺序即显示顺序）----
          modules-left = ["group/container"];
          modules-center = ["cava"];
          modules-right = ["clock" "custom/wf-recorder" "group/main" "tray"];

          # ---- 左侧分组：Logo + 工作区列表 + 分隔图标 ----
          "group/container" = {
            orientation = "inherit"; # 继承外层方向（横向排列）
            modules = ["custom/logo" "hyprland/workspaces" "custom/icon"];
          };

          # ---- 右侧分组：电源模式 + 音量 + CPU + 蓝牙 ----
          "group/main" = {
            orientation = "inherit"; # 横向排列
            modules = ["custom/powerprofile" "pulseaudio" "cpu" "bluetooth"];
          };

          # -------------------------------------------------------------------
          # Cava：音频频谱可视化（居中模块）
          # 说明：播放音乐/视频时显示柱状频谱，静音时自动隐藏。
          # -------------------------------------------------------------------
          "cava" = {
            framerate = 30; # 刷新帧率
            autosens = 1; # 自动灵敏度调节，避免声音轻时无反应
            bars = 14; # 频谱柱数量
            lower_cutoff_freq = 50; # 忽略 50Hz 以下（几乎无听感的超低频）
            higher_cutoff_freq = 10000; # 忽略 10kHz 以上
            hide_on_silence = true; # 静音时隐藏频谱，不占用视觉空间
            method = "pulse"; # 取音协议：PulseAudio（对应 PipeWire 的 pulse 兼容层）
            source = "auto"; # 自动跟随默认输出设备
            stereo = false; # 单声道显示（更省横向空间）
            bar_delimiter = 0; # 柱子之间不留空隙（更连贯的频谱效果）
            monstercat = false; # 关闭 Monstercat 圆角柱形风格
            waves = false; # 关闭波形显示模式
            noise_reduction = 0.6; # 降噪强度，减少底噪抖动
            input_delay = 4; # 输入延迟帧数（过高会导致频谱反应迟钝）
            sleep_timer = 1; # 无音频输入时的休眠秒数，降低 CPU 占用
            format-icons = ["▁" "▂" "▂▃" "▄" "▅" "▆" "▇█" "█"]; # 音量档位对应的柱高字符
            # 备选：柱间留空格的宽间隔版本
            # format-icons = [ " " "▁" "▃" "▄" "▅" "▆" "▇" "█" ];
            actions = {
              on-click-right = "mode"; # 右键在「频谱 / 波形」两种模式间切换
            };
          };

          # ===================================================================
          # 各模块具体配置
          # ===================================================================

          # ---- Logo（纯图标，仅作视觉标识）----
          "custom/logo" = {
          format = "";
          tooltip = false; # Logo 无悬浮提示
          on-scroll-up = ""; # 滚轮向上无动作
          on-scroll-down = ""; # 滚轮向下无动作
        };

        # ---- Hyprland 工作区切换器 ----
        "hyprland/workspaces" = {
          active-only = false; # 显示全部工作区（而非只显示可见的）
          all-outputs = false; # 只显示当前显示器上的工作区
          show-special = true; # 显示 special 工作区（Hyprland 的隐藏/特殊区）
          special-visible-only = false; # special 工作区始终可见
          disable-scroll = true; # 禁用工作区名称自身的滚动（改由整块区域滚轮切换）
          warp-on-scroll = false; # 滚动切换时鼠标指针不跟随移动
          format = "{name}"; # 显示工作区名称
          persistent-workspaces = {"*" = 5;}; # 所有显示器都保留编号 1-5 的空工作区
          on-scroll-up = "hyprctl dispatch workspace e+1"; # 滚轮上：切到下一个工作区
          on-scroll-down = "hyprctl dispatch workspace e-1"; # 滚轮下：切到上一个工作区
        };

        # ---- 分隔图标（视觉分隔用）----
        "custom/icon" = {
          format = "󰋇";
          tooltip = false;
          on-scroll-up = "";
          on-scroll-down = "";
        };

        # ---- CPU 使用率 ----
        cpu = {
          format = "{icon} {usage}%"; # 显示「图标 + 使用率百分比」
          interval = 10; # 每 10 秒刷新一次（降低轮询开销）
          tooltip = false; # 不显示每核详细数据的悬浮提示
          format-icons = [""];
          on-scroll-up = "";
          on-scroll-down = "";
        };

        # ---- 系统托盘：显示后台运行程序的图标（输入法、代理、网盘等）----
        tray = {
          icon-size = 20; # 托盘图标尺寸（像素）
          spacing = 10; # 托盘图标之间的间距（像素）
        };

        # ---- 蓝牙状态 ----
        bluetooth = {
          format = "󰂯 {status}";
          format-connected = " {device_alias}"; # 已连接时改为显示设备名称
          on-scroll-up = ""; # 滚轮无动作
          on-scroll-down = "";
          on-click = "blueman-manager"; # 左键：打开 blueman 图形管理界面
          on-click-right = "rfkill toggle bluetooth"; # 右键：一键开关蓝牙
          tooltip = true; # 显示已连接设备详情
        };

        # ---- 时钟 ----
        clock = {
          timezone = "Asia/Shanghai"; # 时区（与 configuration.nix 的 time.timeZone 一致）
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"; # 悬浮显示年月与日历
          format-alt = "{:%Y-%m-%d}"; # 鼠标悬停时切换为年月日格式
        };

        # ---- 录屏状态指示器（点击打开截图/录屏菜单）----
        "custom/wf-recorder" = {
          format = "{text}"; # 显示脚本返回的 text 字段
          interval = 2; # 每 2 秒轮询一次脚本
          exec = "~/.config/waybar/scripts/wf-recorder-status.sh"; # 录屏状态检测脚本
          return-type = "json"; # 脚本输出为 JSON（须包含 text 字段）
          on-click = "~/.config/hypr/scripts/capture.sh"; # 左键：打开截图/录屏菜单
          hide-empty-text = true; # text 为空时隐藏模块（未录屏时不占位）
          tooltip = true; # 显示悬浮提示
          on-scroll-up = ""; # 滚轮无动作
          on-scroll-down = "";
        };

        # ---- 电源模式切换器（对接 power-profiles-daemon）----
        "custom/powerprofile" = {
          tooltip = true; # 悬浮显示当前模式名称
          exec = "~/.config/waybar/scripts/toggle-power-profile.sh get"; # 查询当前模式
          return-type = "json"; # 脚本输出为 JSON
          on-click = "~/.config/waybar/scripts/toggle-power-profile.sh toggle"; # 左键：切换到下一个模式
          interval = 1; # 每秒刷新，切换后图标立即更新
          on-scroll-up = ""; # 滚轮无动作
          on-scroll-down = "";
        };

        # ---- 音量控制（对接 PipeWire 的 wpctl 命令）----
        pulseaudio = {
          format = "{icon} {volume}%"; # 正常状态：图标 + 音量百分比
          format-muted = "{format_source}"; # 静音时：仅显示静音图标
          format-source = "󰕿";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            default = ["󰕿" "󰖀" "󰕾"];
          };
          on-click = "pavucontrol"; # 左键：打开图形化音量面板
          on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"; # 滚轮上：音量 +5%
          on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"; # 滚轮下：音量 -5%
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; # 右键：切换静音
        };
      };
    };
  };

  # ------------------------------------------------------------------------
  # 状态栏样式（背景、圆角、悬停效果等）
  # ------------------------------------------------------------------------
  home.file.".config/waybar/style.css".source = ./style.css;

  # ------------------------------------------------------------------------
  # 电源模式切换脚本（供上方 custom/powerprofile 模块调用）
  # ------------------------------------------------------------------------
  home.file.".config/waybar/scripts/toggle-power-profile.sh" = {
    source = ./toggle-power-profile.sh; # 脚本来源
    executable = true; # 设置可执行权限（否则 waybar 无法调用）
  };
}
