# memory-zram.nix —— 内存压缩交换（zram）、systemd-oomd 与内存回收 sysctl。
# 作用：无磁盘 swap 的前提下，用 RAM 内 zstd 压缩块设备扩展有效内存，
#   并调整回收时机，避免桌面在内存压力下整体冻结。
# 导入：由 system/default.nix 显式导入。
# 机制：zramSwap 由 zram-generator 生成 /dev/zram0 与 systemd 单元；
#   systemd.oomd 启用 oomd 并监听 user slice；sysctl 经 boot.kernel.sysctl。
# 取值：memoryPercent=34 → 约 8G/23G，压缩后收益高且留足匿名页；
#   zstd 相比 lz4 压缩率更高、CPU 代价可忽略；swappiness=180（0-200）
#   仅在“全部 swap 都是内存”时安全（有断言守护）；watermark_boost_factor=0
#   关闭激进水位提升；watermark_scale_factor=125 让 kswapd 提前平稳回收；
#   page-cluster=0 因 zram 无寻道、预读无意义。
# Compressed swap, VM reclaim and user-slice memory-pressure handling.
{ config, ... }:
{
  assertions = [
    {
      assertion = config.swapDevices == [ ];
      message = "memory-zram.nix uses vm.swappiness=180 for RAM-backed swap; review the policy before adding disk swap.";
    }
  ];
  # systemd-oomd: kill the biggest *user* process under memory pressure instead
  # of letting the kernel OOM killer freeze the whole desktop. Pairs with zram
  # (configured below).
  systemd.oomd.enable = true;
  systemd.oomd.enableUserSlices = true;

  # --- zram in-memory swap ---
  # Only valid because ALL swap is in-memory on this machine (no disk swap:
  # swapDevices = []); if a swapfile is ever added, revert vm.swappiness to
  # <=60 or cold pages will thrash onto disk.
  #
  # 8G zram (34% of 23G RAM), compressed in memory: no SSD wear, and gives the
  # OOM killer room to breathe before the system freezes.
  zramSwap = {
    enable = true;
    memoryPercent = 34;
    # zstd beats lz4 on compress ratio with negligible CPU cost here.
    algorithm = "zstd";
  };

  boot.kernel.sysctl = {
    # Prefer swapping to zram (range 0-200, default 60): compressed pages and
    # their reclaim are cheap.
    "vm.swappiness" = 180;
    # Disable watermark boost: let RAM fill up before the kernel reclaims.
    "vm.watermark_boost_factor" = 0;
    # Wake kswapd earlier (free memory below 1/125 of RAM) so allocation
    # pressure stays smooth instead of sudden swap storms at high swappiness.
    "vm.watermark_scale_factor" = 125;
    # zram is memory-adjacent: swap readahead just fetches useless pages.
    "vm.page-cluster" = 0;
  };
}
