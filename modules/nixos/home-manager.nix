# =============================================================================
#  挂载 home-manager（作为 NixOS 模块使用）
# =============================================================================
{ inputs, vars, ... }:
{
  home-manager = {
    useGlobalPkgs = true;      # 与系统共用同一份 nixpkgs（省一次构建）
    useUserPackages = true;    # 用户包装到 ~/.nix-profile
    backupFileExtension = "hm-backup";   # 与已存在文件冲突时备份而不是报错

    # 传给所有 home-manager 模块的额外参数
    extraSpecialArgs = {
      inherit inputs vars;
    };

    users.${vars.username} = {
      imports = [ ../home/default.nix ];
    };
  };
}
