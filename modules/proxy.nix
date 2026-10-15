# ── Clash Verge（网络代理）＋ TUN 模式防火墙调整 ────────────
{ config, pkgs, ... }:

{
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
}
