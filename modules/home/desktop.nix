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

  # 随机选一张壁纸并 exec swaybg（找不到图时用主题纯色兜底）
  #  同时把选中的图软链到 ~/Pictures/wallpaper.jpg —— swaylock 锁屏背景读它，
  #  这样锁屏永远和桌面显示同一张当前壁纸
  wallpaperRandom = pkgs.writeShellScriptBin "wallpaper-random" ''
    dir="$HOME/${vars.desktop.wallpaperDir}"
    img=$(find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | shuf -n1)
    if [ -z "$img" ]; then
      echo "壁纸池为空：$dir —— 使用主题纯色兜底" >&2
      rm -f "$HOME/Pictures/wallpaper.jpg"          # 别给 swaylock 留悬空软链
      exec ${lib.getExe pkgs.${vars.desktop.wallpaperTool}} -c '${vars.theme.background}'
    fi
    ln -sfn "$img" "$HOME/Pictures/wallpaper.jpg"
    exec ${lib.getExe pkgs.${vars.desktop.wallpaperTool}} -i "$img" --mode fill
  '';
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

  # ---- 壁纸池 + 随机轮换 -------------------------------------------------------
  #  dotfiles/wallpapers/ 部署到 ~/Pictures/wallpapers；
  #  wallpaper.service 登录时随机选一张；rotateWallpaper=true 时定时 restart 换一张
  #  （systemd 重启服务会连旧 swaybg 一起杀掉，所以不用 pkill）
  home.file."${vars.desktop.wallpaperDir}" = {
    source = ../../dotfiles/wallpapers;
    recursive = true;
  };

  # 登录起一张随机壁纸（systemd 重启本服务 = 换一张，旧 swaybg 被连进程带 cgroup 清掉）
  systemd.user.services.wallpaper = {
    Unit = {
      Description = "随机设置一张壁纸（swaybg）";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${wallpaperRandom}/bin/wallpaper-random";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  # 定时轮换：timer 触发这个 oneshot，由它 restart wallpaper.service（= 换一张）
  systemd.user.services.wallpaper-cycle = lib.mkIf vars.desktop.rotateWallpaper {
    Unit = { Description = "换一张壁纸（restart wallpaper.service）"; };
    Service = {
      Type = "oneshot";
      ExecStart = "${systemctl} --user restart wallpaper.service";
    };
  };

  systemd.user.timers.wallpaper-cycle = lib.mkIf vars.desktop.rotateWallpaper {
    Unit = { Description = "定时轮换壁纸"; };
    Timer = {
      OnCalendar = vars.desktop.rotateInterval;
      Persistent = true;
      Unit = "wallpaper-cycle.service";
    };
    Install = { WantedBy = [ "timers.target" ]; };
  };

  home.packages = [ wallpaperRandom ];

  # ---- 锁屏样式（swaylock）---------------------------------------------------
  #  原生 swaylock 零配置 = 灰底 + 大色块指示器（很丑）；这里铺桌面同款壁纸、
  #  指示器走主题色。颜色是 RRGGBB（不带 #），所以替换时把 vars 里的 # 去掉
  home.file.".config/swaylock/config".source =
    pkgs.replaceVars ../../dotfiles/swaylock/config {
      background = lib.removePrefix "#" vars.theme.background;
      foreground = lib.removePrefix "#" vars.theme.foreground;
      accent = lib.removePrefix "#" vars.theme.accent;
      fontFamily = vars.fonts.mono.family;
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
