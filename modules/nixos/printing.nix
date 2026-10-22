# =============================================================================
#  打印 + 扫描
# -----------------------------------------------------------------------------
#  开关：vars.hardware.printing / vars.hardware.scanning
#  组件：CUPS（打印）+ Avahi（mDNS 自动发现网络打印机/扫描仪）+ SANE（扫描）
#
#  使用：
#    - 网页管理界面：http://localhost:631
#    - 图形工具：system-config-printer（未装，需要就加到 home/packages.nix）
#    - 命令行：lpstat -p / lpoptions -d <打印机名> / lp <文件>
#    - 现代网络打印机走 IPP Everywhere / driverless，通常【不需要】装驱动
# =============================================================================
{ lib, pkgs, vars, ... }:
{
  services.printing = lib.mkIf vars.hardware.printing {
    enable = true;
    # 老打印机才需要额外驱动（会明显增加构建体积），按需打开：
    # drivers = [ pkgs.gutenprint ];      # 惠普/佳能/爱普生等大量老机型
    # drivers = [ pkgs.hplipWithPlugin ]; # 惠普一体机（含扫描）
  };

  # mDNS：让系统能自动发现局域网里的打印机 / AirPrint / 网络扫描仪
  services.avahi = lib.mkIf vars.hardware.printing {
    enable = true;
    nssmdns4 = true;                     # 通过 mDNS 解析 .local 主机名
    openFirewall = true;                 # 打开 5353/UDP
  };

  # 扫描仪（SANE）
  hardware.sane = lib.mkIf vars.hardware.scanning {
    enable = true;
    # 一体机/特殊机型按需打开后端（examples）：
    # extraBackends = [ pkgs.hplip ];      # 惠普
    # extraBackends = [ pkgs.sane-airscan ]; # AirScan / eSCL 网络扫描仪（推荐）
  };

  # 扫描工具的图形界面（需要就打开）：
  # environment.systemPackages = lib.mkIf vars.hardware.scanning [ pkgs.xsane pkgs.simple-scan ];
}
