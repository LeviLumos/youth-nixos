# ── 桌面环境：niri（Wayland 合成器）+ greetd ────────────────
{ config, pkgs, ... }:

{
  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session.command =
      "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
  };
}
