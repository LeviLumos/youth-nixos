# =============================================================================
#  用户级软件包
# -----------------------------------------------------------------------------
#  需求清单：
#    1. dev_env：python314 / nodejs24（npm 由 nodejs 自带）/ just
#    2. vscodium      3. zen-browser   4. google-browser(chrome)
#    5. obsidian      6. uv            7. yazi          8. lazygit
#  桌面配套：壁纸 swaybg / 锁屏 swaylock / 空闲 swayidle / 托盘 tray-tui
# =============================================================================
{ inputs, pkgs, vars, ... }:

let
  python = pkgs.${vars.dev.python};    # python314
  nodejs = pkgs.${vars.dev.nodejs};    # nodejs_24（自带 npm/npx）
in
{
  home.packages = [
    # ---- 1. 开发环境 --------------------------------------------------------
    python
    nodejs
    pkgs.just                          # just：写 CLI 命令的工具（justfile 的运行器）

    # ---- 2~5. 编辑器 / 浏览器 / 笔记 ----------------------------------------
    pkgs.vscodium
    pkgs.google-chrome                 # unfree，已在 system.nix 中 allowUnfree
    pkgs.obsidian

    # zen-browser：nixpkgs 26.05 未内置，使用社区 flake（已确认保留该 input）
    # 若你的 nixpkgs 已内置，把这一行换成 pkgs.zen-browser 并删除 flake.nix 里的 zen-browser 输入
    # ⚠️ 用 stdenv.hostPlatform.system，不要用 pkgs.system（后者在 26.05 已弃用、会报警告）
    (inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      or inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen)

    # ---- 6~8. Python 环境管理 / 文件管理 / Git TUI ---------------------------
    pkgs.uv
    pkgs.yazi
    pkgs.lazygit

    # ---- niri 键位依赖（super+space 启动器 / super+t 终端）--------------------
    pkgs.fuzzel                        # 应用启动器
    pkgs.kitty                         # 终端（也由需求指定）

    # ---- 桌面配套：壁纸 / 锁屏 / 空闲 / 托盘 / 音频 --------------------------------
    pkgs.swaybg                        # 壁纸（vars.desktop.wallpaperTool）
    pkgs.swaylock                      # 锁屏（vars.desktop.locker）
    pkgs.swayidle                      # 空闲自动锁屏 / 挂起 / 休眠
    pkgs.tray-tui                      # 终端里的系统托盘（vars.desktop.tray）
    pkgs.pavucontrol                   # 音量/混音器图形界面（启动器里搜 PulseAudio Volume Control）
  ];
}
