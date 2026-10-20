# ============================================================================
# home/youth/programs/development/tmux.nix —— tmux 终端复用器配置
# ----------------------------------------------------------------------------
# tmux 用于会话持久化：终端关闭后进程继续运行，重新打开可恢复现场。
# 本配置与 tmux-resurrect / tmux-continuum 插件配合，实现「自动保存并恢复
# 布局与运行中的程序」。
#
# 核心配置说明：
#   prefix           前缀键。改为 C-a 后可释放 C-b（无需鼠标即可拷贝粘贴）
#   keyMode = "vi"   复制模式使用 vi 风格按键
#   escapeTime = 0   消除 Vim 中 Esc 键的响应延迟
#
# 常用会话操作：
#   Ctrl+a d        分离会话（程序继续运行）
#   tmux attach      重新接入最近会话
#   Ctrl+a r        手动重载配置
#
# 生成的配置文件位置：~/.config/tmux/tmux.conf
# ============================================================================
# 模块参数：pkgs —— 包集合（用于引用 tmux 插件）；... —— 接受其它未声明的参数
{pkgs, ...}: {
  programs.tmux = {
    enable = true; # 安装 tmux

    # ------------------------------------------------------------------------
    # 基础行为
    # ------------------------------------------------------------------------
    prefix = "C-a"; # 前缀键 Ctrl+a
    mouse = true; # 启用鼠标：可直接拖拽分屏边界、滚动查看历史
    keyMode = "vi"; # 复制模式使用 vi 风格按键
    baseIndex = 1; # 窗口与分屏编号从 1 开始（更符合直觉）
    clock24 = true; # 状态栏使用 24 小时制
    reverseSplit = false; # 新分屏不使用「反向」布局（保证新窗口出现在右侧/下方）
    escapeTime = 0; # 消除 Neovim/Vim 中 Esc 键的约 0.5s 延迟
    historyLimit = 50000; # 增大回滚历史条数

    # ------------------------------------------------------------------------
    # 插件
    # ------------------------------------------------------------------------
    plugins = with pkgs; [
      # 在状态栏显示 CPU、内存等实时负载
      tmuxPlugins.cpu

      # tmux-resurrect：把会话布局与运行中的进程保存为文件
      {
        plugin = tmuxPlugins.resurrect;
        # 使用 'session' 策略（而非默认的 'window'），可连同每个窗口内的
        # 面板一起保存，粒度更细但恢复耗时略长
        extraConfig = "set -g @resurrect-strategy-nvim 'session'";
      }

      # tmux-continuum：定时自动保存 / 开机自动恢复
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'          # 启动 tmux 时自动恢复上次会话
          set -g @continuum-save-interval '60'   # 每 60 分钟自动保存一次
        '';
      }
    ];

    # ------------------------------------------------------------------------
    # 其它透传配置
    # ------------------------------------------------------------------------
    extraConfig = "
      set -g status-left-length 50      # 左侧状态栏长度（容纳插件与时间）
      set -g set-clipboard on           # 与系统剪贴板互通（需 tmux-yank 之类的配置配合）
      set -g automatic-rename off       # 关闭窗口名自动跟随命令，避免窗口名频繁变化
    ";
  };

  # --------------------------------------------------------------------------
  # Catppuccin 配色
  # --------------------------------------------------------------------------
  catppuccin.tmux = {
    enable = true; # 应用 Catppuccin 配色到状态栏
    flavor = "mocha"; # 深色主题
  };
}
