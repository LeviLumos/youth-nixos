# =============================================================================
#  vars.nix —— 全局唯一变量来源（single source of truth）
# -----------------------------------------------------------------------------
#  想改成自己的配置，绝大多数情况下【只改这一个文件】就够了。
#  所有 NixOS 模块、home-manager 模块、以及 dotfiles 里的占位符（@xxx@）
#  都从这里取值，改一处即可全局生效。
#
#  注意：这里【不能】引用 pkgs（vars.nix 在 flake.nix 里先于 pkgs 求值），
#        包名/变体名一律用字符串，在具体模块里再用 pkgs.${...} 解析。
# =============================================================================

let
  # ---- 身份 -----------------------------------------------------------------
  username = "youth";
in
{
  inherit username;

  # ---- 主机 -----------------------------------------------------------------
  hostname = "ego";                       # networking.hostName / 输出名 / hosts 目录名
  system = "x86_64-linux";                # aarch64-linux 请改这里
  stateVersion = "26.05";                 # 不要随意改！改了会失去兼容性保护

  # ---- 用户 -----------------------------------------------------------------
  userDescription = "youth";              # users.users.<name>.description
  homeDirectory = "/home/${username}";    # 家目录
  initialPassword = "youth";              # 首次安装的明文密码，装完请改：passwd
  userGroups = [
    "wheel"                               # sudo
    "networkmanager"                      # 网络管理
    "audio"
    "video"
    "input"
    "lp"                                  # 打印
    "scanner"
  ];

  # ---- 区域 / 语言 -----------------------------------------------------------
  timezone = "Asia/Shanghai";
  locale = "en_US.UTF-8";                 # 想全中文改成 "zh_CN.UTF-8"
  supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "zh_CN.UTF-8/UTF-8"
  ];
  consoleKeymap = "us";
  xkb = {
    layout = "us";                        # 输入法由 fcitx5(Rime) 接管，键盘布局保持 us
    variant = "";

    # XKB options（逗号分隔，可叠加）。常用：
    #   "caps:super"     CapsLock → Super/Mod（本配置默认，键位里的 Mod 就是它）
    #   "caps:escape"    CapsLock → Esc（vim 用户常用）
    #   "caps:ctrl_modifier"  CapsLock → Ctrl
    #   ""               恢复 CapsLock 原样
    #   "altwin:swap_alt_win"  交换 Alt 与 Super
    options = "caps:super";
  };

  # ---- 键盘重映射（keyd：evdev 层，XKB 做不到的事交给它）------------------------
  keyboard = {
    # 按住 Alt + h/j/k/l → 方向键 左/下/上/右（文本光标移动）
    #  轻点 Alt 仍然是 Alt（菜单、应用里的 Alt 组合照旧）
    altHjklArrows = true;                 # false = 不启用 keyd
    altHjklArrowsKey = "leftalt";         # 触发键："leftalt"（左 Alt）/ "rightalt"（右 Alt）
  };

  # ---- 引导 -----------------------------------------------------------------
  boot = {
    loader = "uefi";                      # "uefi" = systemd-boot（UEFI） | "grub"（BIOS/MBR）
    efi = true;                           # 是否 UEFI
  };

  # ---- 显卡 -----------------------------------------------------------------
  graphics = {
    # "amd"（核显/独显 amdgpu）| "intel" | "nvidia" | "none"
    gpu = "amd";
  };

  # ---- 硬件外设开关 ----------------------------------------------------------
  hardware = {
    audio = true;                         # 音频（PipeWire + WirePlumber）
    bluetooth = true;                     # 蓝牙（hardware.bluetooth + blueman）
    printing = true;                      # 打印（CUPS + 打印机自动发现）
    scanning = true;                      # 扫描（SANE）
  };

  # ---- 容器（podman）----------------------------------------------------------
  #  rootless（不用 sudo）+ 兼容 docker 命令；btop 等监控工具在用户级包里
  virtualisation = {
    podman = {
      enable = true;                      # false = 完全不装容器运行时
      dockerCompat = true;                # 提供 docker 命令（指向 podman 的兼容层）
      autoPrune = true;                   # 每周清理悬空镜像 / 停止的容器
    };
  };

  # ---- 电源 / 休眠 -----------------------------------------------------------
  power = {
    enable = true;                        # power-profiles-daemon + upower + 节能
    cpuFreqGovernor = null;               # "powersave"（省电）/ "performance"（性能）/ null=默认

    # systemd-logind：合盖、电源键行为
    # 可选值：ignore / poweroff / halt / suspend / hibernate / hybrid-sleep / lock
    lidSwitch = "suspend";                # 用电池时合盖
    lidSwitchExternalPower = "ignore";    # 接电源时合盖
    powerKey = "suspend";                 # 短按电源键

    # 空闲后自动挂起 / 休眠（由 swayidle 触发，0 = 关闭）
    suspendAfter = 0;                     # 例如 1800（空闲 30 分钟挂起）
    hibernateAfter = 0;                   # 例如 3600；⚠️ 休眠需要 swap ≥ 内存，见 doc
  };

  # ---- Nix / 源 --------------------------------------------------------------
  # 国内源：中科大二进制缓存；cache.nixos.org 作为兜底
  nixSubstituters = [
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
  ];

  # ---- Nix 垃圾回收（每周自动）------------------------------------------------
  nixGc = {
    enable = true;                        # false = 不自动回收（只能手动 nix-collect-garbage）
    dates = "weekly";                     # systemd 定时器：weekly / daily / "Sun 04:00" …
    deleteOlderThan = "7d";               # 保留最近 7 天的世代（想更保守就写 "30d"）
    persistent = true;                    # 关机错过了，下次开机补跑
  };

  # ---- Nix store 去重（每周自动硬链接相同文件）---------------------------------
  nixOptimise = {
    enable = true;
    dates = "weekly";
    persistent = true;
  };

  # ---- 主题（颜色）-----------------------------------------------------------
  # 需求：活动窗口用「淡鹅黄」包围边框
  theme = {
    activeBorder = "#F2E3A8";             # 淡鹅黄：活动窗口边框（niri border.active-color）
    inactiveBorder = "#3C3C3C";           # 非活动窗口边框
    urgentBorder = "#C97B5A";             # 需要注意的窗口
    accent = "#F2E3A8";                   # 主题强调色（mako/tray-tui/kitty 共用）
    background = "#1A1A17";
    foreground = "#E8E6D9";
    cursor = "#F2E3A8";
  };

  # ---- 桌面组件（状态栏 / 壁纸 / 锁屏 / 通知 / 托盘）---------------------------
  desktop = {
    wallpaperTool = "swaybg";                       # 设置壁纸的工具
    wallpaperDir = "Pictures/wallpapers";           # 壁纸池（dotfiles/wallpapers/ 部署到这里）
    rotateWallpaper = true;                         # true = 定时随机轮换壁纸（systemd timer）
    rotateInterval = "hourly";                      # 轮换频率（OnCalendar）：hourly / daily / "00 12 * * *"…
    locker = "swaylock";                            # 锁屏（super+alt+l）
    tray = "tray-tui";                              # 终端里的系统托盘（super+shift+t）

    # 空闲行为（swayidle，单位：秒，0 = 关闭该项）
    lockAfter = 300;                                # 5 分钟无操作 → 自动锁屏
    screenOffAfter = 600;                           # 10 分钟无操作 → 关闭显示器
  };

  # ---- 输入法 -------------------------------------------------------------------
  #  fcitx5 + Rime（中州韵）：nixpkgs 自带、走二进制缓存，构建不碰 GitHub。
  #  默认方案 = 雾凇双拼，词库第一次用 `just rime-ice` 装（见 doc/系统需求.md 第九节）
  inputMethod = {
    enable = true;                       # 输入法总开关
    framework = "fcitx5";                # NixOS 官方方案目前只接了 fcitx5

    # 输入法外观主题（写进 ~/.config/fcitx5/conf/classicui.conf 的 Theme=）
    #   "youth"   —— 自建主题：配色跟随 vars.theme.*（默认，见 dotfiles/fcitx5/theme.conf）
    #   "default" —— fcitx5 内置浅色主题
    #   "dark"    —— fcitx5 内置深色主题（若该版本没带，会自动回退 default）
    # ⚠️ 改完要 just switch（部署配置）+ just ime-restart（fcitx5 重新加载）才生效
    theme = "youth";
  };

  # ---- niri ------------------------------------------------------------------
  niri = {
    gaps = 3;                             # 窗口间隙 3px（需求）
    borderWidth = 3;                      # 边框宽度（逻辑像素）
    cornerRadius = 0;                     # 无圆角（需求）
    terminal = "kitty";                   # super+t 启动的终端
    launcher = "fuzzel";                  # super+space 启动的应用启动器
    autoLogin = true;                     # true = 开机经 greetd+tuigreet 免密直进 niri
  };

  # ---- 字体 ------------------------------------------------------------------
  fonts = {
    mono = {
      package = "maple-mono";             # pkgs.maple-mono（nixpkgs 内置 Maple Mono）
      variant = "Normal-NF-CN";           # 可选：Normal-NF-CN / Normal-CN / NF-CN / CN ...
      family = "MapleMonoNormal NF CN";   # kitty/fontconfig 用的字体族名（见 doc/kitty.md 校验方法）
      size = 13.0;                        # kitty / mako 字号
    };
  };

  # ---- Shell / 终端 ----------------------------------------------------------
  shell = {
    bin = "zsh";
    editor = "vim";
  };

  # ---- 开发环境版本 -----------------------------------------------------------
  dev = {
    python = "python314";                 # 需求：python314
    nodejs = "nodejs_24";                 # 需求：nodejs24；npm/npx 由 nodejs 自带（当前为 npm 11）
  };

  # ---- 仓库自身（仅用于 .zshrc 里的快捷别名）-----------------------------------
  repoDir = "youth-nixos";                # 仓库克隆后的目录名，用于 alias rebuild
}
