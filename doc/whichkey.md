# 键位速查与配置调整（which key）

> 本项目的**所有键盘快捷键集中在一处**：`dotfiles/niri/config.kdl`
> 由 `modules/home/niri.nix` 用 `home.file` 部署到 `~/.config/niri/config.kdl`。
>
> 在桌面里随时按 **`super + shift + /`** 可以弹出 niri 自带的「重要快捷键」浮层
> （= which key 浮层，内容由 config.kdl 里的 `hotkey-overlay-title` 决定）。

---

## 1. 键位速查表

`Mod` = `Super`（Windows 键 / Command 键）。

### 启动器 / 终端 / 托盘

| 键位 | 动作 | 备注 |
| --- | --- | --- |
| `super + space` | 应用启动器 `fuzzel` | 需求 (1) |
| `super + t` | 打开终端 `kitty` | 需求 (3) |
| `super + shift + t` | 系统托盘 `tray-tui`（在 kitty 里） | 桌面配套 |

### 焦点移动（需求 2）

| 键位 | 动作 |
| --- | --- |
| `super + h` | 焦点移到左边的列 |
| `super + j` | 焦点移到下面的窗口 |
| `super + k` | 焦点移到上面的窗口 |
| `super + l` | 焦点移到右边的列 |

### 窗口 / 列移动（需求 6、7）

| 键位 | 动作 | 备注 |
| --- | --- | --- |
| `super + [` | 当前列整体移到左边 | 需求 (6) |
| `super + ]` | 当前列整体移到右边 | 需求 (6) |
| `super + 9` | 窗口在**列内**上移一位 | 需求 (7)，已确认语义 |
| `super + 0` | 窗口在**列内**下移一位 | 需求 (7)，已确认语义 |

### 工作区

| 键位 | 动作 | 备注 |
| --- | --- | --- |
| `super + u` | 切到上一个工作区 | 需求 (5) |
| `super + i` | 切到下一个工作区 | 需求 (5) |
| `super + o` | 总览（overview） | 保底/常用 |

### 窗口操作

| 键位 | 动作 | 备注 |
| --- | --- | --- |
| `super + q` | 关闭当前窗口 | 需求 (4) |
| `super + f` | 当前列最大化 | 保底/常用 |
| `super + shift + f` | 窗口全屏 | 保底/常用 |
| `super + v` | 窗口浮动/平铺切换 | 保底/常用 |

### 桌面 / 电源

| 键位 | 动作 | 备注 |
| --- | --- | --- |
| `super + alt + l` | 锁屏 `swaylock` | 桌面配套 |
| `super + alt + s` | 挂起 `systemctl suspend` | 电源 |
| `super + alt + h` | 休眠 `systemctl hibernate` | 电源，需 swap ≥ 内存 |
| `super + alt + w` | 先挂起，2h 后转休眠 | 电源 |

### 截屏 / 系统

| 键位 | 动作 | 备注 |
| --- | --- | --- |
| `Print` | 截屏（可选区域） | 保存到 `~/Pictures/Screenshots/` |
| `ctrl + Print` | 截取整个屏幕 | |
| `alt + Print` | 截取当前窗口 | |
| `super + shift + e` | 退出 niri（带确认弹窗） | 保底键位，**别删** |
| `ctrl + alt + delete` | 退出 niri | 保底键位 |
| `super + shift + /` | 显示快捷键浮层 | 保底键位 |
| `super + escape` | 允许应用接管快捷键（远程桌面/游戏用） | `allow-inhibiting=false` 保证一定生效 |

---

## 2. 键位写在哪个文件

```
dotfiles/niri/config.kdl        ← 键位本体（binds { ... }，约 99~163 行）
modules/home/niri.nix           ← 把上面的文件部署到 ~/.config/niri/config.kdl，并替换 @占位符@
vars.nix                        ← 启动器/终端/锁屏/托盘 等「程序名」在这里
```

**重要分工**：

- 想换**程序**（换启动器/终端/锁屏）→ 改 `vars.nix`，**不要改键位**
- 想换**键位或动作** → 改 `dotfiles/niri/config.kdl`

```nix
# vars.nix —— 改这里就能换掉 super+space / super+t / super+alt+l / super+shift+t 的程序
niri.terminal = "kitty";
niri.launcher = "fuzzel";
desktop.locker = "swaylock";
desktop.tray   = "tray-tui";
```

---

## 3. 怎么改键位（4 步）

### 第 1 步：编辑 `dotfiles/niri/config.kdl`

在 `binds { ... }` 里加一行，例如把「打开浏览器」绑到 `super + b`：

```kdl
    Mod+B repeat=false hotkey-overlay-title="浏览器: Zen" { spawn "zen"; }
```

### 第 2 步（仅当用到新占位符时）：同步 `modules/home/niri.nix`

config.kdl 里的 `@xxx@` 必须由 `modules/home/niri.nix` 提供同名键。

> ⚠️ `pkgs.replaceVars` 会**故意让构建失败**：
> - kdl 里有 `@xxx@` 但 nix 里没给 → 失败
> - nix 里给了 `xxx` 但 kdl 里没有 `@xxx@` → 失败
>
> 所以写死的字符串（如 `spawn "zen"`）最省事，不需要动 nix 文件。

### 第 3 步：让配置生效

- **桌面里**：niri 会自动检测 `~/.config/niri/config.kdl` 的变化并热重载，**不用重启**
- **改了 `vars.nix` 或 nix 模块**：`just switch`（等价于 `sudo nixos-rebuild switch --flake .`）

### 第 4 步：验证

