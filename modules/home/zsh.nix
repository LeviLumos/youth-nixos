# =============================================================================
#  zsh 配置：home.file 管理 ~/.zshrc
# -----------------------------------------------------------------------------
#  源文件：dotfiles/zsh/.zshrc，占位符 @xxx@ 由 replaceVars 替换
#  详细说明见 doc/zsh.md
#  注意：这里【没有】启用 programs.zsh，避免 home-manager 自己生成 .zshrc 覆盖我们自己的
# =============================================================================
{ pkgs, vars, ... }:
{
  home.file.".zshrc".source =
    pkgs.replaceVars ../../dotfiles/zsh/.zshrc {
      editor = vars.shell.editor;
      homeDir = vars.homeDirectory;
      hostname = vars.hostname;
      repoDir = vars.repoDir;
    };
}
