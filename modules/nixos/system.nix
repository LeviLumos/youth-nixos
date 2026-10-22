# =============================================================================
#  系统基础：版本 / 区域 / Nix 设置 / 国内源 / unfree
# =============================================================================
{ vars, ... }:
{
  # ⚠️ stateVersion 只跟 NixOS 大版本走，升级系统时不要随便改
  system.stateVersion = vars.stateVersion;

  # ---- 区域与语言 -----------------------------------------------------------
  time.timeZone = vars.timezone;

  i18n = {
    defaultLocale = vars.locale;
    supportedLocales = vars.supportedLocales;
    extraLocaleSettings = {
      LC_CTYPE = vars.locale;
    };
  };

  console.keyMap = vars.consoleKeymap;

  services.xserver.xkb = {
    layout = vars.xkb.layout;
    variant = vars.xkb.variant;
  };

  # ---- Nix 与国内源（中科大 USTC）--------------------------------------------
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # 中科大二进制缓存优先；cache.nixos.org 作为兜底
      substituters = vars.nixSubstituters;
      # 命中镜像失败时快速回退
      connect-timeout = 10;
      # 每 60 天自动 GC 一次 30 天前的旧世代
      auto-optimise-store = true;
      warn-dirty = false;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # ---- 允许 unfree 包（google-chrome 等）--------------------------------------
  nixpkgs.config = {
    allowUnfree = true;
  };
}
