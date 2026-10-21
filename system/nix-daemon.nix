# nix-daemon.nix —— Nix 守护进程全局设置：镜像源、并行度与自动 GC 阈值。
# 作用：集中配置 experimental-features、国内优先的 substituter 列表与公钥、
#   可信用户、下载/构建并行度，以及磁盘水位触发的守护进程自动 GC。
# 导入：由 system/default.nix 显式导入。
# 机制：nix.settings 生成 /etc/nix/nix.conf，由 nix-daemon systemd 服务读取；
#   min-free/max-free 由 nix-daemon 在后台周期检查并触发 GC。
# 取值：BFSU 首选（实测远快于 USTC），其余为故障回退，connect-timeout +
#   fallback 保证慢镜像不卡构建；max-jobs/cores 按 23G 内存反推上限
#   （QtWebEngine 链接峰值高，全并行会 OOM）；min-free/max-free 保证下载
#   新闭包前留出余量。allowUnfree 在根 flake.nix 的 mkPkgs 中重复声明是有意的：
#   独立 home profile 用单独的 pkgs 实例，两处都必须设置。
# --- nix ---
# Nix daemon settings: substituters, parallelism and automatic store GC
# thresholds. Split out of the host file so the host only holds device identity
# (boot/fs/user) and this stays reusable platform tuning.
_: {
  # Single-user machine: allow unfree (e.g. firmware) everywhere. Kept here
  # rather than in the host file so every device shares the choice.
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # BFSU first: chsrc speed-tested it fastest on this connection (31 MB/s
    # vs USTC's 2.9 MB/s); the rest are fallbacks so a slow mirror can't stall.
    substituters = [
      "https://mirrors.bfsu.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      # ROS 2 binaries (profile/packages/ros2.nix) live only here; without it the
      # whole ROS closure would build from source. May be slow from CN.
      "https://ros.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
    ];
    # Let wheel users (koru) use their chsrc-set ~/.config/nix/nix.conf
    # without the "ignoring untrusted substituter" warning.
    trusted-users = [
      "root"
      "@wheel"
    ];
    fallback = true;
    connect-timeout = 10;
    download-attempts = 3;
    # More parallel downloads and on-the-fly store dedup (hardlinks) instead
    # of waiting for a scheduled optimise.
    max-substitution-jobs = 32;
    # 20 threads x full parallel gcc easily OOMs (QtWebEngine link peaks at
    # ~10GB); cap at 4 concurrent builds x 8 cores to stay under 23G RAM.
    max-jobs = 4;
    cores = 8;
    # Daemon auto-GC: whenever free disk drops below 5G, collect until 10G.
    # Complements the nightly timer below.
    min-free = "${toString (5 * 1024 * 1024 * 1024)}";
    max-free = "${toString (10 * 1024 * 1024 * 1024)}";
    auto-optimise-store = true;
  };
}
