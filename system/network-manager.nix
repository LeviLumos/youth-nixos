# network-manager.nix —— NetworkManager 网络管理与 Wi-Fi 省电策略。
# 作用：启用 NetworkManager 统一管理有线/无线；开启 Wi-Fi 省电（电池优先）；
#   关闭开机阻塞式 wait-online；设置国内公共 DNS（含 IPv6）。
# 导入：由 system/default.nix 显式导入。
# 机制：networking.networkmanager 生成 NM 服务与 D-Bus 配置；
#   wifi.powersave=3 = 开启省电（1 禁用位 + 2 启用位）；
#   wait-online 关闭可避免图形登录等待网络就绪超时；nameservers 写入
#   /etc/resolv.conf 的全局兜底（NM 仍可按连接覆写）。
# NetworkManager and Wi-Fi power-saving policy.
{
  networking.networkmanager.enable = true;

  # Wi-Fi power saving: on battery the NIC rests between packets
  # (~0.2-0.4W); latency impact is negligible with modern iwlwifi runtime PM.
  networking.networkmanager.settings."connection"."wifi.powersave" = 3;

  systemd.services.NetworkManager-wait-online.enable = false;
  # Mainland-friendly public DNS with IPv6 entries.
  networking.nameservers = [
    "119.29.29.29" # DNSPod
    "223.5.5.5" # AliDNS
    "2402:4e00::" # DNSPod IPv6
    "2400:3200::1" # AliDNS IPv6
  ];
}
