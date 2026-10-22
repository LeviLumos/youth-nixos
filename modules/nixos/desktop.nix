# =============================================================================
#  桌面：niri + Wayland 支撑 + 字体 +（可选）自动登录
# -----------------------------------------------------------------------------
#  niri 的配置文件本身由 home-manager 的 home.file 管理（见 modules/home/niri.nix）
# =============================================================================
{ config, lib, pkgs, vars, ... }:

let
  # vars.fonts.mono.package / .variant 都是字符串，这里解析成真正的 derivation
  monoFont = pkgs.${vars.fonts.mono.package}.${vars.fonts.mono.variant};
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
  #  pavucontrol、waybar 音量模块、waybar 的音量点击都依赖它；关掉就没有声音
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
      noto-fonts-emoji               # emoji
    ]);

    fontconfig.defaultFonts = {
      monospace = [ vars.fonts.mono.family ];
    };
  };

  # ---- 可选：greetd 开机自动进入 niri ----------------------------------------
  #  把 vars.nix 里的 niri.autoLogin 改成 true 即可生效（否则为普通 TTY 登录，
  #  登录后执行 `niri-session` 启动桌面）。
  services.greetd = lib.mkIf vars.niri.autoLogin {
    enable = true;
    settings = {
      default_session = {
        command = "${config.programs.niri.package}/bin/niri-session";
        user = vars.username;
      };
    };
  };
}
