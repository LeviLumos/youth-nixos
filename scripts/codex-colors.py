# codex-colors.py —— 由 Nix 配置（home/codex.nix）包装调用：在 PTY 中运行
# Codex CLI，把其硬编码的蓝色系 TUI 强调色替换为共享主题调色板
# （accent/selection/selection-text 三个 hex 参数）。
# 实现：逐字节 ANSI 状态机，只重写 SGR 真彩段；非 TTY 时直接 execvp 透传。
# 测试：tests/codex-colors/run.py。
"""Run Codex in a PTY and replace its fixed TUI accents with the shared palette.

Only known RGB SGR colors are changed. OSC, image protocols, input, and other
escape sequences pass through untouched. Non-terminal invocations use exec.
"""

import argparse
import errno
import os
import pty
import selectors
import signal
import termios
import tty


# 建立替换映射：三个已知蓝色 RGB（SGR 38 前景）映射到 accent，
# 其 48 背景形式映射到 selection 背景，深蓝前景映射为 selection 文本色
class ColorFilter:
    def __init__(self, accent, selection, selection_text):
        def rgb(value):
            return tuple(str(int(value[i : i + 2], 16)).encode() for i in (1, 3, 5))

        blues = ((b"99", b"168", b"248"), (b"164", b"205", b"251"), (b"28", b"100", b"200"))
        self.colors = {
            **{(b"38", color): rgb(accent) for color in blues},
            **{(b"48", color): rgb(selection) for color in blues},
            (b"38", (b"0", b"0", b"46")): rgb(selection_text),
        }
        self.state = "text"
        self.pending = bytearray()
        self.string_kind = None

    # 只重写 SGR 序列中 38/48/58 的 2;R;G;B 真彩段；38;5 索引色等其他参数原样跳过
    def sgr(self, sequence):
        parts = sequence[2:-1].split(b";")
        index = 0
        while index < len(parts):
            if parts[index] in (b"38", b"48", b"58"):
                if parts[index + 1 : index + 2] == [b"2"] and index + 4 < len(parts):
                    key = (parts[index], tuple(parts[index + 2 : index + 5]))
                    if key in self.colors:
                        parts[index + 2 : index + 5] = self.colors[key]
                    index += 5
                    continue
                if parts[index + 1 : index + 2] == [b"5"]:
                    index += 3
                    continue
            index += 1
        return b"\x1b[" + b";".join(parts) + b"m"

    # 逐字节状态机：text/escape/csi/string 四态；
    # 只在 CSI 且终止符为 m 时进入 sgr() 重写，其余序列（OSC、图片协议等）原样透传；
    # pending 超 4096 字节视为异常序列直接放行，防止无限缓冲
    def feed(self, data):
        out = bytearray()
        for byte in data:
            if self.state == "text":
                if byte == 27:
                    self.pending.append(byte)
                    self.state = "escape"
                else:
                    out.append(byte)
            elif self.state == "escape":
                self.pending.append(byte)
                if byte == ord("["):
                    self.state = "csi"
                else:
                    out.extend(self.pending)
                    self.pending.clear()
                    self.string_kind = byte
                    self.state = "string" if byte in b"]PX^_" else "text"
            elif self.state == "csi":
                self.pending.append(byte)
                if 0x40 <= byte <= 0x7E:
                    sequence = bytes(self.pending)
                    out.extend(self.sgr(sequence) if byte == ord("m") else sequence)
                    self.pending.clear()
                    self.state = "text"
                elif len(self.pending) > 4096:
                    out.extend(self.pending)
                    self.pending.clear()
                    self.state = "text"
            else:
                out.append(byte)
                if self.state == "string_escape":
                    self.state = "text" if byte == ord("\\") else "string"
                elif byte == 27:
                    self.state = "string_escape"
                elif byte == 7 and self.string_kind == ord("]"):
                    self.state = "text"
        return bytes(out)

    # 程序结束时冲出未完结的 pending 字节
    def finish(self):
        return bytes(self.pending)


# 处理管道写入不足（short write）
def write_all(fd, data):
    while data:
        size = os.write(fd, data)
        data = data[size:]


# 非 TTY 时直接 execvp 透传；
# 记录原终端属性与窗口尺寸，pty.fork 子进程内同步尺寸后 exec 目标命令；
# SIGWINCH 转发新尺寸；SIGTERM/SIGHUP/SIGINT 转发给子进程组；
# 主循环 select 双向搬运：master→stdout 时先过 ColorFilter；
# master 读到 EIO/EOF 表示子进程退出；
# finally 恢复终端属性并按 shell 惯例换算退出码
def run(command, colors):
    if not os.isatty(0) or not os.isatty(1):
        os.execvp(command[0], command)

    original = termios.tcgetattr(0)
    size = termios.tcgetwinsize(0)
    pid, master = pty.fork()
    if pid == 0:
        termios.tcsetwinsize(0, size)
        os.execvp(command[0], command)

    def resize(_signum, _frame):
        termios.tcsetwinsize(master, termios.tcgetwinsize(0))

    def forward(signum, _frame):
        try:
            os.killpg(pid, signum)
        except ProcessLookupError:
            pass

    previous = {sig: signal.getsignal(sig) for sig in (signal.SIGWINCH, signal.SIGTERM, signal.SIGHUP, signal.SIGINT)}
    signal.signal(signal.SIGWINCH, resize)
    for sig in (signal.SIGTERM, signal.SIGHUP, signal.SIGINT):
        signal.signal(sig, forward)

    try:
        tty.setraw(0)
        with selectors.DefaultSelector() as selector:
            selector.register(0, selectors.EVENT_READ)
            selector.register(master, selectors.EVENT_READ)
            running = True
            while running:
                for key, _ in selector.select():
                    try:
                        data = os.read(key.fd, 65536)
                    except OSError as error:
                        if key.fd == master and error.errno == errno.EIO:
                            running = False
                            break
                        raise
                    if not data:
                        if key.fd == master:
                            running = False
                            break
                        selector.unregister(0)
                        continue
                    if key.fd == master:
                        write_all(1, colors.feed(data))
                    else:
                        write_all(master, data)
        write_all(1, colors.finish())
    finally:
        termios.tcsetattr(0, termios.TCSADRAIN, original)
        os.close(master)
        for sig, handler in previous.items():
            signal.signal(sig, handler)
    _, status = os.waitpid(pid, 0)
    exit_code = os.waitstatus_to_exitcode(status)
    return exit_code if exit_code >= 0 else 128 - exit_code


# 三个必需颜色参数 + REMAINDER 命令；剥离可选的 -- 分隔符
def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("accent", "selection", "selection-text"):
        parser.add_argument(f"--{name}", required=True)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command
    if command[:1] == ["--"]:
        command = command[1:]
    if not command:
        parser.error("a command is required after --")
    return run(command, ColorFilter(args.accent, args.selection, args.selection_text))


if __name__ == "__main__":
    raise SystemExit(main())
