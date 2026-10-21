# ============================================================================
# home/youth/programs/app.nix —— 图形应用配置
# ----------------------------------------------------------------------------
# 集中声明日常使用的桌面软件：通讯、影音、笔记、文件管理与浏览器。
#
# 两类声明方式的区别：
#   home.packages        —— 直接安装二进制包，不产生配置文件，最简单
#   programs.<name>      —— 由 home-manager 生成配置文件，可声明式管理偏好设置
#
# 模块参数：
#   pkgs   —— 包集合
#   config —— 用于读取其它模块结果（如 xdg.configHome）
#   ...    —— 接受其它未声明参数
# ============================================================================
{
  # pkgs —— 包集合
  pkgs,
  # config —— 用于读取其它模块结果（如 xdg.configHome）
  config,
  # inputs —— flake 的全部外部依赖（由 flake.nix 的 home-manager.extraSpecialArgs 注入），
  #           用于引用未收录进 nixpkgs 的包，例如 inputs.zen-browser
  inputs,
  # ... —— 接受其它未声明参数
  ...
}: {
  # ------------------------------------------------------------------------
  # 直接安装的应用（无配置文件需求）
  # ------------------------------------------------------------------------
  home.packages = with pkgs; [
    wechat # 微信 Linux 版
    vlc # VLC 媒体播放器
    discord # Discord 语音与聊天
    obsidian # Obsidian 本地 Markdown 笔记
    spotify # Spotify 音乐客户端
    kdePackages.dolphin # Dolphin 文件管理器（作为默认目录管理器，见 xdg.mimeApps）
    inputs.zen-browser.packages.${pkgs.system}.beta # Zen Browser（见下方说明）
  ];

  # ------------------------------------------------------------------------
  # 谷歌浏览器设置（已注释）
  # 说明：浏览器实际安装在 configuration.nix 的 environment.systemPackages
  #       中（google-chrome），此处保留配置模板，若想改用 NixOS 官方
  #       chromium 模块并附带扩展，可取消注释并同时移除系统包里的 chrome。
  # ------------------------------------------------------------------------
  # programs.chromium = {
  #   enable = true;
  #   commandLineArgs = [
  #     "--force-dark-mode" # 强制深色模式
  #     "--enable-features=UseOzonePlatform" # 启用 Ozone 平台接口
  #     "--ozone-platform=wayland" # 使用原生 Wayland 渲染
  #     "--force-device-scale-factor=1" # 强制缩放比例 1（HiDPI 下尤其需要）
  #     "--enable-gpu-rasterization" # GPU 加速光栅化
  #     "--enable-zero-copy" # 零拷贝渲染，降低延迟
  #   ];
  #   extensions = [
  #     "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite：广告拦截
  #     "bpoadfkcbjbfhfodiogcnhhhpibjhbnh" # 沉浸式翻译：网页双语对照
  #     "egehpkpgpgooebopjihjmnpejnjafefi" # Better History：历史记录管理
  #     "kjoehdlockiihccmfnoamenhobkkddng" # CSDN 自动展开 + 一键复制代码
  #   ];
  # };
  # catppuccin.chromium = {
  #   enable = true;
  #   flavor = "mocha";
  # };

  # ------------------------------------------------------------------------
  # Zen Browser —— 浏览器（替代 Firefox）
  # 说明：Zen Browser 是基于 Firefox 的开源分支，强调隐私（默认拦截
  #       跟踪器、广告）与垂直标签等特性，外观与操作习惯与 Firefox 一致，
  #       因此原有的 user.js 之类的 Firefox 定制思路可平移过来。
  #
  #       该包未收录进 nixpkgs，由 flake 输入 zen-browser-flake 提供，
  #       引用形式为 inputs.zen-browser.packages.<system>.<频道>：
  #         beta            —— 稳定测试通道（本配置使用，亦是该 flake 的 default）
  #         twilight        —— Nightly 通道，更新最快但可能不稳定
  #         twilight-official —— 官方 Nightly 构建
  #
  #       注意：Zen 不像 Firefox 那样由 home-manager 提供 programs.firefox
  #       这类带配置管理的模块，因此此处只安装可执行文件，用户配置放在
  #       ~/.zen/ 下，由应用自行管理（不进 Nix 声明）。
  # ------------------------------------------------------------------------
  # ------------------------------------------------------------------------
  # 视频播放器
  # ------------------------------------------------------------------------
  programs.mpv.enable = true; # 极简高性能播放器，配合 ~/Videos 作为默认媒体目录
  catppuccin.mpv = {
    enable = true; # 应用 Catppuccin 配色
    accent = "mauve"; # 强调色
    flavor = "mocha"; # 配色风格
  };

  # ------------------------------------------------------------------------
  # 录屏与直播推流
  # ------------------------------------------------------------------------
  programs.obs-studio.enable = true; # OBS Studio：录屏、直播
}
