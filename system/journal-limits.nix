# journal-limits.nix —— systemd 持久化日志（journal）体积上限。
# 作用：把 journal 磁盘占用封顶，保护 SSD、限制写入磨损，同时保留跨启动的
#   历史日志可查询。
# 导入：由 system/default.nix 显式导入。
# 机制：services.journald.settings 生成 /etc/systemd/journald.conf，
#   由 systemd-journald 服务读取并按需轮转/vacuum。
# 取值：SystemMaxUse=100M 远小于默认值（根分区 10%），是“够查证即可”的
#   保守上限；SystemMaxFileSize=16M 让单文件更小、轮转更细。
# Persistent system journal size limits.
{
  # Cap the journal at 100M (default is 10% of the root disk) to bound disk use
  # and SSD write wear; kept on disk so past boots stay queryable.
  services.journald.settings.Journal = {
    SystemMaxUse = "100M";
    SystemMaxFileSize = "16M";
  };
}
