# default.nix —— system/ 目录的模块清单与聚合入口。
# 作用：显式列出本机启用的全部系统模块（按字母序导入），便于一眼盘点机器能力；
#   被 flake.nix 的 mkHost（modules += ./system/default.nix）导入。
# 不含：theme.nix 是纯数据文件，由 flake.nix 直接 import 并经 specialArgs
#   注入各模块，不属于模块 imports。
# 机制：Nix module system 的 imports 合并各模块的 option 定义与 config。
# Explicit system module inventory. theme.nix is data, passed via specialArgs.
{
  imports = [
    ./console.nix
    ./fcitx5-rime.nix
    ./firewall.nix
    ./fonts.nix
    ./github-hosts.nix
    ./gpu-screen-recorder.nix
    ./journal-limits.nix
    ./memory-zram.nix
    ./mihomo.nix
    ./network-manager.nix
    ./niri-session.nix
    ./nix-daemon.nix
    ./nix-garbage-collection.nix
    ./openssh-server.nix
    ./pipewire-audio.nix
    ./tcp-tuning.nix
    ./time-servers.nix
    ./zsh-login-shell.nix
  ];
}
