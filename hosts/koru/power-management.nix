# power-management.nix —— koru 主机的电源管理总纲：CPU 调频（auto-cpufreq）、
# 温控（thermald）、电池上报（upower）、声卡编解码器省电、powertop 开机自动
# 调优与鼠标接收器保活。
# 压缩交换与 VM 调参在 system/memory-zram.nix（不在本文件）。
# 由 flake.nix 的 mkHost 以目录 ./hosts/koru 导入，经 default.nix 汇总生效。
# 策略（电池优先）：电池下 powersave + EPP power、峰值钳 3GHz、禁睿频；
#   插电下 performance + 睿频自动。
# --- power ---
# Power saving: auto-cpufreq (AC/battery CPU scaling), thermald, upower, audio
# codec power save and powertop auto-tune at boot.
# Compressed swap and VM tuning live in memory-zram.nix.
#
# Refs:
#   - auto-cpufreq profile: nyx (laptop/system/power/monitors/auto-cpufreq.nix)
#   - caution: on some boards `powersave` pins cores at the frequency floor
#     (Misterio77's merope stall); keep EPP + a max-freq cap, no hard min.
#   - VM tuning: pop-os default-settings, also used by nyx and ryan4yin.
{ lib, pkgs, ... }:
let
  # 046d:c53f 即 Vendor:Product ID：Logitech 2.4G 接收器；遍历 USB 总线匹配后把
  # power/control 写回 on，防止 powertop 的自动挂起让鼠标唤醒后第一次移动有延迟
  # Pin the Logitech 2.4G receiver (046d:c53f) to "on" so the mouse never gets
  # autosuspended (autosuspend makes the first movement lag on wake).
  keep-mouse-awake = pkgs.writeShellScript "keep-mouse-awake" ''
    for d in /sys/bus/usb/devices/*; do
      [ -r "$d/idVendor" ] || continue
      [ "$(cat "$d/idVendor"):$(cat "$d/idProduct")" = "046d:c53f" ] || continue
      echo on > "$d/power/control"
    done
  '';
in
{
  # 调优/诊断工具：powertop（省电调优）、powerstat（功耗统计）、pciutils（lspci 查硬件）
  environment.systemPackages = with pkgs; [
    powertop
    powerstat
    pciutils
  ];

  # --- CPU frequency scaling ---
  # Replaces power-profiles-daemon (they fight over the governor): on battery
  # cores stay low with turbo off; on charger everything runs all-out.
  # i7-13650HX: 800MHz floor, 4.7GHz ceiling, HWP EPP supported.
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "performance";  # 插电：性能 governor
        energy_performance_preference = "performance";  # EPP 也设为 performance
        turbo = "auto";  # 睿频自动
      };
      battery = {
        governor = "powersave";  # 电池：省电 governor
        energy_performance_preference = "power";  # EPP 设为 power
        # Cap P-core bursts at 3GHz on battery (~30% less peak power draw);
        # idle still drops to the 800MHz floor (no hard min, see header ref).
        scaling_max_freq = "3000000";  # 电池下把 P 核峰值钳到 3GHz，峰值功耗约降 30%（i7-13650HX 标称上限 4.7GHz）；空闲仍落回 800MHz 地板，不设硬性下限
        turbo = "never";  # 电池下禁用睿频
      };
    };
  };

  # --- Thermal ---
  # Intel DPTF daemon: smooths fans and clock throttling under sustained load;
  # pairs with the already-active Intel microcode updates.
  #
  # The NixOS module hardcodes --adaptive, but this board exposes no DPTF/PSVT
  # performance tables, so adaptive mode finds no zones and exits 1, which
  # systemd flags at every boot. Drop the flag: non-adaptive is thermald's own
  # suggested fallback and works off the standard thermal zones.
  services.thermald.enable = true;
  # mkForce 去掉模块硬编码的 --adaptive：本板无 DPTF/PSVT 性能表，adaptive 找不到 zone 会退出码 1
  systemd.services.thermald.serviceConfig.ExecStart =
    lib.mkForce "${pkgs.thermald}/sbin/thermald --no-daemon --dbus-enable";

  # --- Battery reporting ---
  # upower powers battery UI and AC/battery events (auto-cpufreq and the screen
  # profile in hosts/koru/display-power.nix both listen for them).
  services.upower.enable = true;  # 提供电池 UI 数据与 AC/电池事件——auto-cpufreq 与 display-power.nix 的屏幕策略都依赖这些事件

  # --- Audio codec ---
  # Power save from module load time (powertop re-applies it at runtime).
  boot.extraModprobeConfig = "options snd_hda_intel power_save=1";  # snd_hda_intel power_save=1：从模块加载起就开启声卡编解码器省电（powertop 运行时会再次套用）

  # --- Powertop ---
  # auto-tune at boot: USB autosuspend, PCIe runtime PM (NIC/NVMe/DPTF),
  # audio codec power_save, NMI watchdog off. NixOS's services.powertop option
  # no longer exists on this nixpkgs branch, hence the manual unit.
  # 手写 oneshot 单元：本 nixpkgs 分支已无 services.powertop 选项；开机执行 auto-tune
  # （USB 自动挂起、PCIe 运行时电源管理、NMI 看门狗关闭等），随后立即把罗技接收器
  # 重新钉回 on（ExecStart 列表按序执行）
  systemd.services.powertop = {
    description = "Powertop auto-tuning";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${pkgs.powertop}/bin/powertop --auto-tune"
        # Re-pin the Logitech receiver to "on" after tuning (see above).
        "${keep-mouse-awake}"
      ];
    };
  };

}
