# clipboard-history.nix —— Wayland 剪贴板历史与持久化模块。
# 角色：home/ 用户层软件模块；由 enable.clipboard-history 开关控制（当前 true）。
# 引用链：flake.nix → home/default.nix → 本文件；theme 经 specialArgs 传入。
# 依赖/数据流：
#   - ../lib/wmenu-style.nix 提供与 niri 启动器一致的 wmenu 外观参数；
#   - cliphist-pick 由 home/niri/keybindings.nix 的 Alt+v 键位调用；
#   - 两个 systemd 用户服务挂在 graphical-session.target 上，由 niri 会话拉起。
# --- clipboard ---
# Clipboard history + persistence for Wayland.
#   cliphist          : stores copy history (wl-paste --watch cliphist store)
#   wl-clip-persist   : keeps the clipboard alive after the source app quits
#   cliphist-pick     : wmenu picker (Mod1+v in niri.nix) -> wl-copy
# Both daemons are systemd user services; they use the default
# graphical-session.target, which niri.service pulls in via niri-session.
{
  lib,
  pkgs,
  theme,
  ...
}:
let
  # Shared with niri.nix's launcher (lib/module-discovery.nix) so both pickers match.
  wmenu-opts = import ../lib/wmenu-style.nix { inherit lib theme; };

  cliphist-pick = pkgs.writeShellScriptBin "cliphist-pick" ''
    set -euo pipefail
    # list 列出历史 | wmenu 弹窗选择，取消/空选则静默退出
    sel=$(${lib.getExe pkgs.cliphist} list | ${lib.getExe pkgs.wmenu} ${wmenu-opts}) || exit 0
    [ -n "$sel" ] || exit 0
    # 选中行回传 cliphist decode 还原原文，再经 wl-copy 写回剪贴板
    printf '%s\n' "$sel" | ${lib.getExe pkgs.cliphist} decode | ${lib.getExe' pkgs.wl-clipboard "wl-copy"}
  '';
in
{
  home.packages = [ cliphist-pick ];

  services.cliphist = {
    enable = true;
    # Text only: the picker has no image preview and this keeps history light.
    allowImages = false;
  };

  services.wl-clip-persist = {
    enable = true;
    # 只持久化 regular 剪贴板，不动 primary 选择区
    clipboardType = "regular";
  };
}
