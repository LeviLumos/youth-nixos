# poppler-utils.nix —— poppler-utils（PDF 工具集）模块。
# 角色：home/ 用户层纯安装模块，由 enable.poppler-utils 开关控制。
# 引用链：flake.nix → home/default.nix → 本文件。
# 数据流：仅安装 pkgs.poppler-utils（主要是 pdftotext）；zathura 打开 PDF
#   时也依赖 poppler 渲染后端。
# --- poppler-utils ---
# PDF tooling built on poppler; the one that matters here is pdftotext:
#   pdftotext -layout in.pdf out.txt
# `-layout` keeps the original visual layout, which is usually what you want.
# For scanned (image-only) PDFs nothing here helps; that needs OCR (tesseract).
{ pkgs, ... }:
{
  home.packages = [ pkgs.poppler-utils ];
}
