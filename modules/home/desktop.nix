# =============================================================================
#  桌面配套：壁纸 / 锁屏 / 通知 / 托盘 / 空闲行为
# -----------------------------------------------------------------------------
#  状态栏 —— 已移除（原为 waybar；如需状态栏，见 doc/系统需求.md「状态栏」一节）
#  壁纸   swaybg   —— niri 启动时拉起（spawn-sh-at-startup）
#  锁屏   swaylock —— super+alt+l；空闲自动锁屏由下面的 swayidle 负责
#  通知   mako     —— 本模块的 systemd 用户服务
#  托盘   tray-tui —— super+shift+t 在 kitty 里打开
#  空闲   swayidle —— 自动锁屏 / 关屏 / 挂起 / 休眠（vars.desktop.* + vars.power.*）
# =============================================================================
{ lib, pkgs, vars, ... }:
let
  # ⚠️ swayidle 的 systemd 服务把 PATH 设成了「只有 bash」，
  #    所以下面所有命令都必须写【绝对路径】，否则会 command not found。
  #  锁屏命令：-f 必须带上，否则 swayidle 触发时会阻塞
  lockCmd = "${lib.getExe pkgs.${vars.desktop.locker}} -f";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  niri = lib.getExe pkgs.niri;

  d = vars.desktop;
  p = vars.power;

  idleEnabled =
    d.lockAfter > 0 || d.screenOffAfter > 0 || p.suspendAfter > 0 || p.hibernateAfter > 0;
in
{
  # ---- 通知守护进程 ---------------------------------------------------------
  services.mako = {
    enable = true;
    settings = {
      font = "${vars.fonts.mono.family} ${toString vars.fonts.mono.size}";
      background-color = vars.theme.background;
      text-color = vars.theme.foreground;
      border-color = vars.theme.accent;
      border-size = "2";
      # 需求：无圆角
      border-radius = "0";
      default-timeout = "5000";
      anchor = "top-right";
      width = "320";
      height = "120";
      padding = "12";
      margin = "12";
      # 进度条
      progress-color = vars.theme.accent;
    };
  };

  # ---- 空闲行为：自动锁屏 / 关屏 / 挂起 / 休眠 --------------------------------
  #  查看状态：systemctl --user status swayidle
  services.swayidle = {
    enable = idleEnabled;

    # 26.05 起：systemdTarget → systemdTargets（列表）
    systemdTargets = [ "graphical-session.target" ];

    timeouts =
      lib.optional (d.lockAfter > 0) {
        timeout = d.lockAfter;
        command = lockCmd;
      }
      ++ lib.optional (d.screenOffAfter > 0) {
        timeout = d.screenOffAfter;
        command = "${niri} msg action power-off-monitors";
        resumeCommand = "${niri} msg action power-on-monitors";
      }
      ++ lib.optional (p.suspendAfter > 0) {
        timeout = p.suspendAfter;
        command = "${systemctl} suspend";
      }
      ++ lib.optional (p.hibernateAfter > 0) {
        timeout = p.hibernateAfter;
        command = "${systemctl} hibernate";
      };

    # 26.05 起：events 由「列表」改成「以事件名为键的属性集」
    #  可选键：before-sleep / after-resume / lock / unlock
    #  进入睡眠/休眠之前先锁屏，醒来必须输密码
    events = {
      "before-sleep" = lockCmd;
    };
  };

  # ---- 终端托盘 -------------------------------------------------------------
  home.file.".config/tray-tui/config.toml".source =
    pkgs.replaceVars ../../dotfiles/tray-tui/config.toml {
      foreground = vars.theme.foreground;
      accent = vars.theme.accent;
    };
}
