# ============================================================================
# home/youth/programs/tool.nix —— 命令行工具集
# ----------------------------------------------------------------------------
# 本文件集中声明两类工具：
#   A. home.packages 直接安装的命令行程序（截图、录屏、剪贴板、压缩等）
#   B. programs.<name> 声明式管理的现代 CLI 替代品（fzf、ripgrep、eza 等）
#
# 设计取向：用 Rust 实现的现代工具（fd/ripgrep/eza/bat）替代经典工具
#           （find/grep/ls/cat），并配合 fzf 组成命令行工作流。
#
# 模块参数：
#   pkgs          —— 稳定版包集合
#   pkgs-unstable —— 不稳定版包集合（由 flake 注入，用于需要新版本的软件）
#   ...           —— 接受其它未声明参数
# ============================================================================
{
  # pkgs —— 稳定版包集合
  pkgs,
  # pkgs-unstable —— 不稳定版包集合（由 flake 注入，用于需要新版本的软件）
  pkgs-unstable,
  # ... —— 接受其它未声明参数
  ...
}: {
  # ------------------------------------------------------------------------
  # A. 直接安装的命令行工具
  # ------------------------------------------------------------------------
  home.packages = with pkgs; [
    # ---- 基础小工具 ----
    tty-clock # 终端时钟（数字翻页风格）
    tree # 以树形结构展示目录
    unzip # 解压 zip
    zip # 打包 zip
    tldr # 简明命令速查（tldr <命令>）
    entr # 文件监听：文件变化时自动重跑命令

    # ---- 显示与外设 ----
    wlr-randr # Wayland 下查询/设置输出分辨率、缩放、刷新率

    # ---- 图片处理 ----
    imagemagick # 缩略图生成（供 nautilus/imv 等文件管理器显示预览）

    # ---- 截图（Wayland 原生方案）----
    grim # 截取整个屏幕的 PNG
    slurp # 在屏幕上框选区域，输出选区几何信息
    satty # 截图后的标注/裁剪/涂鸦编辑器（grim 的交互式搭档）

    # ---- 录屏 ----
    wf-recorder # 基于 wlroots 输出的屏幕/摄像头录制（见同目录 scripts/）

    # ---- 剪贴板（Wayland）----
    wl-clipboard # wl-copy / wl-paste 命令行剪贴板工具
    cliphist # 剪贴板历史管理，可配合 rofi 快速粘贴历史内容

    # ---- 远程桌面 ----
    wayvnc # Wayland VNC 服务端，供他人从局域网远程观看/操作本机

    # ---- 蓝牙 ----
    blueman # 蓝牙图形管理工具（系统服务在 configuration.nix 中启用）

    # ---- 需要较新版本的软件（取自 unstable）----
    pkgs-unstable.picgo # PicGo：图片上传图床命令行工具

    # ---- 影音处理 ----
    losslesscut-bin # LosslessCut：无损剪辑（仅剪切不重编码，体积小速度快）
  ];

  # ------------------------------------------------------------------------
  # Claude Code —— Anthropic 官方 AI 命令行助手
  # 说明：从 unstable 取包以保证版本较新。
  #       原先的 API Key 由 agenix 解密、再经 modules/systemd.nix 注入环境变量；
  #       该链路当前已停用，如需使用请自行在 shell 配置中 export，
  #       或按 flake.nix 中的说明恢复整套 agenix 配置。
  # ------------------------------------------------------------------------
  programs.claude-code = {
    enable = true;
    package = pkgs-unstable.claude-code;
  };

  # ------------------------------------------------------------------------
  # B. 声明式管理的命令行工具
  # ------------------------------------------------------------------------
  # fzf：通用模糊搜索，可作为 Ctrl+R 历史搜索与 Alt+C 文件搜索的默认实现
  programs.fzf = {
    enable = true; # 启用 fzf
    enableZshIntegration = true; # 注入 zsh 集成（提供 fzf 历史/目录跳转快捷键）

    defaultCommand = "fd --type f"; # Ctrl+R 之外，默认搜索目标为「所有文件」
    defaultOptions = [
      # 预览窗内容：目录用 eza 展示两级树，文件用 bat 带行号彩色预览
      "--preview '[ -d {} ] && eza --tree --level=2 --color=always {} || bat --color=always --style=numbers {}'"
      "--preview-window=right:60%" # 预览窗位于右侧，占 60% 宽度
    ];

    # Alt+C 切换目录时的选项：仅用 eza 预览（eza 即 exa 的后继）
    changeDirWidgetOptions = [
      "--preview '[ -d {} ] && eza --tree --level=2 --color=always {} || eza --color=always {}'"
      "--preview-window=right:40%" # 预览窗占 40% 宽度
    ];

    # Ctrl+R 历史搜索时不显示预览（命令历史本身已足够）
    historyWidgetOptions = [
      "--no-preview"
    ];
  };
  catppuccin.fzf = {
    enable = true; # 应用 Catppuccin 配色到 fzf
    flavor = "mocha"; # 深色主题
    accent = "mauve"; # 强调色（高亮/光标）
  };

  # fd：find 的现代替代，语法更简洁且默认忽略 .gitignore 中的路径
  programs.fd = {
    enable = true;
    hidden = true; # 搜索隐藏文件
    ignores = ["node_modules" "target"]; # 额外忽略目录：前端依赖与 Rust 构建产物
  };

  # ripgrep：grep 的现代替代，默认遵循 .gitignore、并行多线程
  programs.ripgrep.enable = true; # rg：文件内容搜索
  programs.ripgrep-all.enable = true; # rga：预先解包压缩文件后再搜索（docx/pdf/zip 等）

  # eza：ls 的现代替代，支持 Git 状态、树形视图与文件类型图标
  programs.eza = {
    enable = true;
    enableZshIntegration = true; # 接管 zsh 的 ls 命令
    colors = "auto"; # 跟随终端自动适配颜色
    git = true; # 显示 Git 仓库状态
    icons = "auto"; # 显示文件类型图标（需 Nerd Font）
  };

  # bat：cat 的现代替代，带语法高亮与行号（fzf 预览依赖它）
  programs.bat = {
    enable = true;
    config = {
      number = true; # 默认显示行号
      paging = "always"; # 始终使用 less 分页输出
    };
  };
  catppuccin.bat = {
    enable = true; # 应用 Catppuccin 配色（生成 bat 主题并设为默认）
    flavor = "mocha";
  };

  # jq：命令行 JSON 解析与格式化工具
  programs.jq.enable = true;

  # imv：极简图片查看器（Wayland 原生），已设为系统默认图片程序
  programs.imv.enable = true;
  catppuccin.imv = {
    enable = true; # 应用 Catppuccin 配色
    flavor = "mocha";
  };

  # yazi：终端文件管理器，支持鼠标操作与预览
  programs.yazi = {
    enable = true;
    shellWrapperName = "yy"; # 启动后自动 cd 到所选目录的包装命令名
    enableZshIntegration = true; # 注入 zsh 集成
  };

  # zoxide：智能目录跳转，用最少的按键在全盘目录间跳转（命令：z）
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true; # 注入 zsh 集成（基于 frecency 算法）
  };

  # btop：图形化系统监控（CPU/内存/磁盘/网络/进程）
  programs.btop.enable = true;
  catppuccin.btop = {
    enable = true; # 应用 Catppuccin 配色
    flavor = "mocha";
  };

  # cava：终端音频频谱可视化
  programs.cava.enable = true;
  catppuccin.cava = {
    enable = true; # 应用 Catppuccin 配色
    flavor = "mocha"; # 深色主题
    transparent = true; # 背景透明，配合终端背景使用
  };
}
