# =============================================================================
#  显卡：AMD 核显（amdgpu）
# -----------------------------------------------------------------------------
#  硬件相关的内核模块原本写在 hardware-configuration.nix 里；
#  本仓库不再内置该文件，因此把「AMD 核显」这部分单独抽成一个可复用模块。
#
#  换显卡只改 vars.nix：graphics.gpu = "amd" | "intel" | "nvidia" | "none"
# =============================================================================
{ lib, pkgs, vars, ... }:
let
  gpu = vars.graphics.gpu;
in
{
  # 提前加载 KMS，避免开机/唤醒时闪屏
  boot.initrd.kernelModules = lib.mkMerge [
    (lib.mkIf (gpu == "amd") [ "amdgpu" ])
    (lib.mkIf (gpu == "intel") [ "i915" ])
    (lib.mkIf (gpu == "nvidia") [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ])
  ];

  # Mesa / VA-API / VDPAU 等图形栈（AMD / Intel 都由 mesa 提供）
  hardware.graphics = {
    enable = gpu != "none";
    # 需要额外硬件编解码支持时再打开（属性名以 nix search 为准）：
    # extraPackages = with pkgs; [ mesa ];
  };

  # NVIDIA 独显需要另外的配置（按需打开）
  services.xserver.videoDrivers = lib.mkIf (gpu == "nvidia") [ "nvidia" ];

  hardware.nvidia = lib.mkIf (gpu == "nvidia") {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    nvidiaSettings = true;
    # 想指定驱动版本再打开（默认即 stable）：
    # package = pkgs.linuxPackages.nvidiaPackages.stable;
  };
}
