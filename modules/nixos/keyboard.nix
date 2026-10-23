# =============================================================================
#  键盘重映射：Alt + h/j/k/l → 方向键（左/下/上/右）
# -----------------------------------------------------------------------------
#  为什么不用 XKB：
#    XKB 只能做「整键换键」（caps:super、caps:escape 这类），
#    做不到「按住修饰键 + h 输出方向键」这种组合层映射。
#    所以这里用 keyd —— 工作在 evdev 层（比 XKB/Wayland 更底层），
#    对 niri(XWayland 也一样)、TTY 全部生效。
#
#  语义（overload）：
#    轻点 Alt        → 还是 Alt（Firefox/GTK 的 Alt+F 菜单等照旧）
#    按住 Alt + h    → 左方向键（文本光标左移）
#    按住 Alt + j/k/l→ 下 / 上 / 右
#
#  ⚠️ 副作用：按住 Alt 时，未在 arrows 层里定义的键会「不带 Alt」发出。
#     例如 Alt+F4 会变成 F4、Alt+Tab 会变成 Tab。
#     需要保留哪个组合，就在 arrows 层里显式写一条（见下方注释）。
#
#  调试：
#    keyd -m              # 实时看按键被映射成什么
#    journalctl -u keyd   # 服务日志（配置写错会在这里报）
#  文档：https://github.com/rvaiya/keyd
# =============================================================================
{ lib, pkgs, vars, ... }:
let
  enabled = vars.keyboard.altHjklArrows;
  holdKey = vars.keyboard.altHjklArrowsKey;      # "leftalt" / "rightalt"
in
{
  services.keyd = lib.mkIf enabled {
    enable = true;

    keyboards.default = {
      # 对所有键盘生效；只想对某一块键盘生效就换成它的 id（keyd -m / keyd list-ids 可查）
      ids = [ "*" ];

      settings = {
        # 主层：把 Alt 变成「轻点=Alt / 按住=arrows 层」
        main = {
          ${holdKey} = "overload(arrows, ${holdKey})";
        };

        # arrows 层：vim 风格的 hjkl
        arrows = {
          h = "left";
          j = "down";
          k = "up";
          l = "right";
          # 想保留某些 Alt 组合，在这里补（按住 Alt 时它们会被映射成 Alt+键）：
          # tab = "leftalt+tab";
          # f4  = "leftalt+f4";
          # 想让 Alt+方向键 = 按词/按行跳（编辑器里通常是 Ctrl+方向键）：
          # left  = "leftcontrol+left";
          # right = "leftcontrol+right";
        };
      };
    };
  };

  # keyd.service 自带二进制，但默认不在 PATH；装上方便 keyd -m 调试
  environment.systemPackages = lib.mkIf enabled [ pkgs.keyd ];
}
