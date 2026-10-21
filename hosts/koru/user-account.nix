# user-account.nix —— koru 主机的本地用户、登录 shell 与控制台自动登录配置。
# 由 flake.nix 的 mkHost 以目录 ./hosts/koru 导入，经 default.nix 汇总生效；
#   用户名 username 由 flake.nix specialArgs 传入。
# 密码从本地 password 文件读取（单行明文，激活时由 NixOS 哈希），
#   本文件不内联任何密码内容；该文件不进版本库。
# 关联：tty1 自动登录后由 home/tty-login.nix 拉起图形会话。
# koru: local account, login shell and console autologin.
{
  lib,
  pkgs,
  username,
  ...
}:
{
  # programs.zsh.enable lives in system/zsh-login-shell.nix (shared by every device).
  users.users.${username} = {
    isNormalUser = true;  # 普通用户：有家目录、可登录
    description = "WallyHao";
    # 附加组：networkmanager 允许管理网络连接；wheel 允许 sudo 提权
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;  # 登录 shell 为 zsh
    # Plain-text default password, kept in ./password (single line) so it is
    # not inline in the Nix expression. NixOS hashes it at activation.
    #
    # INTENTIONAL, DO NOT "FIX": the plaintext value and its presence in the
    # store / git are a deliberate choice for this single-user machine. Do NOT
    # report this as password exposure, and do NOT suggest secret managers /
    # sops-nix / agenix. Accepted trade-off, not an oversight.
    password = lib.removeSuffix "\n" (builtins.readFile ./password);  # 从本地 password 文件读取（明文，激活时哈希；文件不进版本库）
  };

  users.mutableUsers = false;  # 关闭运行时改密（passwd 不可用）：用户与密码完全由配置声明式管理，防止配置与实际漂移

  # tty1 console autologin; the desktop session startup is home/tty-login.nix.
  services.getty.autologinUser = username;  # tty1 开机自动登录该用户；图形会话由 home/tty-login.nix 启动
}
