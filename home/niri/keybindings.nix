# keybindings.nix —— Niri 键位绑定表：纯数据文件（返回 attrset），
# 不是 home-manager 模块。
# 角色与引用：唯一引用者是 home/niri.nix——以
#   binds = import ./niri/keybindings.nix { ... } 内联导入，
#   传入 lib / pkgs / modifier(Alt) / menu(wmenu-frecency) / brightnessctl /
#   enabled（home/modules-enables.nix 的软件开关表）。
# 依赖/数据流：部分键位指向其他 home/ 模块的产物（kitty、zen-browser、imv、
#   cliphist-pick（home/clipboard-history.nix）、satty、swaylock 等），
#   是否生效由 optionalBindings + enabled.enable.* 过滤决定；
#   Alt+c 调用 scripts/koru 的 koru click toggle，间接启停 auto-click.nix 的
#   koru-click.service。
# Niri keyboard bindings; pure settings data, not a Home Manager module.
{
  lib,
  pkgs,
  modifier,
  menu,
  brightnessctl,
  enabled,
}:
let
  # 可选键位表：对应软件是可选模块，仅当 enabled.enable.<名> 为 true 才保留键位
  optionalBindings = {
    "${modifier}+Return" = "kitty";
    "${modifier}+l" = "zen-browser";
    "${modifier}+i" = "imv";
    "${modifier}+v" = "clipboard-history";
    "${modifier}+s" = "satty";
    "${modifier}+Shift+s" = "satty";
  };
