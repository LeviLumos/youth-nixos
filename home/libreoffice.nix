# libreoffice.nix —— LibreOffice 办公套件模块。
# 角色：home/ 用户层纯安装模块，由 enable.libreoffice 开关控制。
# 引用链：flake.nix → home/default.nix → 本文件。
# 数据流：仅安装 pkgs.libreoffice；home/zsh.nix 在 enable.libreoffice
#   打开时定义的 topdf 函数（headless 转 PDF）依赖本包提供的 soffice。
# --- libreoffice ---
# Full office suite (Writer/Impress/Calc); also converts docx/pptx to pdf via
# `soffice --headless --convert-to pdf --outdir <dir> <file>`.
{ pkgs, ... }:
{
  home.packages = [ pkgs.libreoffice ];
}
