# locale.nix —— koru 主机的本地化配置：时区、系统 locale 与键盘布局。
# 由 flake.nix 的 mkHost 以目录 ./hosts/koru 导入，经 default.nix 汇总生效。
# koru: timezone, locale and keyboard layout.
{
  time.timeZone = "Asia/Shanghai";  # 时区上海
  i18n.defaultLocale = "en_US.UTF-8";  # 系统消息用英文（日志好搜索，不影响中文显示）

  services.xserver.xkb = {  # 键盘布局（TTY/显示管理器层面）
    layout = "us";  # 标准 US 布局
    variant = "";  # 无变体
  };
}
