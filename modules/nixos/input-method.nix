# =============================================================================
#  输入法：水杉输入法（MSIME） https://msime.app/
# -----------------------------------------------------------------------------
#  ⚠️ 本模块【默认不启用】：modules/nixos/default.nix 里已注释掉 import。
#     启用需要三步：
#       1. flake.nix      —— 取消 msime input 的注释（并加回 outputs 参数与 specialArgs）
#       2. default.nix    —— 取消 ./input-method.nix 的注释
#       3. vars.nix       —— inputMethod.enable = true
#     启用后首次使用必做（每个用户跑一次，下载约 189MB 词库）：
#       msime-linux-setup --download
#     之后用 fcitx5-configtool 添加「水杉输入法」；升级后 fcitx5 -r 或重新登录。
#
#  ⚠️ NixOS 上官方目前只接了 Fcitx5（没有设置窗口与语音输入）。
# =============================================================================
{ lib, inputs, pkgs, vars, ... }:

let
  # tryPkg：能求值就返回 [ pkg ]，否则返回 []（改名别名 / 不存在都算拿不到）
  #  ⚠️ Nix 的 && 两边都必须是布尔值，所以这里只能用 if，不能写 p != null && ...
  tryPkg = p: if p == null then [ ] else lib.optional (builtins.tryEval p).success p;
in
{
  # 注入 msime-fcitx5 包（来自 github:metasequoiaime/msime 的 overlay）
  nixpkgs.overlays = [ inputs.msime.overlays.default ];

  i18n.inputMethod = lib.mkIf vars.inputMethod.enable {
    enable = true;
    type = vars.inputMethod.framework;         # "fcitx5"
    fcitx5.addons = [
      pkgs.msime-fcitx5
      # 想保留其它中文输入方案可再加，例如：
      # pkgs.fcitx5-rime
    ];
  };

  # 首次配置与日常管理用到的工具。
  #  ⚠️ 有些包在 nixpkgs 里被改名/挪位置（如 fcitx5-configtool 在 26.05 挪进了
  #     qt6Packages，顶层属性变成一碰就 throw 的「改名别名」），所以这里用
  #     tryEval 探测：拿到就装、拿不到就跳过，绝不因此让整个求值失败。
  environment.systemPackages = lib.mkIf vars.inputMethod.enable ([
    pkgs.msime-fcitx5
  ]
  ++ tryPkg (pkgs.qt6Packages.fcitx5-configtool or null)   # 图形界面添加输入法
  ++ tryPkg (pkgs.msime-linux-setup or null)               # --download 下载词库
  ++ tryPkg (pkgs.fcitx5-gtk or null));                    # GTK 程序的 IM 模块

  # 说明：GTK_IM_MODULE / QT_IM_MODULE / XMODIFIERS 三个环境变量
  #       由 i18n.inputMethod 自动设置，这里【不要再重复定义】，否则会冲突报错。
  #       fcitx5 通过 XDG autostart 启动，niri-session 支持该机制，无需手动拉起。
}
