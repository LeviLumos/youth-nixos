# =============================================================================
#  Rime 用户配置：默认方案 = 雾凇双拼
# -----------------------------------------------------------------------------
#  源文件：dotfiles/rime/default.custom.yaml → ~/.local/share/fcitx5/rime/
#  机制：Rime 的 default.custom.yaml 会 patch 掉雾凇自带的 default.yaml，
#        把 schema_list 切到 double_pinyin（雾凇双拼）
#  词库：just rime-ice（克隆 github.com/iDvel/rime-ice 到同一目录）
# =============================================================================
{ ... }:
{
  home.file.".local/share/fcitx5/rime/default.custom.yaml".source =
    ../../dotfiles/rime/default.custom.yaml;
}
