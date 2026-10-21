# inventory.nix —— 主机清单：全仓库唯一的“机器注册表”，声明存在哪些主机
# 及其构建参数。
# 由 flake.nix 的 hosts = import ./hosts/inventory.nix 导入，经 concatMapAttrs
#   遍历：每个键名生成 nixosConfigurations.<键名>（走 mkHost，主机名即键名）
#   和 homeConfigurations.<键名>。
# 注意：安装哪些 home 模块不在这里决定，而是由 home/modules-enables.nix
#   的开关板（每个模块一个布尔值）决定。
# --- hosts ---
# Device registry: the single place that declares which machines exist and how
# each builds.
#
#   system = nixpkgs system to build for.
#
# Which home modules are installed is NOT decided here but in the user-layer
# switchboard, home/modules-enables.nix (one boolean per module).
{
  koru = {
    system = "x86_64-linux";  # nixpkgs 的构建目标架构，mkHost 会用它设置 nixosSystem 的 system
  };
}
