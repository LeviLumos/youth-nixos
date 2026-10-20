# ============================================================================
# home/youth/hyprland/wlogout/wlogout.nix —— 电源/会话菜单
# ----------------------------------------------------------------------------
# wlogout 提供一个简洁的图形界面，用于集中执行：锁屏、注销、重启、关机。
# 本配置在 Nix 侧自定义了按钮布局与样式（不复用 wlogout 自带主题）。
#
# 调用方式：
#   wlogout            打开菜单
#   wlogout --no-off   隐藏「关机」选项
#   wlogout --poweroff 直接执行关机（跳过界面）
#
# 依赖：注销/重启/关机均通过 systemd 命令执行，因此需要 polkit 授权
#       （系统级 services.polkit-gnome 已在 configuration.nix 中启用）。
#
# 样式说明（programs.wlogout.style）：
#   采用 GTK CSS。窗口默认带圆角背景，这里通过 background-image/box-shadow
#   置空以去掉装饰；按钮图标通过 background-image 引用 wlogout 包内的 PNG。
# ============================================================================
{
  # config 用于读取 home.username（决定注销哪个用户）
  config,
  # pkgs 用于引用 wlogout 包内的图标文件路径
  pkgs,
  # ... 表示接受其它未声明的模块参数
  ...
}: {
  home.packages = with pkgs; [
    wlogout # 电源/会话菜单程序本体
  ];

  programs.wlogout.enable = true; # 注册 wlogout 命令

  # ------------------------------------------------------------------------
  # 按钮布局
  # 说明：keybind 为界面内的字母快捷键；text 为按钮下方显示的文字。
  # ------------------------------------------------------------------------
  programs.wlogout.layout = [
    # 锁屏（调用 hyprlock，配置见 ../hyprlock/hyprlock.nix）
    {
      label = "lock";
      action = "hyprlock"; # 启动 hyprlock
      text = "锁屏"; # 按钮文字
      keybind = "l"; # 快捷键 l
    }
    # 注销当前用户会话
    {
      label = "logout";
      # 使用 loginctl terminate-user $USER 结束该用户的全部会话
      action = "loginctl terminate-user ${config.home.username}";
      text = "注销"; # 按钮文字
      keybind = "e"; # 快捷键 e
    }
    # 重启系统
    {
      label = "reboot";
      action = "systemctl reboot"; # 通过 systemd 重启
      text = "重启"; # 按钮文字
      keybind = "r"; # 快捷键 r
    }
    # 关闭系统
    {
      label = "shutdown";
      action = "systemctl poweroff"; # 通过 systemd 关机
      text = "关机"; # 按钮文字
      keybind = "s"; # 快捷键 s
    }
  ];

  # ------------------------------------------------------------------------
  # GTK 样式
  # ------------------------------------------------------------------------
  programs.wlogout.style = ''
    /* 去掉 GTK 默认的窗口背景与阴影 */
    * {
      background-image: none;
      box-shadow: none;
    }

    /* 窗口本体：半透明渐变背景，字号置 0（仅在悬停时放大显示） */
    window {
      background: linear-gradient(145deg, rgba(15, 15, 105, 0.3), rgba(6, 6, 6, 0.4));
      font-size: 0px;
    }

    /* ===== 按钮基础样式：默认透明、居中显示图标 ===== */
    button {
      background-color: transparent;
      background-repeat: no-repeat;
      background-position: center;
      background-size: 40%;
      padding: 0px 10px;
      border: 2px solid transparent;
      transition: all 300ms ease-out;          /* 悬停动画时长与曲线 */
      animation-timing-function: steps(24);    /* 动画按 24 步执行，产生阶梯式放大效果 */
    }

    /* ===== 按钮悬停/按下的放大与描边效果 ===== */
    button:active,
    button:hover {
      font-size: 30px;                          /* 悬停时显示文字（平时为 0） */
      color: white;
      padding: 0px 40px;
      margin: 10px 0px 10px 0px;
      border-radius: 25px;
      border-color: rgba(255, 255, 255, 0.6);
      box-shadow: inset 0 0 10px rgba(255, 255, 255, 0.5);
      background-color: transparent;
      background-repeat: no-repeat;
      background-position: center;
      background-size: 45%;                    /* 悬停时图标略放大 */
      transition: all 0.3s ease-out;
      animation-timing-function: steps(24);
    }

    /* ===== 各按钮的边距与图标 ===== */
    #lock {
      margin: 40px 20px 40px 20px;
      padding: 0px 10px;
      /* 图标取自 wlogout 包内资源（由 Nix 注入实际 store 路径）*/
      background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
    }

    #reboot {
      margin: 40px 20px 40px 20px;
      background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
    }

    #logout {
      margin: 40px 20px 40px 20px;
      background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
    }

    #shutdown {
      margin: 40px 20px 40px 20px;
      background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
    }
  '';
}
