# =============================================================================
#  容器：podman（rootless，兼容 docker 命令）
# -----------------------------------------------------------------------------
#  开关：vars.virtualisation.podman.*
#
#  用法：
#    podman run --rm -it alpine sh        # 拉镜像跑容器（不需要 sudo）
#    podman ps -a                         # 看容器
#    podman images                        # 看镜像
#    docker ...                           # dockerCompat 打开后等价于 podman
#
#  ⚠️ rootless 需要 subuid/subgid 映射：NixOS 的 virtualisation.podman 会带上
#     containers-common 与默认配置；若首次 podman run 报
#     "no subuid ranges found for user" 之类，在 modules/nixos/user.nix 里给该用户加：
#       subUidRanges = [{ startUid = 100000; count = 65536; }];
#       subGidRanges = [{ startGid = 100000; count = 65536; }];
#     然后 sudo nixos-rebuild switch（改完最好重新登录一次）。
# =============================================================================
{ lib, vars, ... }:

let
  cfg = vars.virtualisation.podman;
in
{
  virtualisation.podman = lib.mkIf cfg.enable {
    enable = true;

    # 提供 docker 命令（别名到 podman），方便复制网上的 docker 命令
    dockerCompat = cfg.dockerCompat;

    # 容器里能解析域名（netavark DNS），否则 apt/pip 之类会卡在域名解析
    defaultNetwork.settings.dns_enabled = true;

    # 每周清理悬空镜像与已停止的容器（和 vars.nixGc 一样是 systemd timer）
    autoPrune = {
      enable = cfg.autoPrune;
      dates = "weekly";
    };
  };
}
