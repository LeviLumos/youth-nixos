# ── 用户与 shell ─────────────────────────────────────────
{ config, pkgs, ... }:

{
  programs.zsh.enable = true;

  users.users.youth = {
    isNormalUser = true;
    description = "youth";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "root" "users" ];
  };
}
