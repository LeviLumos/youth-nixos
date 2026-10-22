# =============================================================================
#  蓝牙
# -----------------------------------------------------------------------------
#  开关：vars.hardware.bluetooth
#  组件：bluez（hardware.bluetooth）+ blueman（GTK 图形管理工具）
# =============================================================================
{ lib, vars, ... }:
{
  hardware.bluetooth = lib.mkIf vars.hardware.bluetooth {
    enable = true;
    # 开机给蓝牙设备上电（省得每次手动打开）
    powerOnBoot = true;
  };

  # 图形化蓝牙管理（状态栏/启动器里搜 Blueman）
  services.blueman.enable = vars.hardware.bluetooth;
}
