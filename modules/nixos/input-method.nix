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

  # msime-linux-setup（首次配置用）随系统安装
  environment.systemPackages = lib.mkIf vars.inputMethod.enable [
    pkgs.msime-fcitx5
  ];

  # 说明：GTK_IM_MODULE / QT_IM_MODULE / XMODIFIERS 三个环境变量
  #       由 i18n.inputMethod 自动设置，这里【不要再重复定义】，否则会冲突报错。
  #       fcitx5 通过 XDG autostart 启动，niri-session 支持该机制，无需手动拉起。
}
