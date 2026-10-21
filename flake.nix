# ============================================================================
# flake.nix —— NixOS 配置仓库的入口声明文件
# ----------------------------------------------------------------------------
# 作用：
#   1. 声明本配置所依赖的全部外部输入（inputs），即各个 GitHub 仓库的版本；
#   2. 通过 nixConfig 声明二进制缓存加速源（ substituter ），避免本地编译；
#   3. 组装 NixOS 系统配置 `nixosConfigurations.levi` ，并在系统层挂载
#      home-manager，使 `home/youth` 下的用户级声明（程序、主题、键位等）生效。
#
# 使用方式：
#   查看可用的 flake 输出      nix flake show
#   构建系统并切换            nixos-rebuild switch --flake .#levi   （需 root）
#   仅构建不切换（dry-run）    nixos-rebuild build --flake .#levi
#   进入开发 Shell             nix develop
#
# 依赖关系说明：
#   nixpkgs 是所有其他输入的公共基座，因此这里让 home-manager、CookNixvim
#   都 `follows = "nixpkgs"` ，保证整个系统使用同一份 nixpkgs，避免出现
#   同一软件被编译出多份不同 store 路径的问题。
# ============================================================================
{
  # 仓库描述，仅用于 `nix flake metadata` 等信息展示
  description = "Levi configuration";

  # --------------------------------------------------------------------------
  # nixConfig：把以下设置写入本机 /etc/nix/nix.conf （对所有用户生效）
  # --------------------------------------------------------------------------
  nixConfig = {
    # 额外的二进制缓存源：Noctalia（Quickshell 实现的 Wayland 桌面 Shell）
    # 的预编译产物，避免本地从头编译整个桌面环境
    extra-substituters = ["https://noctalia.cachix.org"];

    # 与上面缓存源配套的信任公钥，防止 Nix 拒绝下载被篡改的二进制
    extra-trusted-public-keys = ["noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="];

    # 全局生效的缓存源与信任公钥（会覆盖系统默认值）
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  # --------------------------------------------------------------------------
  # inputs：所有外部依赖
  # --------------------------------------------------------------------------
  inputs = {
    # 系统基础包集，锁定到稳定分支；绝大多数包都来自这里
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";

    # 不稳定包集：用于需要最新版本软件的场景，通过 pkgs-unstable 引用
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # age 加密密钥管理工具：用于解密 ./secrets/*.age 加密文件
    # 【已禁用】当前不需要加解密流程，本仓库中所有 agenix 相关引用均已注释：
    #   - 此处的 input 声明
    #   - outputs 形参中的 agenix
    #   - 下方的 agenix.nixosModules.default / agenix.homeManagerModules.default
    #   - agenix 命令行工具的安装
    #   - configuration.nix 中的 age.identityPaths / age.secrets
    #   - modules/systemd.nix（env-loader 服务，依赖 age.secrets）
    # 恢复时请把上述几处一并取消注释，否则会因缺少模块或缺少 input 而构建失败。
    # agenix.url = "github:ryantm/agenix";

    # Noctalia 桌面 Shell 的缓存源（Quickshell + Zig 构建，故需自建缓存）
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    # Zen Browser（Firefox 的开源替代）：未收录进 nixpkgs，由该 flake 提供
    # 暴露 packages.<system>.{beta,twilight,twilight-official}，其中 default = beta
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      # 复用下面的 nixpkgs，避免同一软件出现两份 store 路径
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # CookNixvim 配置完整版：一站式 Neovim 配置包，home.packages 直接取其默认包
    CookNixvim = {
      url = "github:Youthdreamer/CookNixvim";
      # 复用上面的 nixpkgs，避免重复拉取
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # BiliBili 直播弹幕终端客户端（TUI），同样以包形式提供
    bili-danmaku-tui.url = "github:Youthdreamer/bili-danmaku-tui";

    # Catppuccin 配色方案（提供 NixOS 模块与 home-manager 模块两种形态）
    catppuccin.url = "github:catppuccin/nix/release-26.05";

    # home-manager：以模块方式嵌入 NixOS，实现声明式的用户级配置
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # --------------------------------------------------------------------------
  # outputs：对外暴露的 flake 输出
  #   形参中逐个列出 inputs 只是为了在下面方便引用（等价于 inputs.x）
  # --------------------------------------------------------------------------
  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    CookNixvim,
    bili-danmaku-tui,
    # agenix, # 【已禁用】见 inputs 中 agenix 处的说明
    catppuccin,
    noctalia,
    ...
  } @ inputs: let
    # 当前配置的目标平台（Intel 64 位 Linux）
    system = "x86_64-linux";

    # 单独实例化一份不稳定包集，并允许非自由软件（proprietary）
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations = {
      # flake 上的系统配置名；`--flake .#levi` 中的 levi 即来源于此
      # 与 configuration.nix 中的 networking.hostName 保持一致
      levi = nixpkgs.lib.nixosSystem {
        inherit system;

        # 额外注入到每个 NixOS 模块的参数：
        #   inputs          —— 全部 flake 输入，供 modules/*.nix 引用
        #   pkgs-unstable   —— 不稳定包集实例，供个别模块使用
        specialArgs = {
          inherit inputs pkgs-unstable;
        };

        modules = [
          # 本仓库的系统级配置（手工维护）
          ./configuration.nix

          # ---- 第三方 NixOS 模块 ----
          # agenix.nixosModules.default # 密钥解密能力【已禁用】
          catppuccin.nixosModules.catppuccin # 主题
          home-manager.nixosModules.home-manager # 声明式用户配置

          # 把 agenix 命令行工具装进系统环境【已禁用】
          # {
          #   environment.systemPackages = [agenix.packages.${system}.default];
          # }

          # ---- home-manager 配置块 ----
          {
            # 直接使用系统 pkgs，避免为用户再构建一套包集
            home-manager.useGlobalPkgs = true;
            # 用户包同时安装到系统 PATH
            home-manager.useUserPackages = true;
            # 把同样的特殊参数透传给 home-manager 的各个模块
            home-manager.extraSpecialArgs = {inherit inputs pkgs-unstable;};

            # 声明用户 youth（与 configuration.nix 中的 users.users.youth 对应）
            home-manager.users.youth = {
              imports = [
                catppuccin.homeModules.catppuccin # 主题（用户级）
                # agenix.homeManagerModules.default # 密钥解密（用户级）【已禁用】
                noctalia.homeModules.default # Noctalia 桌面 Shell
                ./home/youth # 本仓库的用户级配置根目录
              ];
              # 直接安装的第三方包（不走 home.programs 声明）
              home.packages = [
                CookNixvim.packages.${system}.default
                bili-danmaku-tui.packages.${system}.default
              ];
            };
          }
        ];
      };
    };
  };
}