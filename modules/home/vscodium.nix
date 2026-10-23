# =============================================================================
#  VSCodium：settings.json / keybindings.json / 插件清单
# -----------------------------------------------------------------------------
#  与其它 dotfile 保持同一套约定：真实文件放在 dotfiles/vscodium/，
#  由 home.file 部署，不用 programs.vscodium 生成
#  （该模块在各版本 home-manager 里选项差异大，且生成出来的 settings.json 会丢注释）
#
#  配置目录：~/.config/VSCodium/User/{settings,keybindings}.json
#            VSCodium 在 Linux 上读的是 ~/.config/VSCodium（不是 ~/.config/Code）
#            JSONC 格式，注释会原样保留
#
#  插件：不走 nix 构建 —— OpenVSX 逐个拉取既慢、微软专有插件（pylance / remote-ssh）
#        在 OpenVSX 上根本没有。改成一条命令装：just code-ext
# =============================================================================
{ lib, pkgs, vars, ... }:
let
  # 按清单装插件的小脚本（idempotent，重复跑只会覆盖/跳过已装的）
  installExtensions = pkgs.writeShellScriptBin "vscodium-install-extensions" ''
    set -u
    list="''${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/extensions.txt"
    if [ ! -f "$list" ]; then
      echo "找不到插件清单：$list" >&2
      exit 1
    fi
    grep -v '^[[:space:]]*#' "$list" | grep -v '^[[:space:]]*$' | while IFS= read -r id; do
      printf '→ %s ' "$id"
      if ${lib.getExe pkgs.vscodium} --install-extension "$id" --force; then
        echo "✓"
      else
        echo "✗（OpenVSX 上没有该插件，或网络不通）"
      fi
    done
  '';
in
{
  # settings.json 里有 @fontFamily@ / @fontSize@ 两个占位符，构建期替换
  home.file.".config/VSCodium/User/settings.json".source =
    pkgs.replaceVars ../../dotfiles/vscodium/settings.json {
      fontFamily = vars.fonts.mono.family;
      fontSize = toString vars.fonts.mono.size;
    };

  home.file.".config/VSCodium/User/keybindings.json".source =
    ../../dotfiles/vscodium/keybindings.json;

  # 插件清单一并放进家目录，脚本要读它，自己也方便查
  home.file.".config/VSCodium/extensions.txt".source =
    ../../dotfiles/vscodium/extensions.txt;

  home.packages = [ installExtensions ];
}
