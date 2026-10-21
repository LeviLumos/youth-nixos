# bluetooth.nix —— koru 主机的蓝牙配置：整个蓝牙协议栈被关闭。
# 本文件位于 hosts/koru/ 目录，由 flake.nix 的 mkHost 以目录方式导入，
#   并经 hosts/koru/default.nix 汇总，最终并入 nixosConfigurations.koru 生效。
# 目的：罗技 2.4G 鼠标使蓝牙从未被用到；关闭协议栈 + rfkill 封锁射频以省电。
# --- bluetooth ---
# Bluetooth is off: the stack is not enabled and the radio is soft-blocked.
# The Logitech 2.4G mouse means the radio is never used.
{ pkgs, ... }:

{
  # --- Bluetooth: disabled ---
  hardware.bluetooth.enable = false;  # 不启用蓝牙服务栈，不加载任何蓝牙守护进程
  services.blueman.enable = false;  # 不安装 blueman 蓝牙管理托盘

  # btusb may still probe the controller, so keep it rfkill-blocked for battery
  # life. To use Bluetooth, re-enable the stack first (hardware.bluetooth.enable),
  # then: rfkill unblock bluetooth && bluetoothctl power on
  # 蓝牙省电封锁单元：仅关闭协议栈时，btusb 驱动仍可能探测控制器而耗电，
  # 因此开机后用 rfkill 软封锁蓝牙射频。after = systemd-rfkill.service 保证
  # 排在 rfkill 服务之后、不被其覆盖；oneshot 表示执行一次即退出。
  # 若将来要用蓝牙：先重新启用 hardware.bluetooth.enable，
  # 再 rfkill unblock bluetooth && bluetoothctl power on。
  systemd.services.block-bluetooth = {
    description = "Block Bluetooth rfkill (power saving)";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-rfkill.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill block bluetooth";
    };
  };
}
