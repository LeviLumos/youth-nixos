# tests/koru/render.py —— 测试 scripts/koru/render.py（终端宽度自适应、
# Unicode/East-Asian 宽度计算、主题 ANSI 着色与 TTY 交互路径）。
# 由 tests/koru/run.sh 调用，随其进入 CI 的 flake-check job。
"""Check actual terminal widths, Unicode names and theme-driven ANSI output."""
import fcntl
import os
from pathlib import Path
import pty
import re
import struct
import subprocess
import termios
import unicodedata

renderer = Path(__file__).resolve().parents[2] / "scripts/koru/render.py"
escape = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
# 四种宽度下验证主题色 ANSI 出现且每行显示宽度不超限
for width in (24, 40, 60, 80):
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 24, width, 0, 0))
    env = dict(os.environ, TERM="xterm-256color", KORU_COLOR_VALUE="#123456")
    env.pop("NO_COLOR", None)
    subprocess.run(
        ["python3", str(renderer), "field", "Node", "香港 🇭🇰 " + "Long node " * 30],
        stdout=slave, check=True, env=env,
    )
    output = os.read(master, 8192).decode()
    os.close(slave)
    os.close(master)
    assert "\033[38;2;18;52;86m" in output
    for line in escape.sub("", output).splitlines():
        cells = sum(
            0 if unicodedata.combining(c) or c in ("\u200d", "\ufe0f")
            else 2 if unicodedata.east_asian_width(c) in "WF" else 1
            for c in line
        )
        assert cells <= width, (width, line)

# 非 TTY 输出纯文本无转义
plain = subprocess.check_output(
    ["python3", str(renderer), "line", "value", "Plain output"], text=True,
)
assert "\033" not in plain

# 经真 TTY 走 koru.sh proxy start，验证 Done 输出与 TRACE 调用记录
# Exercise the interactive command through a real TTY with the mock backend.
master, slave = pty.openpty()
cli = renderer.parent.parent / "koru.sh"
subprocess.run(
    ["bash", str(cli), "proxy", "start"],
    stdin=slave, stdout=slave, stderr=slave, check=True,
)
output = os.read(master, 8192).decode()
os.close(slave)
os.close(master)
assert "Done." in output
assert "proxyctl <--color> <never> <start>" in Path(os.environ["TRACE"]).read_text()
print("Terminal layout tests passed.")
