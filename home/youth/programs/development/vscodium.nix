# ============================================================================
# home/youth/programs/development/vscodium.nix —— VSCodium
# ----------------------------------------------------------------------------
# VSCodium 是 VS Code 的完全开源构建版本：功能一致，但移除了微软的
# 遥测（telemetry）与专有组件，且使用 MIT 许可证，不需要 allowUnfree。
#
# 关于 mutableExtensionsDir：
#   设为 true 后，扩展目录变为可写（~/.vscode-oss/extensions），
#   允许在图形界面中直接安装扩展。注意这会打破「配置完全由 Nix 管理」的
#   原则 —— 扩展目录变成非声明式产物，重装系统后需要重新安装。
#   若希望完全声明式，可改为 false 并使用 programs.vscodium.extensions。
#
# 与 vscode 模块的关系：
#   home-manager 的 programs.vscodium 与 programs.vscode 共用同一份
#   mkVscodeModule 实现，因此两者的选项完全一致（enable / package /
#   extensions / userSettings / keybindings / mutableExtensionsDir），
#   区别只在于包与数据目录（vscodium 用 ~/.vscode-oss，vscode 用 ~/.config/Code）。
#
# 另注：configuration.nix 中还通过环境变量 NIXOS_OZONE_WL=1 强制
#       Electron 系应用使用原生 Wayland 后端。
# ============================================================================

# 模块参数：pkgs-unstable 由 flake 注入，用于取 VSCodium 的最新版本
{pkgs-unstable, ...}: {
  programs.vscodium = {
    enable = true; # 安装 VSCodium
    mutableExtensionsDir = true; # 允许 GUI 内安装扩展（扩展目录可写）
    package = pkgs-unstable.vscodium; # 使用 unstable 通道的最新版
  };
}
