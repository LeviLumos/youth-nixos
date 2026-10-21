# gpu-screen-recorder.nix —— 屏幕录制（gpu-screen-recorder）能力配置。
# 作用：安装录屏工具，并为 gsr-kms-server 授予 cap_sys_admin 文件能力，
#   使其无需 pkexec 即可建立 KMS 会话抓取屏幕。
# 导入：由 system/default.nix 显式导入。
# 机制：security.wrappers 生成带 capabilities 的包装程序（/run/wrappers/bin），
#   setuid=false——仅授子能力而非 root 身份。
# 依赖：Intel iGPU 的 VA-API 编码器驱动 intel-media-driver 在
#   hosts/koru/intel-graphics.nix 中安装。
# --- screencast ---
# Screen recording with gpu-screen-recorder (NVIDIA-free: uses the Intel
# iGPU's VA-API encoder via gsr-kms-server). intel-media-driver lives in
# hosts/koru/intel-graphics.nix.
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.gpu-screen-recorder ];

  # gsr-kms-server needs cap_sys_admin to control the KMS server for screen
  # recording; without it gpu-screen-recorder falls back to pkexec, which fails
  # on NixOS ("pkexec must be setuid root"), so recording dies with exit code 127.
  security.wrappers.gsr-kms-server = {
    setuid = false;
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+ep";
    source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
  };
}
