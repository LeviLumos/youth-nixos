{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ── 引导加载程序 ──────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── 网络 ─────────────────────────────────────────────────
  networking.networkmanager.enable = true;
  networking.hostName = "nixos";

  # ── 时区与本地化 ─────────────────────────────────────────
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── 桌面环境：Plasma 6 ───────────────────────────────────
  # Plasma 5 在 25.05 之后已不可用，26.05 必须使用 plasma6
  services.xserver.enable = true;
  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  services.displayManager.sddm = {
    enable = true;
    # 可选：启用 Wayland 下的 SDDM（实验性）
    # wayland.enable = true;
  };

  services.desktopManager.plasma6.enable = true;

  # 默认使用 X11 会话（Plasma 6 默认是 Wayland，如需 X11 取消注释）
  services.displayManager.defaultSession = "plasmax11";
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      zlib zstd stdenv.cc.cc curl openssl attr libssh bzip2
      libxml2 acl libsodium util-linux xz systemd
    ];
  };
  

  # ── Clash Verge ──────────────────────────────────────────
  programs.clash-verge = {
    enable = true;
    # 默认使用维护更活跃的 clash-verge-rev，可显式指定
    package = pkgs.clash-verge-rev;
    # 服务模式：TUN 模式稳定运行所必需
    serviceMode = true;
    # TUN 模式：虚拟网卡全局代理
    tunMode = true;
    # 开机自启
    autoStart = true;
  };

  # ⚠️ TUN 模式必需的防火墙调整
  # 当前 nixpkgs 中，Clash 的 TUN 网卡流量会被 nftables 的反向路径过滤
  # 和输入过滤规则丢弃，必须将虚拟网卡加入信任接口并放行 rpfilter。
  # 网卡名可能是 "Mihomo" 或 "Meta"，取决于内核/Clash 配置。
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "Mihomo" "Meta" ];
    extraReversePathFilterRules = ''
      iifname { "Mihomo", "Meta" } accept comment "clash-verge tun"
    '';
  };

  # ── 系统软件包 ───────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    vim
    alacritty
    git
    firefox
    clash-verge-rev
    mihomo
    mise
  ];

  # ── Nix 二进制缓存（国内镜像加速） ──────────────────────
  nix.settings = {

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
