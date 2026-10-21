# btrfs-mounts.nix —— koru 主机的 Btrfs 挂载策略：为根目录、/home、/nix 三个
# 子卷统一追加性能/寿命相关挂载参数。
# 设备与子卷（UUID、subvol）的真值定义在 hardware-configuration.nix，
#   本文件只集中管理选项，二者职责分离。
# 由 flake.nix 的 mkHost 以目录 ./hosts/koru 导入，经 default.nix 汇总生效。
# koru: Btrfs mount policy; UUIDs remain in hardware-configuration.nix.
{
  # btrfs: zstd compression (faster reads on NVMe), noatime (no write on every
  # read, less SSD wear) and discard=async (queued TRIM, no fstrim timer).
  fileSystems."/" = {
    options = [
      "compress=zstd"  # 透明压缩：NVMe 上读取更快、占用更小
      "noatime"  # 不更新访问时间，减少 SSD 写入磨损
      "discard=async"  # 异步排队 TRIM，无需 fstrim 定时器
    ];
  };
  fileSystems."/home" = {  # /home 子卷同样受益于这三项（与根分区同盘同 UUID，仅子卷不同）
    options = [
      "compress=zstd"
      "noatime"
      "discard=async"
    ];
  };
  fileSystems."/nix" = {  # /nix（store）是读多写少的最佳压缩场景
    options = [
      "compress=zstd"
      "noatime"
      "discard=async"
    ];
  };
}
