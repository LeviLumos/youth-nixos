# firewall.nix —— 应用级防火墙放行规则（SSH 除外）。
# 作用：向局域网放行 TCP 8080，用于 koru file 文件分享与本地静态服务。
# 导入：由 system/default.nix 显式导入。
# 机制：networking.firewall 由 NixOS 生成 nftables/iptables 规则并启用防火墙。
# 依赖：SSH 的 22 端口放行在 openssh-server.nix 中就近维护（openFirewall）。
# Application-specific inbound firewall ports (SSH is in openssh-server.nix).
{
  # Allow LAN devices to reach koru file and local static/Slidev servers on 8080.
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
