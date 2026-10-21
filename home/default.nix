# default.nix —— home/ 用户层入口（home-manager 总模块）。
# 角色：不是软件模块，而是入口/装配器；flake.nix 把 ./home/default.nix 作为
#   homeModules 唯一根，经 nixosSystem 内嵌与 homeManagerConfiguration
#   （homeConfigurations.<host> 输出）两条路径加载；theme、username、enabled
#   等由 flake.nix 的 specialArgs/extraSpecialArgs 传入。
# 装配逻辑：
#   - import ./modules-enables.nix 得到开关板（默认实参 enabled）；
#   - lib/module-discovery.nix 自动发现 home/ 下除控制文件（default、
#     modules-enables）外的所有 .nix 模块；
#   - 双向断言：目录里有而开关板没有（unlisted）、开关板有而目录里没有
#     （unknown）都让求值失败；开关值必须为布尔（invalidFlags）；
#   - lib/home-module-dependencies.nix 声明模块间硬依赖（fzf→[fd,zsh]、
#     tty-login→[niri,zsh]），缺依赖同样求值失败。
# 数据流：本层仅管用户配置；flake 以独立可切换的 home profile 输出暴露，
#   运行时 koru home build 即可更换，无需系统级重建。
# --- home/default ---
# Home-manager configuration for the user layer.
#
# home/modules-enables.nix is the single switchboard: one boolean per module in home/,
# which doubles as the inventory of what home/ can install. The switchboard must
# match the directory exactly (asserted below), so a flag can never point at a
# missing file and a file can never sit unlisted. This file and modules-enables.nix are
# the control files, not modules, so discovery skips them.
#
# Because this layer owns only user config, the flake exposes it as a switchable
# home profile output (<host>) so it can change at runtime without a system
# rebuild.
{
  config,
  lib,
  pkgs,
  username,
  theme,
  enabled ? import ./modules-enables.nix,  # 开关板作为默认实参，可被 specialArgs 的 enabled 覆盖
  ...
}:
let
  helpers = import ../lib/module-discovery.nix { inherit lib; };
  dependencies = import ../lib/home-module-dependencies.nix;

  control = [
    "default"
    "modules-enables"
  ];
  modules = lib.filterAttrs (n: _: !(builtins.elem n control)) (helpers.nixModules ./.);
  # 校验开关板每个键都是布尔，防止手误写成字符串
  invalidFlags = builtins.filter (n: !(builtins.isBool enabled.enable.${n})) flags;
  selected =
    assert lib.assertMsg (
      invalidFlags == [ ]
    ) "home/modules-enables.nix: flags must be booleans: ${lib.concatStringsSep ", " invalidFlags}";
    builtins.filter (n: enabled.enable.${n} or false) (builtins.attrNames modules);

  # The switchboard and the directory must agree in both directions; name each
  # mismatch so the failure says which file or flag is out of place.
  allFiles = builtins.attrNames modules;
  # 注意：flags 引用在此 let 中后置定义（Nix 递归 let），供 invalidFlags 与 drift 使用
  flags = builtins.attrNames (enabled.enable or { });
  drift =
    map (n: "unlisted ${n}") (builtins.filter (n: !(builtins.elem n flags)) allFiles)
    ++ map (n: "unknown ${n}") (builtins.filter (n: !(builtins.elem n allFiles)) flags);
  missingDependencies = lib.flatten (
    lib.mapAttrsToList (
      module: requirements:
      lib.optionals (enabled.enable.${module} or false) (
        map (requirement: "${module} requires ${requirement}") (
          builtins.filter (requirement: !(enabled.enable.${requirement} or false)) requirements
        )
      )
    ) dependencies
  );
in
{
  imports = map (n: modules.${n}) selected;

  assertions = [
    {
      assertion = drift == [ ];
      message = "home/modules-enables.nix and home/ disagree: ${lib.concatStringsSep ", " drift}";
    }
    {
      assertion = missingDependencies == [ ];
      message = "invalid Home Manager module selection: ${lib.concatStringsSep ", " missingDependencies}";
    }
  ];

  warnings =
    lib.optional (
      !(enabled.enable.niri or false)
    ) "The Niri desktop is disabled; no graphical session is configured."
    ++ lib.optional (
      !(enabled.enable.tty-login or false)
    ) "TTY login no longer starts the graphical session automatically.";

  # 用户基本信息：username 来自 flake.nix specialArgs（koru）；stateVersion 锁定迁移语义
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.11";

  # Installation is managed independently by `koru profile build`.
  home.sessionPath = [ "\${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/koru-dev/bin" ];

  programs.home-manager.enable = true;

  # The line above installs the home-manager CLI only when home-manager runs
  # standalone. Embedded via nixos-rebuild it sets submoduleSupport.enable, and
  # the module then adds nothing, so `home-manager switch` (the <host> output)
  # would be unreachable from a fresh shell. Put the CLI in the system per-user
  # profile instead; the standalone path already gets it from the flag.
  home.packages = lib.optional config.submoduleSupport.enable pkgs.home-manager ++ [
    (import ../lib/koru-package.nix {
      inherit pkgs lib theme;
      repositoryRoot = "${config.home.homeDirectory}/.config/nixos";
    })
  ];
}