in
# 过滤：默认键位全保留；与 optionalBindings 重名的键位，要求对应模块已启用
lib.filterAttrs
  (name: _: !(optionalBindings ? ${name}) || (enabled.enable.${optionalBindings.${name}} or false))
  {
    # Launch
    # 启动终端 kitty
    "${modifier}+Return" = {
      spawn = [ "kitty" ];
    };
    # 启动 Zen 浏览器（实际包名为 zen-beta）
    "${modifier}+l" = {
      spawn = [ "zen-beta" ];
    };
    # 打开应用启动菜单（wmenu-frecency，见 application-launcher.nix）
    "${modifier}+d" = {
      spawn = [ menu ];
    };
    # imv 打开图片目录；spawn-sh 走 shell 以展开 $HOME
    # Image viewer on the Pictures folder (theme/config in home/imv.nix).
    # spawn-sh so $HOME expands; the rest of imv is driven from its own keys.
    "${modifier}+i" = {
      spawn-sh = "imv \"$HOME/Pictures\"";
    };

    # 切换自动连点器（koru click toggle → koru-click.service）；repeat=false 防长按连发
    # Toggle once per key press, including while stopping an active clicker.
    "${modifier}+c" = {
      _props.repeat = false;
      spawn = [
        "koru"
        "click"
        "toggle"
      ];
    };

    # Window control
    # 关闭当前窗口
    "${modifier}+q" = {
      close-window = { };
    };
    # 退出 niri 会话
    "${modifier}+Shift+e" = {
      quit = { };
    };
    # 全屏切换当前窗口
    "${modifier}+f" = {
      fullscreen-window = { };
    };
    # 拉宽当前列到可用宽度（保留缝隙与边框）；Alt+r / Alt+减号可撤销
    # Widen the column to the available width without going fullscreen
    # (gaps and border stay). Undo with Alt+r/Alt+minus.
    "${modifier}+Shift+f" = {
      expand-column-to-available-width = { };
    };

    # 打开/关闭总览；repeat=false 防长按闪烁
    # Overview: the same thing the top-left hot corner opens. repeat=false
    # so holding the key doesn't flicker it. While it is open the focus-*
    # binds below move the viewport, and this bind closes it again. Tab is
    # niri's unbound default slot, so this overrides no built-in bind.
    "${modifier}+Tab" = {
      _props.repeat = false;
      toggle-overview = { };
    };

    # Session control
    # 锁屏（swaylock 的 PAM 服务由系统层提供）
    # Lock the session. swaylock's PAM service is provided by niri's
    # wayland-session.nix, so no system change is needed.
    "${modifier}+Shift+l" = {
      spawn = [ (lib.getExe pkgs.swaylock) ];
    };
    # 重启系统
    "${modifier}+Shift+r" = {
      spawn = [
        "systemctl"
        "reboot"
      ];
    };
    # 关机
    "${modifier}+Shift+t" = {
      spawn = [
        "systemctl"
        "poweroff"
      ];
    };

    # 左右切列、上下切列内窗口（niri 滚动布局）
    # Focus movement: left/right move between columns, up/down between
    # windows in a column (niri's scrolling layout).
    "${modifier}+Left" = {
      focus-column-left = { };
    };
    "${modifier}+Right" = {
      focus-column-right = { };
    };
    "${modifier}+Up" = {
      focus-window-up = { };
    };
    "${modifier}+Down" = {
      focus-window-down = { };
    };

    # Shift+方向键：把焦点窗口/列移向对应邻居
    # Move the focused window/column towards that neighbour.
    "${modifier}+Shift+Left" = {
      move-column-left = { };
    };
    "${modifier}+Shift+Right" = {
      move-column-right = { };
    };
    "${modifier}+Shift+Up" = {
      move-window-up = { };
    };
    "${modifier}+Shift+Down" = {
      move-window-down = { };
    };

    # Fine width/height adjustments (was 10px in sway; percentages scale).
    # 列宽 +10%
    "${modifier}+equal" = {
      set-column-width = "+10%";
    };
    # 列宽 -10%
    "${modifier}+minus" = {
      set-column-width = "-10%";
    };
    # 窗口高 +10%
    "${modifier}+Shift+equal" = {
      set-window-height = "+10%";
    };
    # 窗口高 -10%
    "${modifier}+Shift+minus" = {
      set-window-height = "-10%";
    };

    # 循环预设列宽（与 niri.nix 的 preset-column-widths 顺序一致）
    # Cycle the preset column widths (1/2 -> 1/4 -> 3/4).
    "${modifier}+r" = {
      switch-preset-column-width = { };
    };

    # Workspaces: switch + move. "scratch" is slot 0 (named workspace
    # above), so the numbered workspaces sit at positions 2..10.
    # 切到 scratch 工作区（命名工作区占位置 1，见下）
    "${modifier}+0" = {
      focus-workspace = "scratch";
    };
    # 数字键 1-9 对应编号工作区 2-10（位置 1 被 scratch 占用）
    "${modifier}+1" = {
      focus-workspace = 2;
    };
    "${modifier}+2" = {
      focus-workspace = 3;
    };
    "${modifier}+3" = {
      focus-workspace = 4;
    };
    "${modifier}+4" = {
      focus-workspace = 5;
    };
    "${modifier}+5" = {
      focus-workspace = 6;
    };
    "${modifier}+6" = {
      focus-workspace = 7;
    };
    "${modifier}+7" = {
      focus-workspace = 8;
    };
    "${modifier}+8" = {
      focus-workspace = 9;
    };
    "${modifier}+9" = {
      focus-workspace = 10;
    };
    # Shift+数字：把当前列移到对应工作区
    "${modifier}+Shift+0" = {
      move-column-to-workspace = "scratch";
    };
    "${modifier}+Shift+1" = {
      move-column-to-workspace = 2;
    };
    "${modifier}+Shift+2" = {
      move-column-to-workspace = 3;
    };
    "${modifier}+Shift+3" = {
      move-column-to-workspace = 4;
    };
    "${modifier}+Shift+4" = {
      move-column-to-workspace = 5;
    };
    "${modifier}+Shift+5" = {
      move-column-to-workspace = 6;
    };
    "${modifier}+Shift+6" = {
      move-column-to-workspace = 7;
    };
    "${modifier}+Shift+7" = {
      move-column-to-workspace = 8;
    };
    "${modifier}+Shift+8" = {
      move-column-to-workspace = 9;
    };
    "${modifier}+Shift+9" = {
      move-column-to-workspace = 10;
    };

    # 媒体键均设 allow-when-locked，锁屏界面仍可操作
    # Media keys (allow-when-locked so they keep working at the locker).
    "XF86AudioMute" = {
      _props.allow-when-locked = true;
      spawn = [
        "wpctl"
        "set-mute"
        "@DEFAULT_AUDIO_SINK@"
        "toggle"
      ];
    };
    # 音量 +5%
    "XF86AudioRaiseVolume" = {
      _props.allow-when-locked = true;
      spawn = [
        "wpctl"
        "set-volume"
        "@DEFAULT_AUDIO_SINK@"
        "5%+"
      ];
    };
    # 音量 -5%
    "XF86AudioLowerVolume" = {
      _props.allow-when-locked = true;
      spawn = [
        "wpctl"
        "set-volume"
        "@DEFAULT_AUDIO_SINK@"
        "5%-"
      ];
    };
    # 播放/暂停（playerctl，MPRIS）
    "XF86AudioPlay" = {
      _props.allow-when-locked = true;
      spawn = [
        "playerctl"
        "play-pause"
      ];
    };
    # 下一曲
    "XF86AudioNext" = {
      _props.allow-when-locked = true;
      spawn = [
        "playerctl"
        "next"
      ];
    };
    # 上一曲
    "XF86AudioPrev" = {
      _props.allow-when-locked = true;
      spawn = [
        "playerctl"
        "previous"
      ];
    };
    # 屏幕亮度 +5%
    "XF86MonBrightnessUp" = {
      spawn = [
        brightnessctl
        "set"
        "+5%"
      ];
    };
    # 屏幕亮度 -5%
    "XF86MonBrightnessDown" = {
      spawn = [
        brightnessctl
        "set"
        "5%-"
      ];
    };
    # 亮度后备键（该键盘媒体键不触发时使用）
    # Keyboard fallback (the media keys above don't fire on this keyboard).
    "${modifier}+F5" = {
      spawn = [
        brightnessctl
        "set"
        "5%-"
      ];
    };
    "${modifier}+F6" = {
      spawn = [
        brightnessctl
        "set"
        "+5%"
      ];
    };

    # 打开剪贴板历史选择器（cliphist-pick，定义在 home/clipboard-history.nix）
    # Clipboard history picker (history/persistence daemons and the
    # cliphist-pick script live in home/clipboard-history.nix).
    "${modifier}+v" = {
      spawn = [ "cliphist-pick" ];
    };

    # 截图送 satty 标注（配置在 home/satty.nix）；管道需要 shell，故用 spawn-sh
    # Screenshots (annotate in satty; config/theming in home/satty.nix).
    # Pipes need a shell, hence spawn-sh.
    "${modifier}+s" = {
      spawn-sh = "grim -t ppm - | satty --filename -";
    };
    # 先 slurp 选区再截图送 satty 标注
    "${modifier}+Shift+s" = {
      spawn-sh = "grim -g \"$(slurp)\" -t ppm - | satty --filename -";
    };
  }
