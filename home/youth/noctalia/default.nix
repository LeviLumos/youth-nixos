# ============================================================================
# home/youth/noctalia/default.nix —— Noctalia 子模块入口
# ----------------------------------------------------------------------------
# Noctalia 是基于 Quickshell 构建的桌面 Shell（状态栏 + 菜单 + 壁纸切换等），
# 风格接近 GNOME/Windows 的聚合菜单，与 Waybar 等传统状态栏可共存。
#
# 注意：其二进制缓存依赖 flake.nix 中声明的 noctalia 输入
#       （github:noctalia-dev/noctalia/cachix）。
# ============================================================================
{
  imports = [
    ./noctalia.nix # Noctalia 桌面 Shell 本身
  ];
}
