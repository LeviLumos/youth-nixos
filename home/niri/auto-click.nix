# auto-click.nix —— 自动连点服务的 systemd 用户单元定义（koru-click.service）。
# 是什么：为 koru 自动左键连点器提供后台 worker；worker 经 ydotool 的
#   uinput 套接字（/run/ydotoold/socket）按频率发送左键按下/抬起事件。
# 角色与引用：
#   - 被 home/niri.nix 导入；
#   - scripts/koru/click.py（经 koru.sh 包装为 koru click 命令）用
#     systemctl --user start/stop koru-click.service 启停本服务，
#     本单元的 ExecStart 以 --worker 参数运行同一脚本；
#   - 键位 Alt+c（keybindings.nix）调用 koru click toggle，间接启停本服务。
# 依赖/数据流：依赖系统层 ydotoold 守护进程及其套接字 /run/ydotoold/socket；
#   点击频率存于 ~/.config/koru/click-frequency（由 click.py 维护）；
#   生命周期绑定 graphical-session.target：随图形会话启动，会话结束自动停止。
# Started only by koru click; stop when the graphical session ends.
{ pkgs, ... }:
{
  systemd.user.services.koru-click = {
    Unit = {
    # 单元属性：仅图形会话存在时运行（After/Requisite），会话结束随之停止（PartOf）
      Description = "Koru automatic left mouse clicks";
      PartOf = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
    # 服务本体：--worker 模式只做连点循环，不做参数解析；
    # TimeoutStopSec=2 保证快速停止，并与 worker 的 SIGTERM 处理配合补发抬键事件
      ExecStart = "${pkgs.python3}/bin/python3 ${../../scripts/koru/click.py} --worker";
      Environment = "YDOTOOL_SOCKET=/run/ydotoold/socket";
      TimeoutStopSec = 2;
    };
  };
}
