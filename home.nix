{ config, pkgs, ... }:
{
  home = {
    username = "youth";
    homeDirectory = "/home/youth";
    stateVersion = "26.05";
    packages = [ pkgs.mise pkgs.vim pkgs.fastfetch ];
  };
  programs.zsh.enable = true;
  # Declarative mise activation (replaces the manual
  # `eval "$(mise activate zsh)"` line that previously lived in ~/.zshrc)
  programs.mise.enable = true;
  programs.git = {
    enable = true;
    userName = "levilumos";
    userEmail = "v227to.me@gmail.com";
  };
  programs.firefox.enable = true;
  programs.alacritty.enable = true;
  programs.home-manager.enable = true;
}
