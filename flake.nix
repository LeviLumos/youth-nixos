{
  description = "youth | NixOS + niri + dotfiles";

  # ---------------------------------------------------------------------------
  # 输入（inputs）
  # ---------------------------------------------------------------------------
  inputs = {
    # NixOS 26.05：与 vars.stateVersion 保持一致
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # home-manager：必须跟随 nixpkgs，否则会出现 glibc/库版本不匹配
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 国内加速 GitHub 访问（GitHub520 的 hosts 文件），非 flake
    github-hosts = {
      url = "github:521xueweihan/GitHub520";
      flake = false;
    };

    # zen-browser 未进入 nixpkgs 26.05，使用社区 flake 提供（已确认保留该 input）
    # 若后续 nixpkgs 内置 zen-browser，可直接改用 pkgs.zen-browser（见 modules/home/packages.nix 注释）
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 水杉输入法（MSIME）：https://msime.app/ —— 提供 fcitx5 插件 overlay
    msime = {
      url = "github:metasequoiaime/msime";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ---------------------------------------------------------------------------
  # 输出（outputs）
  # ---------------------------------------------------------------------------
  outputs =
    { self
    , nixpkgs
    , home-manager
    , github-hosts
    , zen-browser
    , msime
    , ...
    } @ inputs:
    let
      # 全局变量：所有配置（hostname / username / 主题 / 字体 / 键位…）都从这里派生
      vars = import ./vars.nix;
      system = vars.system;
    in
    {
      # nixosConfigurations 的名字 = vars.hostname
      # 因此 `nixos-rebuild switch --flake .` 可以不带 #名字
      nixosConfigurations.${vars.hostname} = nixpkgs.lib.nixosSystem {
        inherit system;

        # 传给所有 NixOS 模块的额外参数
        specialArgs = {
          inherit inputs vars github-hosts zen-browser msime;
        };

        modules = [
          ./hosts/${vars.hostname}/default.nix
          home-manager.nixosModules.home-manager
        ];
      };
    };
}
