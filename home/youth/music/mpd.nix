# ============================================================================
# home/youth/music/mpd.nix —— 本地音乐库（MPD + ncmpcpp）
# ----------------------------------------------------------------------------
# 架构：
#   MPD（Music Player Daemon）—— 后台音乐服务，负责解码与输出
#     ↑ 由 ncmpcpp（终端前端）或 mpc（命令行）控制
#     ↓ 音频输出走 PipeWire（见 configuration.nix 中的 services.pipewire）
#
# 目录约定：
#   音乐文件  ~/music
#   播放列表  ~/.config/mpd/playlists
#   数据库    ~/.local/share/mpd/database
#
# 常用命令：
#   mpc                 查看当前播放状态
#   mpc play / next     播放 / 下一首
#   mpc update          扫描音乐库新增文件
#   ncmpcpp             打开交互式终端界面
#
# 生成的配置文件：~/.config/mpd/mpd.conf
# ============================================================================
# 模块参数：pkgs —— 包集合（用于引用 mpc 等包）；... —— 接受其它未声明的参数
{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
      mpc # MPD 的命令行客户端（极简，便于脚本控制）
    ];

    # ------------------------------------------------------------------------
    # MPD 服务
    # ------------------------------------------------------------------------
    services.mpd.enable = true; # 注册为 systemd 用户服务并随登录启动

    services.mpd = {
      musicDirectory = "/home/youth/music"; # 音乐库根目录（须自行放入音频文件）

      # 追加到 mpd.conf 的额外配置
      extraConfig = ''
        # 输出方式：直接输出到 PipeWire
        audio_output {
          type "pipewire"
          name "PipeWire Output"
        }

        restore_paused "yes"  # 启动时恢复上次的暂停/播放状态
        auto_update "yes"     # 自动检测音乐目录变化并更新数据库
      '';
    };

    # ------------------------------------------------------------------------
    # ncmpcpp：MPD 的终端图形前端
    # 说明：需系统存在 ncmpcpp 程序时才会启用；
    #       若 nixpkgs 中该包不可用，可改用 mpc 或安装 ncmpcpp 后手动运行。
    # ------------------------------------------------------------------------
    programs.ncmpcpp = {
      enable = true;
      mpdMusicDir = "/home/youth/music"; # 音乐目录（与 MPD 保持一致）
      settings = {
        lyrics_directory = "/home/youth/music"; # 歌词存放目录
        store_lyrics_in_song_dir = "yes"; # 歌词直接保存到歌曲所在目录，便于随文件携带
      };
    };
}
