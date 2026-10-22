# =============================================================================
#  用户：一切来自 vars.nix（username / home / groups / 初始密码）
# =============================================================================
{ pkgs, vars, ... }:
{
  users.users.${vars.username} = {
    isNormalUser = true;
    description = vars.userDescription;
    home = vars.homeDirectory;
    shell = pkgs.${vars.shell.bin};
    extraGroups = vars.userGroups;
    initialPassword = vars.initialPassword;   # 只在新用户首次创建时生效
  };

  # 允许用 passwd 改密码（默认就是 true，显式写出来方便理解）
  users.mutableUsers = true;
}
