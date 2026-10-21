# ============================================================================
# modules/default.nix —— 自定义 NixOS 模块集合入口
# ----------------------------------------------------------------------------
# NixOS 的 `imports` 会自动把目录 `./modules` 解析为本目录下的 default.nix，
# 因此在 configuration.nix 中写 `imports = [ ./modules ];` 即可一次性引入
# 这里聚合的所有子模块，无需逐个列出。
#
# 新增模块的做法：
#   1. 在本目录下新建 xxx.nix；
#   2. 在下方 imports 列表中追加 ./xxx.nix；
#   3. 执行 nixos-rebuild switch --flake .#levi 生效。
#
# 注意：这些文件被 NixOS 作为系统模块加载，模块参数中的 config / lib / pkgs /
#       inputs / pkgs-unstable 等均由 NixOS 或 flake 注入，不要在此处 import。
# ============================================================================
{
  imports = [
    ./clash.nix # 代理客户端与系统级代理环境变量
    ./nix-ld.nix # 运行通用 Linux 预编译二进制（mise 装的 node、uvx / npm 原生模块等）
    ./virtualization.nix # 容器与虚拟机（Docker / libvirt / virt-manager）
    ./documentation.nix # 系统手册与文档（man、nixos-help 等）
    # ./systemd.nix # 自定义 systemd 用户服务（解密密钥注入图形会话）
    #   【已禁用】该服务依赖 configuration.nix 中的 age.secrets，
    #   而加解密流程当前已停用，导入会导致 config.age.secrets 缺失而构建失败。
    #   恢复时需先取消 configuration.nix 中 age.* 的注释。
  ];
}