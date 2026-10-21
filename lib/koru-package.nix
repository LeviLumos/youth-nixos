# koru-package.nix —— 打包仓库自带的 koru 命令行管理工具（scripts/koru.sh
# 及其子命令）。
# 由 home/default.nix 在 home.packages 中导入安装，repositoryRoot 固定为
#   ~/.config/nixos。
# 产出是一个 symlinkJoin 包：内含 writeShellApplication 构建的 koru CLI、
#   runCommand 复制的运行时脚本副本、以及 zsh 补全文件。
# 消费方：koru CLI 的全部子命令（system/home/profile/proxy/file/click/store）。
{
  pkgs,
  lib,
  theme,
  repositoryRoot,
}:
let
  # 把 scripts/ 下的脚本复制进 store 产出，供 CLI exec 调用
  scripts = pkgs.runCommand "koru-scripts" { } ''
    mkdir -p $out
    cp ${../scripts/koru.sh} $out/koru.sh
    cp ${../scripts/home-modules.sh} $out/home-modules.sh
    cp -r ${../scripts/koru} $out/koru
  '';
  cli = pkgs.writeShellApplication {  # writeShellApplication：自动生成受控 PATH 并做 shellcheck
    name = "koru";
    # koru.sh 运行所需的全部外部命令：git/nix/home-manager/nixos-rebuild（构建）、
    # jq/qrencode/python3（逻辑）、systemd/util-linux 等（系统操作）
    runtimeInputs = with pkgs; [
      bash
      coreutils
      diffutils
      findutils
      gawk
      git
      gnugrep
      gnused
      home-manager
      iproute2
      jq
      nix
      nixos-rebuild
      nixfmt
      python3
      qrencode
      systemd
      util-linux
    ];
    # CLI 本体：导出仓库根路径、NixOS sudo 包装器与主题色变量（供脚本输出着色），最后 exec 真正的 koru.sh
    text = ''
      export KORU_REPO=${lib.escapeShellArg repositoryRoot}
      export KORU_SUDO=/run/wrappers/bin/sudo
      export KORU_COLOR_HEADING=${lib.escapeShellArg theme.accent-bright}
      export KORU_COLOR_SUCCESS=${lib.escapeShellArg theme.accent}
      export KORU_COLOR_WARNING=${lib.escapeShellArg theme.accent-yellow}
      export KORU_COLOR_ERROR=${lib.escapeShellArg theme.ansi.red}
      export KORU_COLOR_LABEL=${lib.escapeShellArg theme.muted}
      export KORU_COLOR_VALUE=${lib.escapeShellArg theme.fg}
      export KORU_COLOR_MUTED=${lib.escapeShellArg theme.muted-alt}
      exec ${pkgs.bash}/bin/bash ${scripts}/koru.sh "$@"
    '';
  };
in
pkgs.symlinkJoin {  # symlinkJoin 合并 CLI 与补全
  name = "koru-cli";
  paths = [ cli ];
  postBuild = ''
    # zsh 补全装到 site-functions
    install -Dm0644 ${../completions/_koru} $out/share/zsh/site-functions/_koru
  '';
}
