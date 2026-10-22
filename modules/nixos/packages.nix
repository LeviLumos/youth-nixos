# =============================================================================
#  全局（系统级）软件：wget / curl / sshd / git / vim
# =============================================================================
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    vim
  ];

  # ---- sshd -----------------------------------------------------------------
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;   # 建议配置好 ~/.ssh/authorized_keys 后改为 false
    };
  };

  # ---- zsh（需求：shell 用 zsh）----------------------------------------------
  #  这里只负责“系统里有 zsh、可以作为登录 shell”，
  #  zsh 的配置（.zshrc）由 home-manager 的 home.file 管理，见 modules/home/zsh.nix
  programs.zsh.enable = true;

  environment.variables = {
    EDITOR = "vim";
  };
}
