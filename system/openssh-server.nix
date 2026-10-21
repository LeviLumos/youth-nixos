# openssh-server.nix —— OpenSSH 服务器配置。
# 作用：在默认 22 端口提供 SSH 服务（任意网络可达），允许密码登录、
#   禁止 root 登录，并在防火墙放行端口。
# 导入：由 system/default.nix 显式导入。
# 机制：services.openssh 生成 sshd 配置与 sshd systemd 服务；
#   openFirewall=true 在 networking.firewall 中追加 TCP 22 放行。
# 取值：PerSourcePenalties=no——OpenSSH 9.8 默认对连续输错来源 IP 封禁
#   最长 10 分钟，曾把共享网段的合法局域网客户端锁在门外，在保留密码登录
#   的前提下属于接受的取舍。
# --- ssh ---
# OpenSSH server: password login on the default port 22, reachable from any
# network. /etc/ssh host keys are generated on first boot, so no key material
# is stored in the repo.
{
  services.openssh = {
    enable = true;

    settings = {
      # Password login keeps external clients (no authorised keys on this
      # machine yet) able to connect; switch to key-only once a key exists.
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";

      # PerSourcePenalties (default on since OpenSSH 9.8) bans a source IP for
      # up to 10 minutes after a few mistyped usernames or passwords. That
      # locked out legitimate LAN clients on this shared /14, so it is disabled;
      # this is an accepted trade-off while password login stays enabled.
      PerSourcePenalties = "no";
    };

    # Opens TCP 22 in the firewall, keeping the SSH rules next to the service
    # instead of duplicating them in system/network-manager.nix.
    openFirewall = true;
  };
}
