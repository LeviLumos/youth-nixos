# ── 核心系统：引导、网络、时区、Nix、nix-ld ────────────────
{ config, pkgs, ... }:

{
  # ── 引导加载程序 ──────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── 网络 ─────────────────────────────────────────────────
  networking.networkmanager.enable = true;
  networking.hostName = "nixos";

  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  # ── 时区与本地化 ─────────────────────────────────────────
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── nix-ld（运行非 Nix 二进制） ──────────────────────────
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      zlib zstd stdenv.cc.cc curl openssl attr libssh bzip2
      libxml2 acl libsodium util-linux xz systemd
    ];
  };

  # ── Nix 二进制缓存（国内镜像加速） ──────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.sjtu.edu.cn/nix-channels/store"
      # 保留官方源作为备用，防止镜像缺失某些包
      # "https://cache.nixos.org/"
    ];
    trusted-substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.sjtu.edu.cn/nix-channels/store"
      # 保留官方源作为备用，防止镜像缺失某些包
      # "https://cache.nixos.org/"
    ];
  };

  # ── 系统状态版本 ────────────────────────────────────────
  # 跨大版本升级后应更新，26.05 对应 "26.05"
  system.stateVersion = "26.05";
}
