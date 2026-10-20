# ============================================================================
# modules/virtualization.nix —— 容器与虚拟机支持
# ----------------------------------------------------------------------------
# 作用：为 NixOS 启用 Docker 容器引擎与 libvirt/KVM 虚拟化能力，
#       并安装 virt-manager 图形管理界面。
#
# 配套用户组（见 configuration.nix 中的 users.users.youth.extraGroups）：
#   docker / libvirtd / kvm —— 分别对应容器管理、虚拟化管理、硬件加速直通。
#
# 典型用法：
#   docker run …                     # 运行容器
#   virsh list --all                 # 命令行管理虚拟机
#   virt-manager                      # 图形化新建/启动虚拟机
# ============================================================================

# pkgs 用于引用 virtiofsd 等额外包；... 表示接受其它未声明的模块参数
{pkgs, ...}: {
  # --------------------------------------------------------------------------
  # Docker
  # --------------------------------------------------------------------------
  virtualisation.podman.enable = true;

  # --------------------------------------------------------------------------
  # libvirt / KVM
  # --------------------------------------------------------------------------
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu = {
    # 以普通用户身份运行 QEMU，无需 root 即可启动虚拟机（更安全的默认）
    runAsRoot = false;
    # 软件 TPM 模拟：让 Windows 等需要 TPM 的系统能正常安装与运行
    swtpm.enable = true;
    # virtiofsd：虚拟机与宿主机之间共享文件夹的高性能通道（需先编译安装 virtiofsd）
    vhostUserPackages = [
      pkgs.virtiofsd
    ];
  };

  # 图形界面管理器（依赖 libvirt 服务与本机安装的 virt-viewer/qemu-img 等）
  programs.virt-manager.enable = true;
}