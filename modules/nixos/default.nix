# 系统级模块的统一入口（在 hosts/<hostname>/default.nix 中被 import）
{ ... }:
{
  imports = [
    ./system.nix          # 版本 / 区域 / nix 设置 / 中科大源 / 允许 unfree
    ./network.nix         # 主机名 / NetworkManager / GitHub520 hosts
    ./graphics.nix        # 显卡（AMD 核显，由 vars.graphics.gpu 选择）
    ./desktop.nix         # niri + Wayland 支撑 + 字体 + swaylock PAM + 可选 greetd
    # ./input-method.nix    # 输入法（默认关闭；启用步骤见 vars.inputMethod 与 doc/系统需求.md）
    ./bluetooth.nix       # 蓝牙（由 vars.hardware.bluetooth 开关）
    ./printing.nix        # 打印 CUPS + 扫描 SANE（由 vars.hardware.* 开关）
    ./power.nix           # 电源管理 / 合盖 / 挂起 / 休眠（由 vars.power.* 开关）
    ./packages.nix        # 全局软件包：wget / curl / git / vim + sshd
    ./user.nix            # 用户 youth 的创建
    ./home-manager.nix    # 挂载 home-manager（用户级配置 + dotfiles）
  ];
}
