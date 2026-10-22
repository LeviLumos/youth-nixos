# =============================================================================
#  主机配置（host）：ego
# -----------------------------------------------------------------------------
#  ⚠️ 该目录名与 vars.hostname 绑定（flake.nix 中是 ./hosts/${vars.hostname}）。
#     改主机名的完整步骤：
#       1. 修改 vars.nix 里的 hostname
#       2. git mv hosts/ego hosts/<新主机名>
#     （其余所有地方都会自动跟着变）
#
#  关于 hardware-configuration.nix：
#    仓库【不再内置】硬件配置（含磁盘 UUID、文件系统、机型相关内核模块）。
#    请在目标机器上生成后放到本目录，它会被自动引入：
#      sudo nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix
#    全新安装时（安装环境里）：
#      nixos-generate-config --root /mnt
#      cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos-youth/hosts/<hostname>/
# =============================================================================
{ lib, vars, ... }:
let
  hasHardwareConfig = builtins.pathExists ./hardware-configuration.nix;
in
{
  imports =
    [ ../../modules/nixos/default.nix ]
    # 硬件配置存在时自动引入，不存在也不报错（由下面的 assertions 给出提示）
    ++ lib.optional hasHardwareConfig ./hardware-configuration.nix;

  # 缺少硬件配置时给出明确提示，而不是让用户在 fileSystems 断言里迷茫
  assertions = [{
    assertion = hasHardwareConfig;
    message = ''
      缺少硬件配置文件：hosts/${vars.hostname}/hardware-configuration.nix

      请在本机执行（已装好系统）：
        sudo nixos-generate-config --show-hardware-config > hosts/${vars.hostname}/hardware-configuration.nix
      全新安装时（安装环境里）：
        nixos-generate-config --root /mnt
        cp /mnt/etc/nixos/hardware-configuration.nix <本仓库>/hosts/${vars.hostname}/

      注意：该文件要被 git 跟踪（flake 只会拷贝 git 已跟踪的文件），
      否则 --flake . 读不到它。
    '';
  }];

  # ---- 引导 -----------------------------------------------------------------
  #  vars.boot.loader = "uefi"  → systemd-boot（UEFI）
  #  vars.boot.loader = "grub"  → GRUB（BIOS/MBR 或想用 GRUB）
  boot.loader.systemd-boot = lib.mkIf (vars.boot.loader == "uefi") {
    enable = true;
  };

  boot.loader.grub = lib.mkIf (vars.boot.loader == "grub") {
    enable = true;
    device = "nodev";                     # UEFI；BIOS/MBR 改成 "/dev/sda" 之类的磁盘
    efiSupport = vars.boot.efi;
    useOSProber = true;                   # 双系统时探测 Windows
  };

  boot.loader.efi.canTouchEfiVariables = vars.boot.efi;
}
