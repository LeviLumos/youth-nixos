# koru/render.py —— 终端渲染工具：被 common.sh 的 koru_line/koru_field/
# koru_run 以三种模式调用：line（单行标题/提示）、field（标签-值对，窄终端
#   降级为两行）、logs（stdin 日志按显示宽度折行）。
# 颜色来自 KORU_COLOR_* 环境变量（common.sh 从 system/theme.nix 导出），
#   仅在 TTY 且非 NO_COLOR/dumb 终端时启用。
# 宽度计算考虑 Unicode：组合字符 0 列、东亚全宽 2 列。
"""Width-aware presentation only; operations live in the shell scripts."""

import os
import re
import shutil
import sys
import unicodedata

# 探测终端宽度并钳制在 [12, 80]
try:
    terminal_width = os.get_terminal_size(sys.stdout.fileno()).columns
except OSError:
    terminal_width = shutil.get_terminal_size((72, 24)).columns
width = max(12, min(80, terminal_width))
ansi = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")


# 去掉 ANSI 转义与不可打印字符，得到“净宽”文本用于测量
def clean(text):
    return "".join(c for c in ansi.sub("", text) if c >= " " and c != "\x7f")


# 终端单元格宽度：组合字符/ZWJ/变体选择符 0 列；东亚全宽/宽字符 2 列；其余 1 列
def cells(char):
    if unicodedata.combining(char) or char in ("\u200d", "\ufe0f"):
        return 0
    return 2 if unicodedata.east_asian_width(char) in "WF" else 1


# 按显示宽度截断并加省略号尾缀（占 3 列）
def clip(text, limit):
    text = clean(text)
    if sum(map(cells, text)) <= limit:
        return text
    result, used = "", 0
    for char in text:
        used += cells(char)
        if used > limit - 3:
            break
        result += char
    return result + "..."


# 把 6 位十六进制色转 24-bit RGB 前景色序列；非法/非 TTY 时不着色
def color(role):
    if not sys.stdout.isatty() or "NO_COLOR" in os.environ or os.getenv("TERM") == "dumb":
        return "", ""
    value = os.getenv("KORU_COLOR_" + role.upper(), "").lstrip("#")
    if not re.fullmatch(r"[0-9a-fA-F]{6}", value):
        return "", ""
    rgb = [int(value[i:i + 2], 16) for i in (0, 2, 4)]
    return "\033[38;2;%d;%d;%dm" % tuple(rgb), "\033[0m"


def emit(role, text):
    start, end = color(role)
    print(start + text + end, flush=True)


mode = sys.argv[1]
if mode == "line":
    emit(sys.argv[2], clip(sys.argv[3], width))
elif mode == "field":
    # 宽度 >=44 时标签左对齐 12 列同行输出，否则标签、值分两行
    label, value = sys.argv[2:4]
    if width >= 44:
        start, end = color("label")
        other, reset = color("value")
        print(f"  {start}{label:<12}{end} {other}{clip(value, width - 15)}{reset}")
    else:
        emit("label", clip("  " + label, width))
        emit("value", clip("    " + value, width))
elif mode == "logs":
    # 先按显示宽度找断点、优先在空格处折行，再加缩进与 muted 色；
    # 必须先折纯文本再上色，否则 ANSI 序列会干扰宽度计算
    for line in sys.stdin:
        text = clean(line.rstrip())
        # Wrap before applying ANSI colors, including long store paths.
        while sum(map(cells, text)) > width - 2:
            used, cut = 0, 0
            for char in text:
                if used + cells(char) > width - 2:
                    break
                used += cells(char)
                cut += 1
            split = text.rfind(" ", 0, cut + 1)
            if split > cut // 2:
                cut = split
            emit("muted", "  " + text[:cut])
            text = text[cut:].lstrip()
        emit("muted", "  " + text)
