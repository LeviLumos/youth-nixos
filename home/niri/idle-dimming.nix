# idle-dimming.nix —— 显示器空闲调节模块：基于 swayidle 的两段式空闲策略。
# 是什么：空闲 5 分钟把背光降到最大值的约 10%（先保存当前亮度），
#   空闲共 10 分钟关闭全部显示器电源；恢复活动时先还原亮度再点亮显示器。
# 角色与引用：被 home/niri.nix 导入；swayidle 用户服务由 niri.service 拉起
#   （系统层 system/niri-session.nix 提供），随图形会话启动/停止。
# 依赖/数据流：brightnessctl（--save/--restore 读写保存的原始亮度）；
#   niri msg action power-off/on-monitors（合成器息屏/点亮动作）；无自动挂起。
# Dim idle displays, preserve manual brightness and power off idle monitors.
{ lib, pkgs, ... }:
let
  # 取绝对路径：脚本与超时命令不依赖运行时 PATH
  brightnessctl = lib.getExe pkgs.brightnessctl;
  niri = lib.getExe pkgs.niri;
  # 调暗脚本：读取并保存当前背光，再降到最大亮度的 1/10
  dim-display = pkgs.writeShellScript "dim-idle-display" ''
    set -eu
    # brightnessctl saves the raw value for this user's backlight device.
    # Restrict the device class so keyboard/indicator LEDs are never selected.
    current=$(${brightnessctl} --class=backlight --save get)
    maximum=$(${brightnessctl} --class=backlight max)
    target=$((maximum / 10))
    # 目标亮度至少为 1，避免降到 0 导致屏幕彻底不可见
    [ "$target" -ge 1 ] || target=1

    # 若用户已手动调得更暗，绝不调亮——只降不升
    # An already dim display must not become brighter on idle.
    if [ "$current" -gt "$target" ]; then
      ${brightnessctl} --class=backlight set "$target"
    fi
  '';
in
{
  # 两段超时 + resumeCommand 恢复；模块默认 -w 串行执行，保证先保存后恢复的顺序
  # Save/dim after 5 min, power off all monitors after 10 min total inactivity.
  # On activity, restore the saved brightness and turn monitors back on.
  # The module's default -w serializes commands, including save before restore.
  # This user service is bound to graphical-session.target via niri.service.
  services.swayidle = {
    enable = true;
    timeouts = [
      # 阶段一（5 分钟）：调暗；恢复活动时用 --restore 还原保存的亮度
      {
        timeout = 300;
        command = "${dim-display}";
        resumeCommand = "${brightnessctl} --class=backlight --restore";
      }
      # 阶段二（10 分钟）：关闭显示器电源；恢复活动时重新点亮
      {
        timeout = 600;
        command = "${niri} msg action power-off-monitors";
        resumeCommand = "${niri} msg action power-on-monitors";
      }
    ];
  };

}
