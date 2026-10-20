# ============================================================================
# home/youth/fcitx5/fcitx5.nix —— Fcitx5 输入法配置
# ----------------------------------------------------------------------------
# Fcitx5 是成熟的输入法框架，本配置选用 Rime（中州韵）作为核心引擎，
# 支持拼音、五笔及各类双拼方案。
#
# 输入法链路：
#   应用 -> 环境变量（QT_IM_MODULE 等）-> fcitx5 -> rime 引擎 -> 候选窗口
#
# 生成的配置文件：~/.config/fcitx5/profile、~/.config/fcitx5/config
# ============================================================================
# 模块参数：pkgs —— 包集合（用于引用各类输入法插件）；... —— 接受其它未声明的参数
{
  pkgs,
  ...
}: {
  # ------------------------------------------------------------------------
  # 启用 Fcitx5
    # 说明：NixOS 会通过 systemd 拉起 fcitx5 服务，并生成 autostart 文件；
    #       hyprland.lua 中也显式执行了 fcitx5，两者不冲突（幂等启动）。
    # ------------------------------------------------------------------------
    i18n.inputMethod = {
      type = "fcitx5"; # 指定输入法框架
      enable = true;    # 启用输入法服务
    };

    # ------------------------------------------------------------------------
    # 输入法插件
    # ------------------------------------------------------------------------
    i18n.inputMethod.fcitx5.addons = with pkgs; [
      fcitx5-rime # Rime 引擎：中州韵，支持双拼/五笔/自定义方案
      qt6Packages.fcitx5-configtool # 图形化配置工具（fcitx5-configtool）
      qt6Packages.fcitx5-chinese-addons # 中文相关插件：拼音、五笔、简繁转换等
    ];

    # 启用 Wayland 原生前端（而非 XWayland 兼容层），输入更稳定、延迟更低
    i18n.inputMethod.fcitx5.waylandFrontend = true;

    /*
     *i18n.inputMethod.fcitx5.settings.inputMethod与catppuccin.fcitx5.apply相冲突
     *因为两者都试图管理同一个配置文件
     *catppuccin.fcitx5可以导入主题配色可以使用classicui.globalSection.Theme导入主题
     *也可以禁用inputMethod，设置主题。
     */

    # ------------------------------------------------------------------------
    # 输入法列表与排序
    # 说明：定义一个名为 Default 的输入法组，包含「美式键盘（英文）」与「Rime」，
    #       并把键盘放在首位、rime 放在次位，方便用 Super+Space 快速切换。
    # ------------------------------------------------------------------------
    i18n.inputMethod.fcitx5.settings.inputMethod = {
      GroupOrder."0" = "Default"; # 只有一个输入法组
      "Groups/0" = {
        Name = "Default";                       # 组名
        "Default Layout" = "us";                # 物理键盘布局为美式
        DefaultIM = "keyboard-us";              # 默认使用纯英文键盘
      };
      "Groups/0/Items/0".Name = "keyboard-us"; # 组内第 1 项：英文
      "Groups/0/Items/1".Name = "rime";        # 组内第 2 项：Rime
    };

    # ------------------------------------------------------------------------
    # 全局选项与候选窗口主题
    # ------------------------------------------------------------------------
    i18n.inputMethod.fcitx5.settings = {
      globalOptions = {
        # ---- 已禁用的选项（保持注释）----
        # "Behavior" = {
        # 关键设置：关闭程序内预编辑，强制使用 Fcitx5 浮窗(能解决 neovide 中无法预编辑的问题)
        # "PreeditEnabledByDefault" = "False";
        # };

        # 切换输入法的快捷键：Super + Space（与桌面环境常用键位一致）
        "Hotkey/TriggerKeys" = {"0" = "Super+space";};
      };

      # 候选窗口主题：使用 catppuccin 提供的 Mocha 配色 + Mauve 强调色
      # 注意：该主题名来自 catppuccin.fcitx5 生成的配置
      addons.classicui.globalSection.Theme = "catppuccin-mocha-mauve";
    };

    # ------------------------------------------------------------------------
    # Catppuccin 配色
    # 说明：
    #   flavor = "mocha"      深色主题变体
    #   accent = "mauve"      强调色
    #   enableRounded = true  圆角候选窗口
    #   apply = false         关闭自动改写配置，避免与上面的 settings 冲突，
    #                         因此配色需手动通过 classicui 的 Theme 引用
    # ------------------------------------------------------------------------
    catppuccin.fcitx5 = {
      enable = true;
      flavor = "mocha"; # 主题变体
      accent = "mauve"; # 强调色
      enableRounded = true; # 启用圆角
      apply = false; # 自动配置
    };
}
