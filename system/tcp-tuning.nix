# tcp-tuning.nix —— TCP 拥塞控制、队列规则（qdisc）与 IPv4 加固 sysctl。
# 作用：启用 BBR 拥塞控制 + CAKE qdisc（高延迟/丢包链路吞吐更好、Wi-Fi 下
#   降低 bufferbloat 并按流公平调度）；开启 TFO 等 TCP 调优；应用面向不可信
#   Wi-Fi 的反向路径过滤/拒绝重定向等加固项。
# 导入：由 system/default.nix 显式导入。
# 机制：boot.kernelModules 让 kmod 在 sysctl 应用前先加载 tcp_bbr 与 sch_cake
#   模块（库存内核中两者为模块而非内建），否则对应 sysctl 会因模块未载入而失败；
#   其余经 boot.kernel.sysctl 写入运行时内核。
# 取值：tcp_fastopen=3 = 客户端+服务端同时启用；rmem/wmem_max 支撑大带宽
#   积延迟链路的窗口；backlog 承载突发连接；加固项集合沿用 fufexan/nyx。
# TCP congestion control, queueing and IPv4 hardening.
{
  # Load the BBR congestion-control module and the CAKE qdisc module before
  # the sysctls below are applied (both compiled as modules on stock kernels).
  boot.kernelModules = [
    "tcp_bbr"
    "sch_cake"
  ];

  boot.kernel.sysctl = {
    # BBR + CAKE: better throughput/latency on high-BDP and lossy links;
    # CAKE also gives per-flow fairness and lower bufferbloat on Wi-Fi.
    "net.core.default_qdisc" = "cake";
    "net.ipv4.tcp_congestion_control" = "bbr";

    # TCP Fast Open (client + server) and general TCP tuning.
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_sack" = 1;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.ip_local_port_range" = "1024 65535";

    # Larger socket buffers and backlog for faster bulk transfers.
    "net.core.rmem_max" = 2500000;
    "net.core.wmem_max" = 2500000;
    "net.core.netdev_max_backlog" = 100000;

    # TCP hardening on untrusted Wi-Fi (fufexan/nyx shared set): strict
    # reverse-path filtering, no redirects or source routing, ignore bogus
    # ICMP errors and RFC 1337 TIME-WAIT killing.
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.tcp_rfc1337" = 1;
  };
}
