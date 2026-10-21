# display-power.nix —— koru 主机的屏幕电源策略：按供电状态（电池/交流）
# 自动调整 Niri 合成器下的亮度与刷新率。
# 生效链路：udev 监听电源适配器插拔事件 → 触发 oneshot systemd 服务
#   niri-display-power → 以用户身份运行 power-profile 脚本 → 经 niri IPC +
#   brightnessctl 调整屏幕。
# 由 flake.nix 的 mkHost 以目录 ./hosts/koru 导入，经 default.nix 汇总生效。
# 策略：电池档 60% 亮度 + 60Hz；交流档 100% + 144Hz（目标刷新率取模式表中
#   数值最接近者）。
# Niri display brightness and refresh-rate policy on AC/battery.
{
  lib,
  pkgs,
  username,
  ...
}:
let
  # Store paths kept out of the ambient PATH (udev spawns power-profile with no
  # user environment).
  jq = lib.getExe pkgs.jq;  # 用 getExe 取绝对路径：udev 衍生本脚本时没有用户 PATH，只能写死 store 路径
  niri = lib.getExe pkgs.niri;  # 同上，取 store 绝对路径

  # AC/battery screen profile: dim to 60% + 60Hz on battery, full 100% + 144Hz
  # on AC. No-ops unless a niri session is running, so it is safe as a udev
  # trigger.
  power-profile = pkgs.writeShellScriptBin "power-profile" ''
    set -euo pipefail
    # udev 环境无 PATH，指到当前系统 profile 的 bin
    export PATH=/run/current-system/sw/bin

    # 没有会话环境时按 uid 推导 XDG_RUNTIME_DIR
    uid="''$(id -u)"
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/''$uid}"

    # niri 的 IPC 套接字在 XDG_RUNTIME_DIR 下，但 udev 不带会话环境启动本脚本，
    # 需从套接字文件名找回；找不到则直接退出——无图形会话时安全空转
    # niri's IPC socket lives in XDG_RUNTIME_DIR, but udev starts us without the
    # session environment, so recover it from the socket file (the old sway
    # script did the same for SWAYSOCK).
    if [ -z "''${NIRI_SOCKET:-}" ]; then
      for sock in /run/user/''$uid/niri*.sock; do
        [ -S "''$sock" ] && { NIRI_SOCKET="''$sock"; break; }
      done
    fi
    [ -z "''${NIRI_SOCKET:-}" ] && exit 0
    export NIRI_SOCKET

    # 遍历所有电源设备，任一处于 Discharging 即认为使用电池
    on_battery=false
    for status in /sys/class/power_supply/*/status; do
      if [ -r "''$status" ] && [ "$(cat "''$status")" = "Discharging" ]; then
        on_battery=true
        break
      fi
    done

    # The active output is the one with a logical mapping (a disabled output has
    # none), so no connector is hardcoded.
    output=$(${niri} msg --json outputs | ${jq} -r '
      to_entries | map(select(.value.logical != null)) | .[0].key // empty
    ')
    [ -n "$output" ] || exit 0

    # Pick the 1920x1080 mode whose refresh is closest to the target. niri needs
    # the exact mode string while its IPC reports refresh in millihertz, so
    # format it back to Hz here.
    pick_mode() {
      ${niri} msg --json outputs | ${jq} -r --arg o "$output" --argjson hz "$1" '
        (.[$o].modes
          | map(select(.width == 1920 and .height == 1080))
          | sort_by(((.refresh_rate / 1000) - $hz) | if . < 0 then -. else . end)
          | .[0]) as $best
        | if $best == null then empty
          else "\($best.width)x\($best.height)@\($best.refresh_rate / 1000)" end
      '
    }

    # 电池档：60% 亮度 + 60Hz；交流档：100% + 144Hz（目标刷新率取模式表中数值最接近者）
    if [ "$on_battery" = true ]; then
      brightnessctl set 60%
      mode=$(pick_mode 60)
    else
      brightnessctl set 100%
      mode=$(pick_mode 144)
    fi
    [ -n "$mode" ] && [ "$mode" != "null" ] && ${niri} msg output "$output" mode "$mode"
  '';
in
{
  # 安装脚本与 brightnessctl，供上述链路调用
  environment.systemPackages = [
    power-profile
    pkgs.brightnessctl
  ];

  # --- Screen power profile ---
  # udev must return promptly: queue work in systemd rather than running
  # compositor IPC and display changes in the device event worker.
  systemd.services.niri-display-power = {
    description = "Apply Niri display power profile";
    serviceConfig = {
      Type = "oneshot";
      User = username;  # 以目标用户身份运行，才能访问其 niri IPC 套接字
      ExecStart = "${power-profile}/bin/power-profile";
    };
  };
  # 电源适配器插（online=1）拔（online=0）都触发；--no-block 让 systemd 入队即返回，不阻塞 udev 事件处理
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl --no-block start niri-display-power.service"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl --no-block start niri-display-power.service"
  '';
}
