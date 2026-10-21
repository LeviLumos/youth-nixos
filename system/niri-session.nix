# niri-session.nix —— Niri Wayland 合成器的系统会话注册与配套守护。
# 作用：注册 Niri 会话（登录管理器可选）、启用 ydotool（无 XTest 的 Wayland
#   虚拟输入注入，用户加入 ydotool 组以访问 uinput 套接字）、安装 fuse3
#   以支撑 xdg-document-portal 的文件系统透传。
# 导入：由 system/default.nix 显式导入。
# 机制：programs.niri 安装二进制与 Wayland session 桌面条目；
#   programs.ydotool 启用 ydotoold 系统服务（/dev/uinput 权限组）。
# 依赖：桌面级细配置（键位、光标、启动项）在 home/niri.nix。
# System Niri session registration and document-portal runtime.
{ pkgs, username, ... }:
{
  programs.niri = {
    enable = true;
    useNautilus = false;
  };
  programs.ydotool.enable = true;
  users.users.${username}.extraGroups = [ "ydotool" ];

  environment.systemPackages = [ pkgs.fuse3 ];
}
