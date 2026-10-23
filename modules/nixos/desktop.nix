# =============================================================================
#  桌面：niri + Wayland 支撑 + 字体 +（可选）自动登录
# -----------------------------------------------------------------------------
#  niri 的配置文件本身由 home-manager 的 home.file 管理（见 modules/home/niri.nix）
# =============================================================================
{ config, lib, pkgs, vars, ... }:

let
  # vars.fonts.mono.package / .variant 都是字符串，这里解析成真正的 derivation
  monoFont = pkgs.${vars.fonts.mono.package}.${vars.fonts.mono.variant};

  # 登录会话命令：niri（greetd 用它启动桌面）
  niriSession = "${config.programs.niri.package}/bin/niri-session";
in
{
  # ---- niri 本体（NixOS 官方模块，不需要额外 flake）--------------------------
  programs.niri.enable = true;

  # ---- Wayland 必需支撑 -----------------------------------------------------
  security.polkit.enable = true;

  services.gnome.gnome-keyring.enable = true;

  # 文件选择器 / 截屏 / 屏幕共享等 portal
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Electron/Chromium 系应用（vscodium / chrome / obsidian）在 Wayland 下更稳
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # X11 应用（XWayland）支持
  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];

  # 让 niri 继承完整的用户 PATH（配合 greetd / TTY 手动启动都推荐）
  systemd.user.services.niri.enableDefaultPath = false;

  # ---- 音频（PipeWire）------------------------------------------------------
  #  pavucontrol 等混音器依赖它；关掉就没有声音
  services.pipewire = lib.mkIf vars.hardware.audio {
    enable = true;
    alsa.enable = true;                  # ALSA 应用 → PipeWire
    alsa.support32Bit = true;            # 32 位程序（wine / steam 等）
    pulse.enable = true;                 # PulseAudio 应用 → PipeWire（pactl/pavucontrol 需要）
    jack.enable = true;                  # 专业音频 / JACK 应用
    wireplumber.enable = true;           # 会话管理器（设备连接、路由）
  };

  # 实时优先级（避免爆音/卡顿）
  security.rtkit.enable = lib.mkIf vars.hardware.audio true;

  # ---- 锁屏（swaylock）需要的 PAM --------------------------------------------
  #  super+alt+l 会调用 swaylock；没有 PAM 配置会直接无法解锁
  security.pam.services.swaylock = { };

  # ---- 字体 -----------------------------------------------------------------
  fonts = {
    enableDefaultPackages = true;
    packages = [
      monoFont                       # Maple Mono CN（终端字体，需求）
    ] ++ (with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans            # 中文（界面/文档）
      noto-fonts-color-emoji         # emoji（26.05 起由 noto-fonts-emoji 改名而来）
    ]);

    fontconfig.defaultFonts = {
      monospace = [ vars.fonts.mono.family ];
    };
  };

  # ---- greetd + tuigreet（登录管理器）----------------------------------------
  #  greetd 的待遇由 vars.nix 的 niri.autoLogin 决定：
  #    true  → 开机免密直接进 niri（用 initial_session）
  #    false → 完全不装 greetd：TTY 登录后手动执行 niri-session
  #
  #  两种模式下 tuigreet 都是「登录界面」本身；autoLogin=true 时它只在
  #  手动 systemctl restart greetd / 关掉自动登录后才会真正露面。
  #  ⚠️ greetd 模块在 settings 含 initial_session 时会自动关掉 restart，
  #     避免「退出 niri → 又被自动登录」的死循环；所以退出 niri 后
  #     tty1 会空着，用 ctrl+alt+F2 登录后再 sudo systemctl restart greetd 即可。
  services.greetd = lib.mkIf vars.niri.autoLogin {
    enable = true;
    useTextGreeter = true;                    # tuigreet 是 TUI：避免 systemd 启动日志打乱界面

    settings = {
      # 登录界面：tuigreet（--time 显示时间，--remember 记住上次登录的用户）
      default_session = {
        user = "greeter";                     # 该用户由 greetd 模块自动创建
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${niriSession}";
      };

      # 开机自动登录（只跑一次）
      initial_session = {
        user = vars.username;
        command = niriSession;
      };
    };
  };
}
