# ============================================================================
# home/youth/programs/development/neovide.nix —— Neovim 的 GUI 前端
# ----------------------------------------------------------------------------
# Neovide 把 Neovim（核心）与 GPU 渲染的 GUI 窗口结合起来，保留 vim 操作习惯
# 的同时获得原生的动画、连字与 GPU 光标渲染。
#
# 注意：Neovim 本体与插件配置由 flake.nix 中的 CookNixvim 提供，
#       本文件只负责启动器 Neovide 本身的外观设置。
#
# 生成的配置文件位置：~/.config/neovide/config.toml
# ============================================================================
# 模块参数：pkgs-unstable 由 flake 注入，用于取 Neovide 的最新版本
{pkgs-unstable, ...}: {
  programs.neovide.enable = true; # 安装 Neovide

  # 从 unstable 取包，保证 GUI 与较新的 Neovim 版本兼容
  programs.neovide.package = pkgs-unstable.neovide;

  # ------------------------------------------------------------------------
  # 外观与行为
  # ------------------------------------------------------------------------
  programs.neovide.settings = {
    idle = true; # 窗口空闲时降低 CPU 占用（无输入后自动休眠渲染）
    vsync = true; # 开启垂直同步，消除撕裂并降低资源消耗
    font = {
      normal = []; # 字体族留空表示使用系统默认（Neovim 内配置已指定 Nerd Font）
      size = 16.0; # 字号
    };
  };
}
