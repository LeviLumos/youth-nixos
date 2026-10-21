# nix-garbage-collection.nix —— Nix 定时垃圾回收与手动升级策略。
# 作用：每天凌晨 03:15 自动 GC，删除 7 天前的旧 generation 并清理无引用的
#   store 路径；保持自动升级关闭，flake.lock 更新走手动流程。
# 导入：由 system/default.nix 显式导入。
# 机制：nix.gc.automatic 生成 nix-gc.service + nix-gc.timer（persistent=true
#   关机错过则补跑）；system.autoUpgrade.enable=false 即不创建升级定时器。
# 取值：7d 兼顾回滚窗口与磁盘占用；启动项数量由 boot.loader.systemd-boot.
#   configurationLimit 独立控制，不受 GC 影响。
# Scheduled Nix garbage collection and manual upgrade policy.
{
  # Daily GC via the built-in timer: drop generations older than a week, then
  # collect unreferenced store paths. Boot entries are capped independently by
  # boot.loader.systemd-boot.configurationLimit.
  nix.gc = {
    automatic = true;
    dates = "03:15";
    persistent = true;
    options = "--delete-older-than 7d";
  };
  # Auto-upgrade stays off; flake.lock and github-hosts are refreshed manually
  # with `nix flake update`, followed by an explicit rebuild. `dates`/`flake` are not
  # set: they are inert while `enable` is false.
  system.autoUpgrade.enable = false;
}
