# hosts/koru/default.nix —— koru 主机的模块汇总入口：显式 imports 全部主机
# 子模块，设定主机名与系统状态版本。
# 由 flake.nix 的 mkHost 以 modules = [ ./hosts/koru ] 导入（模块系统同时会
#   自动发现目录下的 .nix 文件）；default.nix 保证子模块加载意图明确。
# 硬件身份（hardware-configuration.nix）与 stateVersion 按生成值原样保留。
# 依赖：hostname 来自 mkHost specialArgs（inventory.nix 的键名）。
# koru host composition. Hardware identities and state version are preserved.
{ hostname, ... }:
{
  # 以下按“硬件 → 引导 → 挂载 → 本地化 → 用户 → 外设/图形/电源”的顺序汇总：
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ./btrfs-mounts.nix
    ./locale.nix
    ./user-account.nix
    ./bluetooth.nix
    ./display-power.nix
    ./intel-graphics.nix
    ./power-management.nix
  ];
  networking.hostName = hostname;  # 主机名来自 mkHost specialArgs（即 inventory.nix 中的键名 koru）
  system.stateVersion = "26.11";  # stateVersion 决定 NixOS 升级时的迁移行为基准，装机后不应改动
}
