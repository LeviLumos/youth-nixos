# =============================================================================
#  电源管理 / 挂起 / 休眠
# -----------------------------------------------------------------------------
#  开关：vars.power.*
#  组件：
#    powerManagement（CPU 频率/节能）、power-profiles-daemon（省电/均衡/性能档位）
#    upower（电池与设备电量，状态栏等依赖）、logind（合盖/电源键/休眠策略）
#
#  ⚠️ 休眠（hibernate）要真正可用，还必须满足（机器相关，见 doc）：
#     1. 有 swap 分区/文件，且 swap ≥ 物理内存
#     2. hardware-configuration.nix 里配置：boot.resumeDevice = "/dev/disk/by-uuid/<swap UUID>";
#     3. 内核参数带上 resume（NixOS 会根据 resumeDevice 自动加）
#     4. 用 `systemctl hibernate` 验证；不行就查 `journalctl -u systemd-hibernate`
# =============================================================================
{ lib, vars, ... }:
{
  # ---- 基础电源管理 ---------------------------------------------------------
  powerManagement.enable = vars.power.enable;

  powerManagement.cpuFreqGovernor =
    lib.mkIf (vars.power.cpuFreqGovernor != null) vars.power.cpuFreqGovernor;

  # 省电/均衡/性能档位切换（waybar/系统托盘可调用；命令行：powerprofilesctl set balanced）
  services.power-profiles-daemon.enable = vars.power.enable;

  # 电池、外设电量等状态（UPower DBus）
  services.upower.enable = vars.power.enable;

  # ---- systemd-logind：合盖 / 电源键 / 休眠策略 -------------------------------
  services.logind.settings = {
    Login = {
      HandleLidSwitch = vars.power.lidSwitch;
      HandleLidSwitchExternalPower = vars.power.lidSwitchExternalPower;
      HandleLidSwitchDocked = "ignore";
      HandlePowerKey = vars.power.powerKey;
      # 插电时按电源键也可以设成 "ignore"，避免误触关机
    };
    Sleep = {
      # 笔记本：先挂起，挂起 HibernateDelaySec 后自动转休眠，省电又不丢状态
      AllowSuspendThenHibernate = "yes";
      HibernateDelaySec = "2h";
    };
  };

  # ---- 笔记本省电（按需打开）--------------------------------------------------
  # services.tlp = {
  #   enable = true;
  #   settings = {
  #     TLP_DEFAULT_MODE = "AC";
  #     CPU_SCALING_GOVERNOR_ON_AC = "performance";
  #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
  #   };
  # };
}
