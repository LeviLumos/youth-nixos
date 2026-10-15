# ── 系统软件包 ───────────────────────────────────────────
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    clash-verge-rev
    mihomo
  ];
}
