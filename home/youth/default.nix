# ============================================================================
# home/youth/default.nix —— 用户 youth 的 home-manager 配置入口
# ----------------------------------------------------------------------------
# 由 flake.nix 中 home-manager.users.youth.imports 引入。
# 本文件负责「组装」：导入各功能子目录（shell、终端、桌面环境、输入法、
# 启动器、壁纸、音乐等），并声明跨模块的全局设置。
#
# 模块参数：
#   config —— home-manager 配置结果，可读取其它模块已合并后的值
#   pkgs   —— 包集合
#   lib    —— home-manager / nixpkgs 标准库（mkIf、dag 等）
#   ...    —— 接受其它未声明参数（flake 注入的 inputs、pkgs-unstable 等）
# ============================================================================
{
  # config —— home-manager 配置结果，可读取其它模块已合并后的值
  config,
  # pkgs —— 包集合
  pkgs,
  # lib —— home-manager / nixpkgs 标准库（mkIf、dag 等）
  lib,
  # ... —— 接受其它未声明参数（flake 注入的 inputs、pkgs-unstable 等）
  ...
}: {
  # --------------------------------------------------------------------------
  # 1. 子模块聚合
  # --------------------------------------------------------------------------
  imports = [
    ./shell # zsh + 提示符 + 别名
    ./programs # 各类应用程序与开发工具
    ./terminal # kitty / alacritty 终端
    ./niri # Niri 滚动平铺桌面环境
    ./hyprland # Hyprland 桌面环境
    ./noctalia # Noctalia 状态栏与菜单
    ./fcitx5 # 中文输入法
    ./rofi # 应用启动器与截图工具
    ./wallpaper # 动态壁纸
    ./music # 音乐播放器与 mpd
  ];

  # --------------------------------------------------------------------------
  # 2. 直接安装的命令行包
  # 说明：home.packages 装入用户 profile，路径加入用户 PATH
  # --------------------------------------------------------------------------
  home.packages = with pkgs; [
    xwayland-satellite # XWayland 替代实现（Wayland 下运行 X11 程序）
    libnotify # notify-send 命令，用于命令行发送桌面通知
  ];

  # --------------------------------------------------------------------------
  # 3. 激活钩子：自动创建截图目录
  # 说明：home.activation 定义在 home-manager 重建时执行的一次性动作。
  #   dag.entryAfter ["writeBoundary"] 表示排在文件写入阶段之后执行，
  #   避免与 Nix 管理的文件写入冲突。
  # --------------------------------------------------------------------------
  home.activation.ensureScreenshotDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.home.homeDirectory}/screenshot"
  '';

  # --------------------------------------------------------------------------
  # 4. 权限与桌面服务
  # --------------------------------------------------------------------------
  # polkit 图形认证代理：挂载磁盘、修改网络等操作时弹窗输入密码授权
  services.polkit-gnome.enable = true;

  services.swaync.enable = true; # 通知中心
  services.swayidle.enable = true; # 空闲管理：超时锁屏、挂起

  catppuccin.swaync = {
    enable = true; # 应用 Catppuccin 配色到通知中心
    flavor = "mocha"; # 配色风格（与全局主题保持一致）
  };

  # ---- 备选通知器：mako（若想换成更简洁的样式，取消以下注释）----
  # services.mako.enable = true;
  # catppuccin.mako = {
  #   enable = true;
  #   accent = "mauve";
  #   flavor = "mocha";
  # };

  # --------------------------------------------------------------------------
  # 5. 默认应用关联（XDG MIME 类型）
  # 说明：双击文件或点击链接时，决定交给哪个程序处理。
  # --------------------------------------------------------------------------
  xdg.mimeApps.enable = true; # 启用 home-manager 管理的 MIME 数据库
  xdg.mimeApps.defaultApplications = {
    "image/png" = "imv.desktop"; # 图片 -> imv（极简图片查看器）
    "image/jpeg" = "imv.desktop"; # JPG -> imv
    "image/gif" = "imv.desktop"; # GIF -> imv
    "inode/directory" = "org.kde.dolphin.desktop"; # 文件夹 -> Dolphin 文件管理器
    "text/html" = "google-chrome.desktop"; # HTML -> Chrome
    "x-scheme-handler/http" = "google-chrome.desktop"; # http 链接
    "x-scheme-handler/https" = "google-chrome.desktop"; # https 链接
    "x-scheme-handler/clash" = "clash-verge.desktop"; # clash 协议 -> Clash Verge
  };

  # --------------------------------------------------------------------------
  # 6. 鼠标指针
  # --------------------------------------------------------------------------
  home.pointerCursor = {
    enable = true; # 声明式管理光标主题
    package = pkgs.adwaita-icon-theme; # 光标文件来自 Adwaita 图标主题
    name = "Adwaita"; # 光标主题名
    size = 24; # 基准尺寸（像素）
  };

  # --------------------------------------------------------------------------
  # 7. 会话环境变量（用户级）
  # 说明：与 configuration.nix 中的 environment.sessionVariables 作用范围不同，
  #       这里是「当前用户的所有进程」都能读到的变量。
  # --------------------------------------------------------------------------
  home.sessionVariables = {
    EDITOR = "nvim"; # 默认编辑器（git commit、crontab 等会调用）
    VISUAL = "nvim"; # 完整版编辑器变量
    PATH = "$HOME/.local/bin:$PATH"; # 把用户自行安装的程序目录提到最前
    LANG = "en_US.UTF-8"; # 系统主语言：英文（程序界面语言）
    LC_CTYPE = "zh_CN.UTF-8"; # 字符集：中文，保证 UTF-8 中文正常显示
    LC_MESSAGES = "en_US.UTF-8"; # 程序提示信息语言：英文
  };

  # --------------------------------------------------------------------------
  # 8. 状态版本
  # 说明：home-manager 用它判断是否需要迁移旧配置，请勿随意修改。
  # --------------------------------------------------------------------------
  home.stateVersion = "25.11";
  # home.enableNixpkgsReleaseCheck = false; # 需要关闭版本检查提示时取消注释
}