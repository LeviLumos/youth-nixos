# =============================================================================
#  Rime 用户配置：默认方案 = 雾凇双拼，并把 Rime 设为 fcitx5 的默认输入法
# -----------------------------------------------------------------------------
#  ① 方案选择：dotfiles/rime/default.custom.yaml → ~/.local/share/fcitx5/rime/
#     Rime 的 default.custom.yaml 会 patch 掉雾凇自带的 default.yaml，
#     把 schema_list 切成 double_pinyin（雾凇双拼）
#  ② 输入法列表：~/.config/fcitx5/profile —— fcitx5 装好后默认是空的（只有键盘），
#     必须用 fcitx5-configtool 手动加一次才能 ctrl+space 出中文。
#     这里登录/switch 时自动写一份（Rime 为默认 + 保留 us 键盘），开箱即用。
#     ⚠️ 只在 profile 不存在时写一次；之后你在 configtool 里改的不会被覆盖
#  ③ 词库：just rime-ice（克隆 github.com/iDvel/rime-ice 到同一目录）
# =============================================================================
{ lib, vars, ... }:
{
  # ---- ① 默认方案 = 雾凇双拼 --------------------------------------------------
  home.file.".local/share/fcitx5/rime/default.custom.yaml".source =
    ../../dotfiles/rime/default.custom.yaml;

  # ---- ② fcitx5 输入法列表：默认 Rime ------------------------------------------
  #  只在文件不存在时写（home.activation 在每次 switch 时跑，
  #  所以这里不能无条件覆盖，否则用户后来的调整会被打回）
  home.activation.seedFcitx5Profile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    profile="${vars.homeDirectory}/.config/fcitx5/profile"
    if [ ! -f "$profile" ]; then
      mkdir -p "$(dirname "$profile")"
      cat > "$profile" <<'PROFILE_EOF'
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=rime

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=rime
Layout=

[GroupOrder]
0=Default
PROFILE_EOF
      echo "已写入 fcitx5 默认输入法列表（默认 Rime，ctrl+space 切换）"
    fi
  '';
}
