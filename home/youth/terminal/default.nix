# ============================================================================
# home/youth/terminal/default.nix —— 终端模拟器子模块入口
# ----------------------------------------------------------------------------
# 由 home/youth/default.nix 的 `imports = [ ./terminal ]` 引入。
# Nix 会自动把目录 ./terminal 解析为 ./terminal/default.nix。
#
# 当前包含：
#   kitty.nix     —— GPU 加速终端（日常默认，configuration.nix 中 TERMINAL 变量）
#   alacritty.nix —— 备选终端，更轻量
# ============================================================================
{
  imports = [
    ./kitty.nix # kitty 终端配置
    #./alacritty.nix # alacritty 终端配置（备选）
  ];
}
