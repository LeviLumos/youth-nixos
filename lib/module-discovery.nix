# module-discovery.nix —— Home 模块自动发现工具：扫描目录下的直接子级 .nix
# 文件，供 home/default.nix 构建模块选择表——开关板 home/modules-enables.nix
# 必须与目录内容一一对应（双向断言）。
# 嵌套的“功能辅助”模块（如 home/niri/）由所属模块自行 import，不参与发现。
# 注意 rec：nixModules 依赖 nixFiles。
# Discover direct-child Nix modules for the Home Manager selection table.
# Nested feature helpers are imported by their owning module, not discovered.
{ lib }:
rec {
  # *.nix files directly in `dir`, as paths, sorted by name.  # builtins.readDir 列目录，filterAttrs 只留普通文件且 .nix 后缀
  nixFiles =
    dir:
    map (n: dir + "/${n}") (
      builtins.attrNames (
        lib.filterAttrs (n: type: type == "regular" && lib.hasSuffix ".nix" n) (builtins.readDir dir)
      )
    );

  # Same, keyed by module name (the filename without its .nix suffix).  # 键 = 去 .nix 后缀的文件名，即 modules-enables.nix 中的开关名；值 = 模块路径
  nixModules =
    dir:
    lib.listToAttrs (
      map (p: lib.nameValuePair (lib.removeSuffix ".nix" (baseNameOf p)) p) (nixFiles dir)
    );

}
