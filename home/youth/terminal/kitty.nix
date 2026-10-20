# ============================================================================
# home/youth/terminal/kitty.nix —— kitty 终端配置
# ----------------------------------------------------------------------------
# kitty 是基于 GPU 渲染的终端模拟器，滚动流畅、支持连字与图片协议。
# 系统默认终端（configuration.nix 中 TERMINAL=kitty）即为本程序。
#
# 本文件分两部分：
#   programs.kitty —— 通过 Nix 选项配置（字体、extraConfig 等）
#   extraConfig    —— 直接透传给 kitty.conf 的原生配置项
# 说明：extraConfig 中的内容会追加到生成的 kitty.conf 末尾，优先级较高。
#
# 生成的配置文件位置：~/.config/kitty/kitty.conf（由 home-manager 管理，勿手工修改）
# ============================================================================
# 形参使用 `_` 表示不需要任何 home-manager 模块参数
_: {
  programs.kitty = {
    enable = true; # 启用 kitty 终端

    # ---------------------------------------------------------------------
    # 字体
    # 说明：必须使用 Nerd Font，否则 starship / powerlevel10k 提示符中的
    #       图标字符会显示为方块或空白。
    # ---------------------------------------------------------------------
    font = {
      name = "FiraCode Nerd Font Mono"; # 等宽编程字体，含 Nerd 图标字形
      size = 14; # 字号（pt）
    };

    # ---------------------------------------------------------------------
    # 原生 kitty 配置项（逐行注释说明见下方）
    # ---------------------------------------------------------------------
    extraConfig = ''
      # 光标拖尾动画（帧数），默认关闭；需要时取消注释
      # cursor_trail 3

      # 粗体/斜体自动匹配：由 kitty 从字体族中挑选对应字重，无需单独指定
      bold_font        auto
      italic_font      auto
      bold_italic_font auto

      # 背景透明度与背景模糊（配合 Hyprland 的模糊效果观感更好）
      background_opacity 0.92
      background_blur 30
      hide_window_decorations yes   # 隐藏窗口装饰（边框由合成器绘制，避免双层标题栏）
      confirm_os_window_close 0      # 关闭窗口不弹出确认对话框（0 = 关闭该确认行为）

      # ---- 标签栏（Tab Bar）----
      tab_bar_edge bottom            # 标签栏位于底部
      tab_bar_min_tabs 1             # 仅一个标签时也显示标签栏
      tab_bar_style powerline        # 电源线风格分隔
      tab_powerline_style slanted    # 分隔符使用斜角

      # ---- 标签配色（取自 Catppuccin Mocha 调色板，与全局主题一致）----
      inactive_tab_foreground #CDD6F4  # 未激活标签文字色（Text）
      inactive_tab_background #1E1E2E  # 未激活标签背景色（Base）
      active_tab_foreground #11111B    # 激活标签文字色（Mantle）
      active_tab_background #CBA6F7    # 激活标签背景色（Mauve 强调色）
      tab_title_template " {index}: {title}{'  {}'.format(num_windows) if num_windows > 1 else \'\'}"
      active_tab_foreground #11111B
      active_tab_background #CBA6F7
      inactive_tab_foreground #CDD6F4
      # 说明：上一行 tab_title_template 用于自定义标签标题，格式为
      #       「Nerd 图标 + 序号: 标题」，当同一标签内窗口数大于 1 时追加窗口数量；
      #       其中的图标为不可见字符，请勿随意编辑。
      # 说明：上方「标签配色」区块与紧随 tab_title_template 的这三行为原配置的
      #       重复书写，实际生效的是先出现的值，保留原样以免改变现状。

      # 选区配色
      selection_foreground none      # 选区不改变文字颜色
      selection_background #585B70   # 选区背景色（Surface2）

      # 记忆窗口大小：新窗口沿用前一个窗口的尺寸
      remember_window_size yes

      # 强制从左到右渲染：避免 RTL 字符与鼠标选择方向异常
      force_ltr_rendering yes

      # 禁用连字（部分连字会破坏等宽列对齐，可按需开启）
      disable_ligature
    '';

    # 直接使用 kitty 内置的 Catppuccin Mocha 主题
    themeFile = "Catppuccin-Mocha";
  };
}
