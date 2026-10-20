# ============================================================================
# configuration.nix —— 系统级（NixOS）主配置
# ----------------------------------------------------------------------------
# 本文件负责定义整台机器的全局行为：包、用户、引导、网络、字体、桌面环境、
# 音频、显卡驱动等。所有自定义改动集中在此处或 modules/ 目录中。
#
# 运行环境由 flake.nix 组装，模块参数（inputs、pkgs-unstable）会由 flake 注入。
# ============================================================================
{
  # lib —— NixOS 模块标准库（mkDefault / mkForce / mkIf 等选项构造器）
  lib,
  # pkgs —— 当前系统的包集合
  pkgs,
  # ... —— 其余未显式声明的参数（例如 flake 注入的 inputs）
  ...
}: {
  imports = [
    # 由 nixos-install / nixos-generate-config 自动生成的硬件描述（磁盘、分区等）
    ./hardware-configuration.nix
    # 本仓库自定义模块目录（默认导入 modules/default.nix）
    ./modules
  ];

  # ==========================================================================
  # 一、Nix 基础设置
  # ==========================================================================

  # 允许这两个用户使用 nix 命令而无需交互式确认（wheel 用于 sudo，youth 是主用户）
  nix.settings.trusted-users = ["root" "youth"];

  # 允许安装非自由（proprietary）软件，如 Steam、Chrome 等
  nixpkgs.config.allowUnfree = true;

  # 启用 Nix 2.0 之后的命令行语法（nix build/install）与 Flakes 支持，
  # 这是使用 flake.nix 的前提
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # ==========================================================================
  # 二、系统级软件包
  # 说明：这里放的是「所有用户」都能用、且不属于某个桌面环境管理的命令行工具。
  #       GUI 应用与个人软件建议放在 home/youth/programs/ 下由 home-manager 管理。
  # ==========================================================================
  environment.systemPackages = with pkgs; [
    wineWow64Packages.stable # 32 位 Windows 运行环境（跑 32 位 exe）
    winetricks # 一键为 wine 前缀安装运行库与字体
    google-chrome # 浏览器
    pulseaudio # 兼容层音频守护进程（实际发声由 PipeWire 提供）
    pciutils # lspci 命令，用于排查硬件/驱动问题
    ffmpeg # 音视频转码、录屏剪辑
    libva # VA-API 视频加速接口库
    libva-utils # vainfo 等调试 VA-API 的工具
    power-profiles-daemon # 电源模式守护（节能/平衡/性能）
    vim # 最小编辑器，保证救援时可用
    git # 版本控制
    curl # HTTP 客户端
    wget # HTTP 下载工具
    bluez # 蓝牙协议栈
    cachix # 推送本地构建结果到 Cachix 缓存服务
  ];

  # ==========================================================================
  # 三、桌面娱乐与 Shell
  # ==========================================================================
  # programs.steam.enable = true; # 开启 Steam（依赖 32 位支持）
  # programs.steam.fontPackages = with pkgs; [source-han-sans]; # 为 Steam 游戏补齐中文字体，避免方块字
  programs.zsh.enable = true; # 系统默认 Shell 使用 zsh（用户 shell 在下方单独指定）

  # ==========================================================================
  # 四、会话环境变量
  # 说明：这些变量被写入 /etc/profile 与所有登录会话，供 GUI 程序读取。
  #       桌面环境中的环境变量请放 home/youth/default.nix 的 home.sessionVariables，
  #       两者作用域不同：这里是系统级，这里是用户级。
  # ==========================================================================
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # 强制 Qt 使用 Wayland 平台插件（KDE/Qt 应用原生 Wayland 渲染）
    TERMINAL = "kitty"; # 默认终端模拟器

    # ---- Fcitx5 输入法相关的 Qt/X11 环境变量 ----
    # GTK_IM_MODULE 保持注释：原生 GTK4 应用（Hyprland 生态）自带输入法支持，
    # 反而设置它会导致部分 GTK 程序（如 rofi / gtk 主题）出现光标异常。
    # QT_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx"; # Qt5/Qt6 应用输入法框架
    QT5_IM_MODULE = "fcitx"; # 兼容旧版 Qt5 应用
    XMODIFIERS = "@im=fcitx"; # XWayland 应用（X11 程序）加载 fcitx 的通用约定
  };

  # ==========================================================================
  # 五、敏感信息与密钥管理（Agenix）【已禁用】
  # 说明：./secrets/*.age 为 age 加密文件，仓库中只存密文，
  #       解密所需的私钥路径在此声明，密文内容通过环境变量注入。
  #
  # 当前整套加解密流程已停用，以下选项全部注释。若取消注释，需要同时恢复：
  #   - flake.nix 中的 agenix input、模块引用与 CLI 安装
  #   - modules/default.nix 中对 ./systemd.nix 的导入
  #   - modules/systemd.nix 中的 env-loader 服务（它依赖此处的
  #     config.age.secrets.ai_api_key.path）
  #   - hyprland.lua 中启动 env-loader 的那一行
  # 否则会出现「未知选项 age」或「attribute 缺失」的构建错误。
  # ==========================================================================

  # 允许从该 SSH 私钥派生 age 身份，用于解密 ai_api_key.age
  # 注意：换机/重建时必须确保该私钥存在，否则系统能构建但密钥解密会失败
  # age.identityPaths = [
  #   "/home/youth/.ssh/id_ed25519"
  # ];

  # 解密后写入一个文件；变量名即解密后的环境变量名（ai_api_key）
  # age.secrets."ai_api_key" = {
  #   file = ./secrets/ai_api_key.age;
  #   owner = "youth"; # 文件属主（同时可在下方通过 symlink 链接到 /run/user/…）
  # };

  # ==========================================================================
  # 六、用户与权限
  # ==========================================================================
  users.users.youth = {
    description = "Youth";
    isNormalUser = true; # 标记为普通用户（可获得自己的 systemd 用户实例）
    home = "/home/youth";
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true; # 忽略 NixOS 对「shell 必须在 store 中」的安全检查
    # hashedPassword = "$6$d89dDb.7HKl8dx2J$NP00uF4ukMaVYoWzInQxoeokT7927qybXJGzrGwe7WYd7aRNMrNVfLbgnotRDPysU0lqTrZ1L0uTu7EjXsYwg/"; # SHA-512 密码哈希（明文不可恢复，修改需用 mkpasswd 生成）
    extraGroups = [
      "wheel" # 系统管理员（配合下方免密 sudo）
      "networkmanager" # NetworkManager / 无线网络管理
      "audio" # 音频设备访问
      "input" # 桌面会话 / 输入设备管理
      "video" # 显卡与视频加速设备
      "docker" # Docker 容器
      "kvm" # KVM 虚拟机加速
      "libvirtd" # libvirt 虚拟化管理
    ];
  };

  # wheel 组 sudo 免密：日常使用便利，但需知晓其安全代价
  security.sudo.wheelNeedsPassword = false;

  # ==========================================================================
  # 七、引导与内核
  # ==========================================================================
  # 使用 systemd-boot 作为 UEFI 引导加载器（安装到 ESP 分区）
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true; # 允许直接写入 EFI 变量（Secure Boot 关闭时可用）

  # 针对移动版/低功耗 SATA 控制器的稳定性修复参数，避免硬盘掉盘
  boot.kernelParams = ["ahci.mobile_lpm_policy=1"];

  # ==========================================================================
  # 八、网络与远程访问
  # ==========================================================================
  services.openssh.enable = true; # 开启 SSH 服务
  services.openssh.settings.PermitRootLogin = "yes"; # 允许 root 直接 SSH 登录
  services.timesyncd.enable = true; # 使用 systemd-timesyncd 做 NTP 时间同步

  # udisks2：桌面环境下 U 盘 / 移动硬盘的自动挂载与图标显示
  services.udisks2.enable = true;

  networking.hostName = "levi"; # 主机名（与 flake 中的 nixosConfigurations.levi 一致）
  networking.networkmanager.enable = true; # 图形化网络管理（NetworkManager）
  networking.firewall.allowedTCPPorts = [
    5900 # VNC 远程桌面端口（若后续启用 VNC 服务）
  ];

  # ==========================================================================
  # 九、电源管理（睡眠/休眠策略）
  # ==========================================================================
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "yes"; # 允许普通睡眠（合盖/菜单挂起）
    AllowHibernation = "no"; # 禁用休眠
    AllowHybridSleep = "no"; # 禁用混合睡眠
    AllowSuspendThenHibernate = "no"; # 禁用「先睡眠后休眠」
  };

  # ==========================================================================
  # 十、区域与本地化
  # ==========================================================================
  time.timeZone = "Asia/Shanghai";
  # 系统 UI 语言使用英文（部分程序无中文翻译，英文更稳定）
  i18n.defaultLocale = "en_US.UTF-8";
  # 但日期/数字等格式使用中文习惯
  i18n.extraLocaleSettings = {
    LC_TIME = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_CTYPE = "zh_CN.UTF-8";
  };

  # 纯 TTY 控制台字体与键盘布局
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
    useXkbConfig = true; # 使用 xkb.options 中定义的 TTY 布局
  };

  # ==========================================================================
  # 十一、字体
  # 说明：Nerd Font 提供大量图标字形，是 Wayland 状态栏/状态脚本显示图标的必要条件。
  # ==========================================================================
  fonts.packages = with pkgs; [
    noto-fonts # Noto 西文字体族
    noto-fonts-cjk-sans # Noto 思源黑体（简体/繁体中文）
    noto-fonts-color-emoji # 彩色 emoji
    dejavu_fonts # DejaVu 字体（部分老程序依赖）
    nerd-fonts.fira-code # 编程字体，含 Nerd 图标
    nerd-fonts.jetbrains-mono # 编程字体，含 Nerd 图标
    nerd-fonts.comic-shanns-mono # 圆体等宽字体，适合终端标题栏
  ];

  fonts = {
    enableDefaultPackages = true; # 保留 nixpkgs 默认字体包，避免无衬线字体缺失
    fontconfig = {
      enable = true; # 启用 fontconfig 字体匹配机制
      defaultFonts = {
        serif = ["Noto Sans" "Noto Sans CJK SC"]; # 注意：serif 实际填的是无衬线族名，属原配置既有写法
        sansSerif = ["Noto Serif" "Noto Serif CJK SC"];
        monospace = ["Fira Code"];
      };
    };
  };

  # ==========================================================================
  # 十二、图形与桌面环境
  # 说明：本机同时安装了 Hyprland 与 Niri 两套 Wayland 合成器，
  #       在 GDM 登录界面选择使用哪一个；两者配置分别在 home-manager 中管理。
  # ==========================================================================
  programs.xwayland.enable = true; # XWayland 支持：用于运行仅支持 X11 的老程序

  # Niri：滚动式平铺 Wayland 合成器
  programs.niri.enable = true;

  # Hyprland：基于 Hyprpaper/Animations 的动态效果型合成器
  programs.hyprland = {
    enable = true;
    withUWSM = true; # 通过 universal-workspace-session 启动，色彩管理更完善
    xwayland.enable = true;
  };

  services.displayManager.gdm.enable = true; # GNOME 显示管理器，用于登录与切换会话
  services.gnome.gnome-keyring.enable = true; # GNOME Keyring：保存 SSH/GPG 密码
  services.xserver.enable = true; # 启用独立 X Server 组件（多数情况下由 XWayland 覆盖）
  security.pam.services.gdm.enableGnomeKeyring = true; # 让 GDM 登录后解锁 gnome-keyring

  # ==========================================================================
  # 十三、音频
  # 说明：PipeWire 作为底层音频服务，并通过 pulse 协议兼容层接管
  #       PulseAudio 程序（wireplumber 等工具的配置在 home 中）。
  # ==========================================================================
  services.pulseaudio.enable = false; # 禁用原生 PulseAudio，改用 PipeWire 的 pulse 兼容层

  security.rtkit.enable = true; # 允许实时音频线程实时调度，降低延迟

  services.pipewire = {
    enable = true; # PipeWire 音频服务
    alsa.enable = true; # 直接桥接 ALSA 应用
    alsa.support32Bit = true; # 支持 32 位 ALSA 程序
    pulse.enable = true; # 启用 pulse 协议兼容层（绝大多数程序依赖它）
  };

  # ==========================================================================
  # 十四、硬件服务
  # ==========================================================================
  hardware.bluetooth.enable = true; # 蓝牙支持（配合系统 bluez）
  services.blueman.enable = true; # 图形化蓝牙管理界面
  services.power-profiles-daemon.enable = true; # 电源模式切换（配合 hyprland 面板脚本）
  services.upower.enable = true; # 电池与电源事件上报，配合桌面电池图标

  hardware = {
    enableAllFirmware = true; # 自动安装内核需要的全部固件（无线网卡等）
    cpu.intel.updateMicrocode = true; # 安装 Intel CPU 微码
    # cpu.amd.updateMicrocode = true; # 若为 AMD 平台，改用此行
  };

  hardware.graphics = {
    enable = true; # 开启硬件图形加速（GLX/EGL + Vulkan）
    enable32Bit = true; # 32 位图形支持，Steam 等需要
    extraPackages = with pkgs; [
      intel-media-driver # Intel 核显（Gen8+ 旧架构需 i965 驱动，此处为新版驱动）
      intel-vaapi-driver # Intel 硬件视频编解码（VA-API），用于浏览器/剪辑加速
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver # 32 位版本的媒体驱动
      intel-vaapi-driver # 32 位版本的 VA-API 驱动
    ];
  };

  # ==========================================================================
  # 十五、系统清理
  # 说明：自动回收旧 store 路径，至少保留 7 天，防止误删正在使用的闭包。
  # ==========================================================================
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly"; # 每周执行一次垃圾回收
    options = lib.mkDefault "--delete-older-than 7d"; # 仅删除 7 天未使用的路径
  };

  # ==========================================================================
  # 十六、状态版本
  # 说明：nixos-rebuild 升级时用于判断哪些配置需要迁移，请勿随意修改。
  # ==========================================================================
  system.stateVersion = "26.05";
}