# profile/flake.nix —— profile 独立 flake 的入口：输出
# packages.x86_64-linux.dev-tools——一个版本锁定的开发工具 bundle，
# 与系统重建（NixOS configuration）解耦。
# 数据流：inputs 锁定 nixpkgs/rust-overlay/nix-ros-overlay → default.nix
#   汇总 packages/*.nix 得到 tools → buildEnv 合并所有工具为 bundle 并写入
#   versions.json → toolchain-checks.nix + 内联 rust-version 检查验证工具链可用
#   → scripts/koru/profile.sh 以 nix profile install/upgrade 消费本 flake 输出。
# 注意：本 flake 有自己的 flake.lock，升级工具链不影响系统层的锁。
{
  description = "Version-locked development tools for the koru profile";  # flake 描述：为 koru profile 提供版本锁定的开发工具

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";  # 工具集主 nixpkgs 源（unstable 通道），由 flake.lock 锁定版本
    # Rust 官方通道覆盖层：提供 rust-bin 按精确版本安装 rustc/cargo
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";  # 复用本 flake 的 nixpkgs，避免重复下载两份源码
    };
    # Deliberately independent of our nixpkgs: ROS uses its tested package set.
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";  # ROS 专用覆盖层，刻意不跟随主 nixpkgs，保证使用 ROS 官方测试过的包集
  };

  outputs =
    {
      nixpkgs,
      rust-overlay,
      nix-ros-overlay,
      ...
    }:
    let
      system = "x86_64-linux";  # 目标平台固定为 x86_64-linux，与 koru 管理脚本中的属性路径一致
      # 主包集：叠加 rust-overlay，供除 ROS 外的所有工具链使用
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ rust-overlay.overlays.default ];
      };
      # ROS 包集：使用 nix-ros-overlay 自带锁定的 nixpkgs（而非主 nixpkgs），
      # 并允许 unfree 许可证，因为部分 ROS 组件非自由许可
      rosPkgs = import nix-ros-overlay.inputs.nixpkgs {
        inherit system;
        overlays = [ nix-ros-overlay.overlays.default ];
        config.allowUnfree = true;
      };
      tools = import ./default.nix { inherit pkgs rosPkgs; };  # 汇总全部工具链模块（见 default.nix）
      rustTarget = pkgs.stdenv.hostPlatform.rust.rustcTarget;  # 宿主机 Rust 目标三元组，用于定位 llvm-profdata 等组件路径
      versions = pkgs.lib.mapAttrs (_: tool: tool.versions) tools;  # 从各模块抽取 versions 元数据表
      versionFile = pkgs.writeText "koru-dev-versions.json" (builtins.toJSON versions);  # 把版本表落成 JSON 文件，安装后供 koru profile status 读取展示
      # 用 buildEnv 把所有工具链的 packages 合并进同一个输出（bin/lib/share）
      bundle = pkgs.buildEnv {
        name = "koru-dev-tools";
        paths = pkgs.lib.concatMap (tool: tool.packages) (builtins.attrValues tools);  # 展开每个模块的 packages 列表并拼接
        # passthru：把版本表与“包名→store 路径”清单附加到派生上，供脚本/检查查询
        passthru = {
          inherit versions;
          # 记录每个包的名称与 store 路径（优先 pname，回退 name）
          packageInventory = pkgs.lib.mapAttrs (
            _: tool:
            map (package: {
              name = package.pname or package.name;
              path = toString package;
            }) tool.packages
          ) tools;
        };
        # 构建后把 versions.json 复制到 share/koru-dev/，这是 profile.sh status 的数据来源
        postBuild = ''
          mkdir -p $out/share/koru-dev
          cp ${versionFile} $out/share/koru-dev/versions.json
        '';
      };
    in
    {
      # 对外输出：koru/profile.sh 安装的唯一属性（#dev-tools）
      packages.${system}.dev-tools = bundle;
      # nix flake check 时运行的验证：toolchain-checks.nix 逐工具链冒烟，
      # 再补一个内联的 rust-version 检查
      checks.${system} = (import ./toolchain-checks.nix { inherit pkgs bundle versions; }) // {
        rust-version =
          pkgs.runCommand "check-profile-rust"
            {
              nativeBuildInputs = [ pkgs.stdenv.cc ];  # 需要 C 编译器以驱动 cargo 构建冒烟项目
            }
            ''
              # 把 bundle 的工具放到 PATH 最前，确保检查的是安装版而非环境里的其他版本
              export PATH=${bundle}/bin:$PATH
              # 校验 rustc 精确版本（含前导空格防前缀误匹配）
              ${bundle}/bin/rustc --version | ${pkgs.gnugrep}/bin/grep -F 'rustc ${versions.rust.rustc} '
              ${bundle}/bin/cargo --version
              ${bundle}/bin/rustfmt --version
              ${bundle}/bin/cargo-clippy --version
              ${bundle}/bin/cargo llvm-cov --version
              # 确认 llvm-tools-preview 组件（含 llvm-profdata）确实随 rust 安装
              test -f ${bundle}/lib/rustlib/${rustTarget}/bin/llvm-profdata
              # 沙箱内需要可写 HOME 供 cargo 建缓存
              export HOME=$TMPDIR/home
              mkdir -p "$HOME" smoke/src
              cd smoke
              cat > Cargo.toml <<'TOML'
              [package]
              name = "profile-smoke"
              version = "0.1.0"
              edition = "2024"
              TOML
              cat > src/lib.rs <<'RUST'
              pub fn answer() -> u32 { 42 }
              #[test]
              fn works() { assert_eq!(answer(), 42); }
              RUST
              # 离线跑覆盖率冒烟测试，验证 coverage 工具链端到端可用
              cargo llvm-cov --offline --summary-only
              touch $out
            '';
      };
    };
}
