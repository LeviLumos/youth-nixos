# =============================================================================
#  输入法：fcitx5 + Rime（默认）/ 水杉 MSIME（可选）
# -----------------------------------------------------------------------------
#  开关：vars.inputMethod.*
#    engine = "rime"   —— nixpkgs 自带、走二进制缓存，构建不碰 GitHub（默认）
#    engine = "msime"  —— 水杉输入法 https://msime.app/：
#                          需能访问 github.com 与 raw.githubusercontent.com，
#                          且按 flake.nix 注释开启 msime input；
#                          会从源码编译一整套 Rust + npm 前端，内存/磁盘开销大
#
#  用法（装好后第一次）：fcitx5-configtool → 把「Rime」加入输入法列表 →
#                        Ctrl+Space 切换。Rime 默认方案 = 朙月拼音（luna_pinyin），
#                        想换雾凇拼音/双拼见 doc/系统需求.md 第九节。
# =============================================================================
{ lib, inputs, pkgs, vars, ... }:

let
  im = vars.inputMethod;

  # tryPkg：能求值就返回 [ pkg ]，否则返回 []（改名别名 / 不存在都算拿不到）
  #  ⚠️ Nix 的 && 两边都必须是布尔值，所以这里只能用 if，不能写 p != null && ...
  tryPkg = p: if p == null then [ ] else lib.optional (builtins.tryEval p).success p;

  isMsime = im.engine == "msime";
in
{
  # msime 的包（msime-fcitx5 / msime-linux-setup）由 msime flake 的 overlay 提供；
  # rime 用 nixpkgs 自带的包，不需要 overlay。
  # ⚠️ engine = "msime" 时必须先在 flake.nix 里开启 msime input，
  #    否则这里没有 overlay，下面取 pkgs.msime-fcitx5 会报「属性不存在」。
  nixpkgs.overlays = lib.mkIf (isMsime && inputs ? msime) [ inputs.msime.overlays.default ];

  i18n.inputMethod = lib.mkIf im.enable {
    enable = true;
    type = im.framework;                        # "fcitx5"

    fcitx5.addons =
      if isMsime
      then [ pkgs.msime-fcitx5 ]
      else [
        pkgs.fcitx5-rime                        # 中州韵 Rime（朙月拼音等）
        pkgs.fcitx5-chinese-addons              # libpinyin 等老牌方案，多一个备选
      ];
  };

  # 图形界面管理输入法列表；msime 另带词库下载工具
  environment.systemPackages = lib.mkIf im.enable (
    tryPkg (pkgs.qt6Packages.fcitx5-configtool or null)   # 26.05 挪进了 qt6Packages
    ++ lib.optionals isMsime (tryPkg (pkgs.msime-linux-setup or null))   # --download 词库
  );

  # 说明：GTK_IM_MODULE / QT_IM_MODULE / XMODIFIERS 三个环境变量
  #       由 i18n.inputMethod 自动设置，这里【不要再重复定义】，否则会冲突报错。
  #       fcitx5 通过 XDG autostart 启动，niri-session 支持该机制，无需手动拉起。
}
