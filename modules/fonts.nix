# ── 字体 ─────────────────────────────────────────────────
{ config, pkgs, ... }:

{
  # Maple Mono CN（Nerd Font 变体）：等宽编程字体，含中文字形与图标
  # 通过 fc-list | grep -i maple 验证安装结果
  fonts.packages = with pkgs; [
    maple-mono.NF-CN
  ];
}
