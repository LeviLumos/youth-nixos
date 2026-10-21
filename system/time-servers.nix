# time-servers.nix —— NTP 时间同步服务器选择。
# 作用：把系统时间同步的上游换为国内服务器（阿里云、腾讯云），
#   保证低延迟、高可用的准确授时。
# 导入：由 system/default.nix 显式导入。
# 机制：networking.timeServers 由 systemd-timesyncd 消费（写入其配置，
#   timesyncd 服务按序尝试列表内服务器）。
# Network time synchronization server selection.
{
  # Mainland NTP servers for accurate system time.
  networking.timeServers = [
    "ntp.aliyun.com"
    "ntp.tencent.com"
  ];
}