```bash
# 弹出快捷键浮层，确认新键位已生效
super + shift + /

# 列出 niri 支持的所有 action（改动作名前先查这个）
niri msg action
```

---

## 4. KDL 键位语法速查

```kdl
binds {
    // ① 内置动作（niri action）
    Mod+H { focus-column-left; }

    // ② 启动程序（repeat=false 防止长按连开一堆窗口）
    Mod+T repeat=false hotkey-overlay-title="终端: @terminal@" { spawn "@terminal@"; }

    // ③ 执行 shell 命令（支持管道/~ 展开/多个命令）
    Mod+Shift+T hotkey-overlay-title="系统托盘" {
        spawn-sh "@terminal@ --title @tray@ @tray@";
    }
}
```

### 常用写法

| 写法 | 作用 |
| --- | --- |
| `Mod+键` | `Mod` = Super；组合用 `+` 连起来 |
| `repeat=false` | 长按不重复触发（**所有 spawn 都建议加**） |
| `hotkey-overlay-title="..."` | 在 `super+shift+/` 浮层里显示的名字 |
| `spawn "程序"` | 直接启动程序 |
| `spawn-sh "命令"` | 走 shell，支持 `~`、管道、`&&` |
| `allow-inhibiting=false` | 禁止应用拦截这个键位（逃生键必加） |
| `cooldown 5` | 触发后 5 秒内不重复触发（可选） |

### 键名对照（写不出来的键来这里查）

| 你键盘上的 | KDL 里写 |
| --- | --- |
| Super / Win / Command | `Mod` 或 `Super` |
| Alt | `Alt` |
| Ctrl | `Ctrl` |
| Shift | `Shift` |
| 回车 | `Return` |
| 空格 | `Space` |
| Esc | `Escape` |
| Tab / Backspace | `Tab` / `Backspace` |
| 1 … 0 | `1` … `0` |
| F1 … F12 | `F1` … `F12` |
| `/` `\` | `Slash` `Backslash` |
| `[` `]` | `BracketLeft` `BracketRight` |
| `-` `=` | `Minus` `Equal` |
| `;` `'` | `Semicolon` `Apostrophe` |
| `,` `.` | `Comma` `Period` |
| 上/下/左/右 | `Up` `Down` `Left` `Right` |
| PrtSc | `Print` |
| 音量+/音量-/静音 | `XF86AudioRaiseVolume` `XF86AudioLowerVolume` `XF86AudioMute` |
| 亮度+/亮度- | `XF86MonBrightnessUp` `XF86MonBrightnessDown` |

> 键名就是 XKB 的 keysym 名。不确定时用 `wev`（`nix shell nixpkgs#wev`）抓一下。

---

## 5. 常见改法示例

### 换掉启动器 / 终端 / 锁屏

改 `vars.nix`（键位不变，只换程序）：

```nix
niri.launcher = "wofi";       # 需要先在 packages.nix 里加 pkgs.wofi
niri.terminal = "alacritty";
desktop.locker = "hyprlock";
```

### 给「切工作区」也带上当前窗口

把需求 (5) 的 `super+u/i` 改成带窗口移动：

```kdl
    Mod+U { move-window-to-workspace-up; }
    Mod+I { move-window-to-workspace-down; }
```

### 加一组音量键（PipeWire 已启用）

```kdl
    XF86AudioRaiseVolume { spawn-sh "pactl set-sink-volume @DEFAULT_SINK@ +5%"; }
    XF86AudioLowerVolume { spawn-sh "pactl set-sink-volume @DEFAULT_SINK@ -5%"; }
    XF86AudioMute        { spawn-sh "pactl set-sink-mute @DEFAULT_SINK@ toggle"; }
```

### 让某个键位不被应用抢走（远程桌面/游戏）

```kdl
    Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
```

### 删掉不需要的键位

直接把那一行删掉或加 `//` 注释掉即可；niri 热重载后失效。

---

## 6. 排错

| 现象 | 原因 / 处理 |
| --- | --- |
| 键位完全没反应 | 检查是否被输入法（fcitx5）或其它程序占用；先按 `super+escape` 解除拦截 |
| 改了 config.kdl 没生效 | 手工确认文件：`cat ~/.config/niri/config.kdl`；nix 改的必须 `just switch` |
| niri 启动失败 / 退回 TTY | KDL 语法错误（括号不匹配、引号不配对）。看 TTY 上的报错，或 `journalctl -b -u niri` |
| 提示 `unknown action` | action 名写错，用 `niri msg action` 查准确名字 |
| 构建报 `@xxx@` 相关错误 | `dotfiles/niri/config.kdl` 与 `modules/home/niri.nix` 的占位符不同步，见第 2 步 |
| `super+space` 没反应 | `fuzzel` 没装或没在 PATH；确认 `vars.niri.launcher` 与 `modules/home/packages.nix` |
| 休眠失败 | swap < 内存 或 没配 `boot.resumeDevice`，见[系统需求.md](系统需求.md) |
| 截屏后找不到图 | 默认 `~/Pictures/Screenshots/`，路径在 config.kdl 的 `screenshot-path` |

---

## 7. 相关文档

- [`系统需求.md`](系统需求.md)：全局变量表、模块说明、安装与二次加工
- [`kitty.md`](kitty.md)：终端内的键位与配置
- [`zsh.md`](zsh.md)：shell 里的别名与快捷键
- niri 官方键位文档：<https://niri-wm.github.io/niri/Configuration:-Key-Bindings>
- niri 全部 action：<https://niri-wm.github.io/niri/Configuration:-Key-Bindings#actions>
