# intel-graphics.nix —— koru 主机核显（Intel iGPU）配置：显示、渲染与视频
# 硬解/编码全部跑在核显上；RTX 4060 独显不装驱动（nouveau 在 boot.nix 黑名单
# 中，也没有 nvidia 驱动）。
# 由 flake.nix 的 mkHost 以目录 ./hosts/koru 导入，经 default.nix 汇总生效。
# --- graphics ---
# Intel iGPU setup: the RTX 4060 dGPU is driver-less (nouveau is blacklisted
# in hosts/koru/boot.nix and no nvidia driver is installed), so display,
# render and video codec all run on the Intel iGPU with VA-API.
{ pkgs, ... }:

{
  # --- Userspace render stack ---
  # Explicit Mesa/DDX enable (already the default, kept for clarity); the i915
  # kernel driver works out of the box.
  hardware.graphics.enable = true;  # 启用 Mesa 用户态图形栈（已是默认值，写出来为明确意图）；i915 内核驱动开箱即用

  # Intel iHD VA-API driver: hardware h264/hevc/av1 decode/encode on the iGPU.
  # Without it browsers and video apps fall back to CPU decode.
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];  # iHD 后端 VA-API 驱动：核显硬解/编码 h264/hevc/av1，否则浏览器与视频应用回退 CPU 软解

  # --- Kernel ---
  # Explicitly load GuC + HuC firmware (modern kernels default to GuC only;
  # HuC is used by media workloads / VA-API).
  boot.kernelParams = [ "i915.enable_guc=3" ];  # enable_guc=3 = 位0(GuC)+位1(HuC)：GuC 负责图形提交/调度，HuC 服务媒体/VA-API；新内核默认只开 GuC，这里显式两者都开
}
