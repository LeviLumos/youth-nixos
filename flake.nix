# --- flake ---
# NixOS flake: flake-parts composition + home-manager.
#
# One selection decides what the user layer installs: home/modules-enables.nix, one
# boolean per home module (the single switchboard and the inventory of what
# home/ can install). home/default.nix asserts it matches the module directory.
#
# Outputs:
#   - nixosConfigurations.<host> : full system, with home-manager embedded for
#     that host, switchboard from home/modules-enables.nix.
#   - homeConfigurations.<host>  : user layer only, switchboard as-is. Can be
#     switched at runtime (`home-manager switch --flake .#<host>`).
#   - homeConfigurations.all     : every user module forced on, evaluation
#     only, so a disabled/unsupported module cannot rot unnoticed.
#
# 【中文说明】全仓库总入口：
# 是什么 —— 用 flake-parts 组织的 NixOS + home-manager 配置 flake。
# 结构 —— hosts/inventory.nix 声明主机清单；每个主机目录（hosts/<name>/）
#   提供机器层配置，system/default.nix 提供系统服务层，home/default.nix
#   提供用户层（由 modules-enables.nix 开关板裁剪）。
# 数据流 —— theme（system/theme.nix）、username、inputs、enabled 等经
#   specialArgs / extraSpecialArgs 注入各层模块。
# 修改指引 —— 换用户名改 username；加主机改 hosts/inventory.nix 并建目录；
#   增删用户软件改 home/modules-enables.nix；主题改 system/theme.nix。
{
  # flake 描述（仅元数据，不影响求值）
  description = "NixOS configuration (flake-parts + home-manager)";

  # 输入依赖：全部由 flake.lock 锁定，普通构建不会更新锁。
  inputs = {
    # 系统主包集：nixos-unstable 通道
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # AI 编码工具 OpenCode（dev 分支），经 extraSpecialArgs.inputs 传入 home 层
    opencode = {
      url = "github:anomalyco/opencode/dev";
    };

    # flake-parts：模块化的 flake 输出组织器；
    # nixpkgs-lib 跟随主 nixpkgs，避免引入第二份 lib
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # 用户层管理框架；follows 主 nixpkgs，保证两层用同一份包源
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen browser (removed from nixpkgs; community-maintained flake:
    # https://github.com/0xc000022070/zen-browser-flake). Follows our nixpkgs
    # and home-manager; the flake assumes nixpkgs-unstable, which we are on.
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # GitHub acceleration hosts, pinned by flake.lock; refresh manually via
    # `nix flake update github-hosts` (system.autoUpgrade is disabled).
    github-hosts = {
      url = "github:521xueweihan/GitHub520";
      flake = false;
    };

  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      # 全仓库唯一的目标平台（当前仅 x86_64 笔记本）
      system = "x86_64-linux";
      # 全局用户名：主机层账号与 home 层配置共用
      username = "koru";
      # 全局主题单一数据源（纯数据），经 specialArgs 注入 system 与 home 两层
      theme = import ./system/theme.nix;

      # 主机清单（名字 → { system; ... }），驱动下方所有输出按主机生成
      hosts = import ./hosts/inventory.nix;

      # pkgs per target system: standalone home profiles and NixOS configs may
      # target different architectures once non-x86_64 hosts are added.
      # allowUnfree is repeated from system/nix-daemon.nix on purpose: standalone home
      # profiles use this separate pkgs instance (the embedded one reuses the
      # system set via useGlobalPkgs), so it must be set in both places.
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      # 用户层唯一根模块（home/default.nix 内部再做发现与校验）
      homeModules = [ ./home/default.nix ];

      # The user-layer switchboard (home/modules-enables.nix) and its forced variant:
      # `all` turns every module on so nothing can rot unnoticed.
      homeEnabled = import ./home/modules-enables.nix;
      enabledAll = homeEnabled // {
        enable = builtins.mapAttrs (_: _: true) homeEnabled.enable;
      };

      # extraSpecialArgs shared by the embedded and standalone home profiles.
      mkHomeSpecialArgs = enabled: {
        inherit
          inputs
          theme
          username
          enabled
          ;
      };

      # 构造完整 NixOS 系统：主机层目录 + 系统服务层 + 内嵌 home-manager（用户层）
      mkHost =
        name: host:
        nixpkgs.lib.nixosSystem {
          system = host.system;
          # 注入各层模块的共享参数（theme/username/inputs 与主机名）
          specialArgs = {
            inherit
              inputs
              theme
              username
              ;
            hostname = name;
          };
          modules = [
            # 机器层：硬件、引导、电源、账号（hosts/<name>/ 目录全部模块）
            ./hosts/${name}
          ]
          # 系统服务层：桌面会话、网络、音频、Nix 等（显式清单见 system/default.nix）
          ++ [ ./system/default.nix ]
          ++ [
            # 内嵌 home-manager：用户层随系统一次构建、一次切换
            inputs.home-manager.nixosModules.home-manager
            {
              # 复用系统 pkgs（含 allowUnfree），用户包进系统环境
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              # 被接管的既有配置文件备份为 *.hm-bak，而不是构建失败
              home-manager.backupFileExtension = "hm-bak";
              # 开关板按原样传入：内嵌 profile 与独立 profile 行为一致
              home-manager.extraSpecialArgs = mkHomeSpecialArgs homeEnabled;
              home-manager.users.${username} = {
                imports = homeModules;
              };
            }
          ];
        };

      # 构造独立 home profile（不嵌系统）：enabled 决定开关板按原样还是全开
      mkHome =
        enabled: host:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs host.system;
          extraSpecialArgs = mkHomeSpecialArgs enabled;
          modules = homeModules;
        };

      # Working tree for the format/lint checks (no .git or editor junk).
      src = lib.cleanSource ./.;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ system ];

      flake.nixosConfigurations = lib.concatMapAttrs (name: host: {
        "${name}" = mkHost name host;
      }) hosts;

      flake.homeConfigurations =
        lib.concatMapAttrs (name: host: {
          "${name}" = mkHome homeEnabled host;
        }) hosts
        // {
          # Evaluation-only: every home module forced on, so a module no host
          # currently imports still fails CI the day it breaks. Built through
          # the same mkHome as the real profiles, so the two cannot drift.
          all = mkHome enabledAll { inherit system; };
        };

      # 按平台提供的开发辅助：格式化器、检查用 shell 与 flake checks
      perSystem =
        { pkgs, ... }:
        {
          # nix fmt 使用的格式化器
          formatter = pkgs.nixfmt;

          # nix develop 进入的静态检查环境（CI 也用它跑 shellcheck 与测试）
          devShells.default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              deadnix
              jq
              nixfmt
              ripgrep
              shellcheck
              statix
            ];
          };

          # nix flake check 跑的全部仓库级检查（CI 的静态检查部分）
          checks = {
            # 代理生命周期 VM 集成测试（真实 sudo + TUN）
            proxy-lifecycle = import ./tests/proxyctl/vm.nix { inherit pkgs; };
            formatting =
              pkgs.runCommand "check-formatting"
                {
                  nativeBuildInputs = [ pkgs.nixfmt ];
                }
                ''
                  nixfmt --check $(find ${src} -name '*.nix' -type f)
                  touch $out
                '';

            lint =
              pkgs.runCommand "check-lint"
                {
                  nativeBuildInputs = [ pkgs.statix ];
                }
                ''
                  statix check --config ${src}/statix.toml ${src}
                  touch $out
                '';

            dead-code =
              pkgs.runCommand "check-dead-code"
                {
                  nativeBuildInputs = [ pkgs.deadnix ];
                }
                ''
                  deadnix --fail ${src}
                  touch $out
                '';
          };
        };
    };
}
