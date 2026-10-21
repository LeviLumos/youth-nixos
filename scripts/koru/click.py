#!/usr/bin/env python3
# koru/click.py —— 自动连点器：由 koru.sh 的 click 子命令 exec 调用。
# 频率持久化到 ~/.config/koru/click-frequency；实际点击由 systemd 用户服务
#   koru-click.service（定义在 home/niri/auto-click.nix）以 --worker 模式
#   运行本脚本，通过 ydotoold 的 Unix socket 注入 input_event。
# 交互模式负责参数解析与 toggle；worker 模式是常驻点击循环。
"""Persistent click settings and a session-scoped ydotool worker."""
import argparse
import fcntl
import math
import os
from pathlib import Path
import signal
import socket
import struct
import subprocess
import sys
import tempfile
import threading
import time

# systemd 用户服务单元名 / 默认频率 / ydotoold socket 默认路径
UNIT = 'koru-click.service'
DEFAULT_FREQUENCY = 100.0
SOCKET = '/run/ydotoold/socket'


# 频率设置文件路径，遵循 XDG_CONFIG_HOME
def settings_path():
    return Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config')) / 'koru/click-frequency'


# 参数校验：必须是有限浮点数且在 0.1–1000 次/秒之间
def frequency_value(value):
    try:
        number = float(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError('Frequency must be a number.') from error
    if not math.isfinite(number) or not 0.1 <= number <= 1000:
        raise argparse.ArgumentTypeError('Frequency must be between 0.1 and 1000 clicks per second.')
    return number


# 读取已保存频率，文件缺失时回退默认值
def read_frequency():
    try:
        return frequency_value(settings_path().read_text().strip())
    except FileNotFoundError:
        return DEFAULT_FREQUENCY


# 原子写入：先写临时文件再 rename 替换，避免读到半截配置
def save_frequency(number):
    path = settings_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, delete=False) as handle:
        temporary = Path(handle.name)
        handle.write(f'{number:g}\n')
    try:
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


# 用 SOCK_DGRAM 连接 ydotoold socket 探测后端是否可用；
# ydotoold 由 NixOS 配置提供，未就绪时提示应用配置并重新登录
def check_backend():
    connection = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    try:
        connection.connect(os.environ.get('YDOTOOL_SOCKET', SOCKET))
    except OSError:
        connection.close()
        raise RuntimeError('Cannot access ydotoold. Apply the NixOS configuration and log out and back in.') from None
    return connection


# 常驻点击循环：SIGTERM/SIGINT 只置位停止事件；
# BTN_LEFT(272) down/up 各跟一个 SYN_REPORT(0,0,0) 构成一次完整点击；
# 起始延迟 0.25s 等待热键修饰键释放；节奏落后时跳过积压点击而不是连发补齐；
# 退出前补发 button-up，防止按键卡住
def worker():
    stopped = threading.Event()
    for sig in (signal.SIGTERM, signal.SIGINT):
        signal.signal(sig, lambda *_: stopped.set())
    # ydotoold accepts native Linux input_event records, one per datagram.
    # BTN_LEFT down/up, each followed by SYN_REPORT, form one full click.
    def emit(connection, kind, code, value):
        connection.send(struct.pack('@llHHi', 0, 0, kind, code, value))

    with check_backend() as connection:
        deadline = time.monotonic() + 0.25  # Let the hotkey modifiers be released.
        try:
            while not stopped.wait(max(0, deadline - time.monotonic())):
                frequency = read_frequency()
                emit(connection, 1, 272, 1)
                emit(connection, 0, 0, 0)
                emit(connection, 1, 272, 0)
                emit(connection, 0, 0, 0)
                interval = 1 / frequency
                deadline += interval
                # Skip missed clicks instead of emitting bursts after a stall.
                if deadline < time.monotonic():
                    deadline = time.monotonic() + interval
        finally:
            emit(connection, 1, 272, 0)
            emit(connection, 0, 0, 0)


# 查询用户服务是否在运行
def is_active():
    return subprocess.run(['systemctl', '--user', 'is-active', '--quiet', UNIT], check=False).returncode == 0


# 用 per-uid 文件锁串行化热键快速连按，保证每次按键恰好 toggle 一次；
# --frequency 只保存参数并即时生效（worker 每次循环重读频率），无需重启服务
def main():
    parser = argparse.ArgumentParser(prog='koru click', description='Toggle automatic left clicks at the cursor. Default: 100 clicks/s.')
    parser.add_argument('action', nargs='?', choices=['toggle', 'start', 'stop', 'status'])
    parser.add_argument('--frequency', type=frequency_value, help='save clicks per second (0.1–1000); applies while running')
    parser.add_argument('--worker', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.worker:
        worker()
        return
    # Serialize rapid hotkey invocations so each press toggles exactly once.
    runtime = Path(os.environ.get('XDG_RUNTIME_DIR', '/tmp'))
    with (runtime / f'koru-click-{os.getuid()}.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if args.frequency is not None:
            save_frequency(args.frequency)
        action = args.action or ('status' if args.frequency is not None else 'toggle')
        if action == 'toggle':
            action = 'stop' if is_active() else 'start'
        if action == 'start':
            with check_backend():
                pass
        if action in ('start', 'stop'):
            subprocess.run(['systemctl', '--user', action, UNIT], check=True)
        print(f'Click: {"running" if is_active() else "stopped"}; frequency: {read_frequency():g} clicks/s')


if __name__ == '__main__':
    try:
        main()
    except (OSError, RuntimeError, argparse.ArgumentTypeError, subprocess.CalledProcessError) as error:
        print(f'koru click: {error}', file=sys.stderr)
        sys.exit(1)
