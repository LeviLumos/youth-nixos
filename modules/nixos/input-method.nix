# =============================================================================
#  输入法：fcitx5 + Rime（中州韵）
# -----------------------------------------------------------------------------
#  包全部来自 nixpkgs、走二进制缓存，**构建不碰 GitHub**（`just switch` 几秒完成）。
#
#  默认方案 = 雾凇双拼（rime-ice）：
#    - 方案选择：`dotfiles/rime/default.custom.yaml`（`modules/home/rime.nix` 部署
#      到 `~/.local/share/fcitx5/rime/`），把 schema_list patch 成 double_pinyin
#    - 词库：第一次用 `just rime-ice` 装（github.com/iDvel/rime-ice，走 git over https）
#
#  开关：vars.inputMethod.{enable,framework}
# =============================================================================
{ lib, pkgs, vars, ... }:

let
  # tryPkg：能求值就返回 [ pkg ]，否则返回 []（改名别名 / 不存在都算拿不到）
  #  ⚠️ Nix 的 && 两边都必须是布尔值，所以这里只能用 if，不能写 p != null && ...
  #  ⚠️ fcitx5-configtool 在 26.05 挪进了 qt6Packages，顶层属性是一碰就 throw 的
  #     「改名别名」，所以这里取 qt6Packages 下的那个
  tryPkg = p: if p == null then [ ] else lib.optional (builtins.tryEval p).success p;
in
{
  i18n.inputMethod = lib.mkIf vars.inputMethod.enable {
    enable = true;
    type = vars.inputMethod.framework;                 # "fcitx5"

    fcitx5.addons = [
      pkgs.fcitx5-rime                     # 中州韵 Rime（雾凇拼音/双拼的载体）
      pkgs.fcitx5-chinese-addons           # libpinyin 等备选方案，多一个选择
    ];
  };

  # 图形界面管理输入法列表（启动器里搜 Fcitx 配置）
  environment.systemPackages = lib.mkIf vars.inputMethod.enable (
    tryPkg (pkgs.qt6Packages.fcitx5-configtool or null)
  );

  # 说明：GTK_IM_MODULE / QT_IM_MODULE / XMODIFIERS 三个环境变量
  #       由 i18n.inputMethod 自动设置，这里【不要再重复定义】，否则会冲突报错。
  #       fcitx5 通过 XDG autostart 启动，niri-session 支持该机制，无需手动拉起。
}
