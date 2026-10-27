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
#
#  ⚠️ 26.05 把 fcitx5 系列包挪进了 `qt6Packages`，顶层 `pkgs.fcitx5-*` 变成
#     「改名别名」——属性存在，但一求值就 throw（报错形如
#     "'fcitx5-chinese-addons' has been renamed to/replaced by 'qt6Packages.…'"）。
#     所以这里统一用 getPkg：先取 qt6Packages 下的，取不到再用 tryEval 试顶层。
# =============================================================================
{ lib, pkgs, vars, ... }:

let
  # getPkg：优先 qt6Packages.<name>；没有则用 tryEval 试探顶层 pkgs.<name>
  #         （改名别名会 throw，tryEval 能兜住，返回 null 表示拿不到）
  getPkg = name:
    let
      qt6 = (pkgs.qt6Packages or { }).${name} or null;
      tried = builtins.tryEval (pkgs.${name} or null);
    in
    if qt6 != null then qt6 else if tried.success then tried.value else null;

  rime = getPkg "fcitx5-rime";                   # 中州韵 Rime（雾凇拼音/双拼的载体）
  chineseAddons = getPkg "fcitx5-chinese-addons"; # libpinyin 等备选方案（可缺）
  configtool = getPkg "fcitx5-configtool";        # 图形界面管理输入法列表（可缺）
in
{
  i18n.inputMethod = lib.mkIf vars.inputMethod.enable {
    enable = true;
    type = vars.inputMethod.framework;                 # "fcitx5"

    fcitx5.addons =
      if rime == null then
        throw "找不到 fcitx5-rime：nixpkgs 又挪位置了，改 modules/nixos/input-method.nix 的 getPkg"
      else
        [ rime ] ++ lib.optional (chineseAddons != null) chineseAddons;
  };

  # 图形界面管理输入法列表（启动器里搜 Fcitx 配置）
  environment.systemPackages = lib.mkIf vars.inputMethod.enable
    (lib.optional (configtool != null) configtool);

  # 说明：GTK_IM_MODULE / QT_IM_MODULE / XMODIFIERS 三个环境变量
  #       由 i18n.inputMethod 自动设置，这里【不要再重复定义】，否则会冲突报错。
  #       fcitx5 通过 XDG autostart 启动，niri-session 支持该机制，无需手动拉起。
}
