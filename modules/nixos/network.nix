# =============================================================================
#  网络：主机名 / NetworkManager / GitHub 加速（GitHub520 hosts）
# =============================================================================
{ github-hosts, vars, ... }:
{
  networking = {
    hostName = vars.hostname;

    # 桌面环境需要 NetworkManager（nmtui / nmcli / 托盘）
    networkManager.enable = true;

    # ---- GitHub520 hosts：国内加速 github 访问 ----
    # 来源是 flake 里的 github-hosts 输入（flake = false，即纯源码目录）
    # 等价效果：把 https://github.com/521xueweihan/GitHub520 的 hosts 文件并入 /etc/hosts
    hostFiles = [
      "${github-hosts}/hosts"
    ];

    # 若还需要自定义静态解析，写在这里：
    # extraHosts = ''
    #   127.0.0.1 example.local
    # '';

    firewall.enable = true;
  };
}
