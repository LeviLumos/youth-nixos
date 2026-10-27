# =============================================================================
#  系统基础：版本 / 区域 / Nix 设置（国内源 + 每周 GC）/ unfree
# =============================================================================
{ lib, vars, ... }:
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

  # ---- 内存兜底：zram swap（压缩内存当交换分区）--------------------------------
  #  从源码编译重型包（浏览器、Rust 项目等）时容易把内存打满被 OOM kill，
  #  zram 用一部分内存做压缩 swap，比没有 swap 稳得多（重启后自动生效）
  zramSwap = {
    enable = true;
    memoryPercent = 50;                  # 用 50% 内存作为 zram（可改 25~100）
    algorithm = "zstd";                  # 压缩算法：zstd / lz4
  };

  # XKB：layout/variant/options 同时喂给 X(XWayland 应用) 与 niri
  #  （niri 是 Wayland 合成器，不走 xserver 的配置，见 dotfiles/niri/config.kdl 的 input.keyboard.xkb）
  services.xserver.xkb = {
    layout = vars.xkb.layout;
    variant = vars.xkb.variant;
    options = vars.xkb.options;           # 默认 "caps:super"：CapsLock → Super/Mod
  };

  # ---- Nix 与国内源（中科大 USTC）--------------------------------------------
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # 中科大二进制缓存优先；cache.nixos.org 作为兜底
      substituters = vars.nixSubstituters;
      # 命中镜像失败时快速回退
      connect-timeout = 10;
      # 每次添加路径时自动硬链接去重（配合下面的 nix.optimise 定期全量优化）
      auto-optimise-store = true;
      warn-dirty = false;
    };

    # ---- 垃圾回收：每周自动清理旧世代 -------------------------------------------
    #  定时器：nix-gc.timer（systemctl list-timers nix-gc 看下次运行时间）
    #  ⚠️ 只删「没有 gc-root 指向」的路径；当前系统、当前启动项、home-manager
    #     当前世代都在 root 里，不会被删 —— 可以放心开着。
    gc = lib.mkIf vars.nixGc.enable {
      automatic = true;
      dates = vars.nixGc.dates;                 # weekly
      options = "--delete-older-than ${vars.nixGc.deleteOlderThan}";
      persistent = vars.nixGc.persistent;       # 关机错过 → 开机补跑
      randomizedDelaySec = "30min";             # 避免和别人同一时刻卡 I/O
    };

    # ---- store 去重：每周把相同文件硬链接成一份 ---------------------------------
    optimise = lib.mkIf vars.nixOptimise.enable {
      automatic = true;
      dates = vars.nixOptimise.dates;
      persistent = vars.nixOptimise.persistent;
    };
  };

  # ---- 允许 unfree 包（google-chrome 等）--------------------------------------
  nixpkgs.config = {
    allowUnfree = true;
  };
}
