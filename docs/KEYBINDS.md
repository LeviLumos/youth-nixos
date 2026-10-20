# 快捷键速查表

本仓库同时配置了 **Hyprland** 与 **Niri** 两套 Wayland 桌面环境，
两者在 GDM 登录界面可以自由切换，因此快捷键也分成两套。

> 提示：Niri 自带快捷键速查浮层，按 `Super + Shift + /` 即可在屏幕上查看。

---

## 目录

- [修饰键约定](#修饰键约定)
- [Hyprland 快捷键](#hyprland-快捷键)
- [Niri 快捷键](#niri-快捷键)
- [两套环境的对照表](#两套环境的对照表)
- [其它常用快捷键](#其它常用快捷键)
- [如何修改快捷键](#如何修改快捷键)

---

## 修饰键约定

| 文档写法 | 实际按键 | Hyprland 中的变量 | Niri 中的写法 |
| :--- | :--- | :--- | :--- |
| `Super` | Win 键 / Command 键 | `mainMod`（`SUPER + `） | `Mod` |
| `Shift` | 上档键 | `super_shift`（`SUPER + SHIFT + `） | `Shift` |
| `Alt` | 换挡键 | `super_alt`（`SUPER + ALT + `） | `Alt` |
| `Ctrl` | 控制键 | `CTRL + ` | `Ctrl` |

说明：

- 本文档中的 `Super` 均指键盘上的 **Win 键**，不是 `Ctrl`。
- 组合键中的字母**不区分大小写**，例如 `Super + B` 直接按 Win+B 即可，无需按 Shift。
- Hyprland 的修饰键在 `hyprland.lua` 中定义为变量（`mainMod` / `super_shift` / `super_alt`），
  改一处即可整体更换。

---

## Hyprland 快捷键

配置文件：`home/youth/hyprland/hypr/hyprland.lua`（第 10 节）

### 启动程序

| 快捷键 | 功能 | 实际执行的命令 |
| :--- | :--- | :--- |
| `Super + Enter` | 打开终端 | `kitty` |
| `Super + Shift + Enter` | 打开**浮动**终端 | `kitty --class floating-term` |
| `Super + B` | 打开 Chrome | `google-chrome-stable` |
| `Super + Shift + B` | 打开 Zen Browser | `zen` |
| `Super + M` | 打开音乐播放器 | `spotify` |
| `Super + D` | 应用启动器 | `rofi -show drun -theme ~/.config/rofi/themes/app.rasi` |
| `Super + E` | 文件管理器 | `EDITOR=nvim kitty yazi` |
| `Super + N` | Neovim GUI | `neovide` |
| `Super + L` | 锁屏 | `hyprlock` |
| `Super + Shift + Esc` | 电源菜单 | `wlogout -b 4` |

### 系统操作

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + Shift + R` | 重载 Hyprland 配置，并重启 waybar 与 wayvnc |
| `Super + Shift + W` | 切换壁纸（`awww-rofi.sh`，rofi 选图 + 随机过渡动画） |

### 窗口操作

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + Q` | 关闭当前窗口 |
| `Super + Shift + G` | 区域截图 → `grim` + `slurp` → 复制到剪贴板 → `satty` 标注 |
| `Super + G` | 打开截图/录屏菜单（`capture.sh`） |

### 窗口布局

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + F` | 全屏（真全屏） |
| `Super + Shift + F` | 假全屏（最大化但保留状态栏） |
| `Super + P` | 切换浮动 / 平铺 |
| `Super + Shift + P` | 固定（pin）浮动窗口，使其在所有工作区可见 |
| `Super + Shift + A` | 窗口居中 |
| `Super + V` | 伪窗口模式（pseudo），配合改窗口大小做布局微调 |
| `Super + J` | 切换当前窗口的分割方向（水平 / 垂直） |

### 焦点移动

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + Tab` | 切换到下一个窗口 |
| `Super + ←` | 焦点移到左侧窗口 |
| `Super + →` | 焦点移到右侧窗口 |
| `Super + ↑` | 焦点移到上方窗口 |
| `Super + ↓` | 焦点移到下方窗口 |

### 移动窗口（交换位置）

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + Shift + ←` | 与左侧窗口交换位置 |
| `Super + Shift + →` | 与右侧窗口交换位置 |
| `Super + Shift + ↑` | 与上方窗口交换位置 |
| `Super + Shift + ↓` | 与下方窗口交换位置 |

### 调整窗口大小

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + Alt + →` | 窗口放大（+10 像素） |
| `Super + Alt + ←` | 窗口缩小（-10 像素） |

### 鼠标绑定

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + 鼠标左键拖动` | 移动窗口 |
| `Super + 鼠标右键拖动` | 调整窗口大小 |
| `Super + 滚轮上` | 切换到上一个工作区 |
| `Super + 滚轮下` | 切换到下一个工作区 |

> 鼠标按键代码：`272` = 左键，`273` = 右键，`274` = 中键。

### 工作区

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + 1` ~ `Super + 0` | 切换到第 1 ~ 10 个工作区 |
| `Super + [` | 切换到上一个工作区 |
| `Super + ]` | 切换到下一个工作区 |
| `Super + Z` | 切换到最近的**空**工作区 |
| `Super + Shift + 1` ~ `Super + Shift + 0` | 把当前窗口移到第 1 ~ 10 个工作区 |
| `Super + Shift + [` | 把窗口移到上一个工作区（相对移动） |
| `Super + Shift + ]` | 把窗口移到下一个工作区（相对移动） |
| `Super + Shift + Z` | 把窗口移到空工作区 |

### 特殊工作区

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + S` | 显示 / 隐藏特殊工作区（"隐藏桌面"） |
| `Super + Shift + S` | 把当前窗口移入特殊工作区 |
| `Super + Shift + X` | 把窗口移到 `+0` 工作区（快速移回） |

---

## Niri 快捷键

配置文件：`home/youth/niri/config.kdl`（`binds { }` 块）

### 启动程序

| 快捷键 | 功能 | 实际执行的命令 |
| :--- | :--- | :--- |
| `Super + /` + `Shift` | **显示快捷键速查浮层** | `show-hotkey-overlay` |
| `Super + Enter` | 打开终端 | `alacritty` |
| `Super + Shift + Enter` | 打开**浮动**终端 | `alacritty --class floating_terminal` |
| `Super + D` | 应用启动器 | `fuzzel` |
| `Super + Shift + W` | 切换壁纸 | `~/.config/wallpaper/script/awww-rofi.sh` |
| `Super + G` | 截图与录屏菜单 | `~/.config/hypr/scripts/capture.sh` |
| `Super + E` | 文件管理器 | `alacritty -e yazi` |
| `Super + B` | 打开 Chrome | `google-chrome-stable` |
| `Super + Shift + B` | 打开 Zen Browser | `zen` |
| `Super + N` | Neovim | `alacritty -e nvim` |

### Noctalia 桌面 Shell 面板

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + S` | 多功能启动器（launcher 面板） |
| `Super + Shift + V` | 剪贴板历史（clipboard 面板） |
| `Super + L` | 锁屏 |

### 多媒体与亮度

| 快捷键 | 功能 |
| :--- | :--- |
| `音量+` | 音量 +10% |
| `音量-` | 音量 -10% |
| `静音键` | 切换扬声器静音 |
| `麦克风静音键` | 切换麦克风静音 |
| `亮度+` | 屏幕亮度 +10% |
| `亮度-` | 屏幕亮度 -10% |

> 这些键在**锁屏状态下同样有效**（配置中的 `allow-when-locked=true`）。

### 会话与窗口

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + O` | 概览模式（缩略显示所有窗口与工作区） |
| `Super + Q` | 关闭当前窗口 |
| `Print` | 交互式选择区域截图 |
| `Ctrl + Print` | 截取整个屏幕 |
| `Alt + Print` | 截取当前窗口 |
| `Super + Esc` | 切换"快捷键抑制"（远程桌面时用，始终不会被抑制） |
| `Super + Shift + E` | 退出 Niri（会先弹确认框） |
| `Ctrl + Alt + Delete` | 退出 Niri |
| `Super + Shift + P` | 关闭显示器背光（动鼠标或按键恢复） |

### 焦点移动

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + ←` / `Super + H` | 焦点移到左侧的列 |
| `Super + →` / `Super + L` | 焦点移到右侧的列 |
| `Super + ↑` / `Super + K` | 焦点移到列内上方窗口 |
| `Super + ↓` / `Super + J` | 焦点移到列内下方窗口 |
| `Super + Home` | 跳到当前列的第一个窗口 |
| `Super + End` | 跳到当前列的最后一个窗口 |

### 移动窗口 / 列

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + Ctrl + ←` / `Super + Ctrl + H` | 把整列向左移动 |
| `Super + Ctrl + →` / `Super + Ctrl + L` | 把整列向右移动 |
| `Super + Ctrl + ↑` / `Super + Ctrl + K` | 窗口在列内上移 |
| `Super + Ctrl + ↓` / `Super + Ctrl + J` | 窗口在列内下移 |
| `Super + Ctrl + Home` | 把整列移到最前 |
| `Super + Ctrl + End` | 把整列移到最后 |

### 列的合并与拆分

Niri 以「列」为单位组织窗口，以下快捷键用于调整窗口归属哪一列。

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + [` | 并入左侧的列；若已独立则向左弹出为独立列 |
| `Super + ]` | 并入右侧的列；若已独立则向右弹出为独立列 |
| `Super + ,` | 把右侧的窗口吸收到当前列底部 |
| `Super + .` | 把当前列底部的窗口弹出到右侧 |

### 多显示器

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + Shift + ←/→/↑/↓` | 焦点移到对应方向的显示器 |
| `Super + Shift + H/J/K/L` | 同上（Vim 风格键位） |
| `Super + Shift + Ctrl + ←/→/↑/↓` | 把整列移到对应方向的显示器 |
| `Super + Shift + Ctrl + H/J/K/L` | 同上（Vim 风格键位） |

### 工作区

Niri 采用**动态工作区**，数量随使用自动增减，因此以下为「相对」切换。

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + PageDown` / `Super + U` | 切换到下一个工作区 |
| `Super + PageUp` / `Super + I` | 切换到上一个工作区 |
| `Super + 1` ~ `Super + 9` | 按编号切换到指定工作区（超出数量时落到末尾空工作区） |
| `Super + Ctrl + PageDown` / `Super + Ctrl + U` | 把当前列移到下一个工作区 |
| `Super + Ctrl + PageUp` / `Super + Ctrl + I` | 把当前列移到上一个工作区 |
| `Super + Ctrl + 1` ~ `Super + Ctrl + 9` | 把当前列移到指定编号工作区 |
| `Super + Shift + PageDown` / `Super + Shift + U` | 整个工作区向下移动（改变排列顺序） |
| `Super + Shift + PageUp` / `Super + Shift + I` | 整个工作区向上移动 |

### 滚轮快捷键

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + 滚轮上下` | 切换工作区（150ms 冷却，避免切换过快） |
| `Super + Ctrl + 滚轮上下` | 把当前列移到上/下工作区 |
| `Super + 滚轮左右` | 焦点移到左/右侧的列 |
| `Super + Ctrl + 滚轮左右` | 整列向左/右移动 |
| `Super + Shift + 滚轮上下` | 焦点移到左/右侧的列（模拟部分应用的横向滚动习惯） |
| `Super + Ctrl + Shift + 滚轮上下` | 整列向左/右移动 |

### 尺寸调整

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + R` | 循环切换预设列宽（1/3 → 1/2 → 2/3） |
| `Super + Shift + R` | 循环切换预设窗口高度 |
| `Super + Ctrl + R` | 重置窗口高度为均分 |
| `Super + F` | 最大化当前列 |
| `Super + Shift + F` | 全屏当前窗口 |
| `Super + Ctrl + F` | 把列扩展到剩余可用宽度 |
| `Super + C` | 将当前列居中显示 |
| `Super + Ctrl + C` | 把所有完全可见的列整体居中 |
| `Super + -` | 列宽 -10% |
| `Super + =` | 列宽 +10% |
| `Super + Shift + -` | 窗口高度 -10% |
| `Super + Shift + =` | 窗口高度 +10% |

### 浮动与标签页

| 快捷键 | 功能 |
| :--- | :--- |
| `Super + V` | 窗口在「浮动」与「平铺」之间切换 |
| `Super + Shift + V` | 焦点在浮动窗口与平铺窗口之间切换 |
| `Super + W` | 当前列改为「标签页」显示（竖排标签），替代上下堆叠 |

---

## 两套环境的对照表

日常最常用的操作，两套环境的按键对照：

| 功能 | Hyprland | Niri |
| :--- | :--- | :--- |
| 打开终端 | `Super + Enter` | `Super + Enter` |
| 应用启动器 | `Super + D`（rofi） | `Super + D`（fuzzel） |
| 关闭窗口 | `Super + Q` | `Super + Q` |
| 锁屏 | `Super + L` | `Super + L` |
| 浏览器 | `Super + B` / `Super + Shift + B` | `Super + B` / `Super + Shift + B` |
| 文件管理器 | `Super + E` | `Super + E` |
| 截图菜单 | `Super + G` | `Super + G` |
| 壁纸切换 | `Super + Shift + W` | `Super + Shift + W` |
| 电源菜单 | `Super + Shift + Esc`（wlogout） | `Super + Shift + E`（退出确认） |
| 重载配置 | `Super + Shift + R` | 自动或 `niri msg action do-reload-config` |
| 焦点移动 | `Super + 方向键` | `Super + 方向键` 或 `Super + H/J/K/L` |
| 切换工作区 | `Super + 1`~`0` | `Super + 1`~`9` |
| 全屏 | `Super + F` | `Super + Shift + F` |
| 浮动切换 | `Super + P` | `Super + V` |

> 注意差异：**全屏**与**浮动**在两套环境中按键不同；
> Niri 的 `Super + F` 是「最大化列」而非全屏窗口。

---

## 其它常用快捷键

### 输入法（Fcitx5）

| 快捷键 | 功能 | 配置位置 |
| :--- | :--- | :--- |
| `Super + Space` | 切换中 / 英文输入法 | `home/youth/fcitx5/fcitx5.nix` |

输入法组顺序为：美式键盘（默认）→ Rime。

### 终端内（tmux）

| 快捷键 | 功能 |
| :--- | :--- |
| `Ctrl + B` 然后按方向键 | 在分屏之间移动焦点 |
| `Ctrl + B` 然后 `"` / `%` | 横向 / 纵向分屏 |
| `Ctrl + B` 然后 `[` | 进入复制模式（vi 键位：`h/j/k/l`、`/` 搜索） |

> tmux 前缀键为默认 `Ctrl + B`，未在本仓库中修改。
> 会话的自动保存 / 恢复由 tmux-continuum 插件完成（每 60 分钟一次）。

### rofi / fuzzel 菜单内

| 按键 | 功能 |
| :--- | :--- |
| 直接输入 | 模糊搜索候选项 |
| `Enter` | 确认选择 |
| `Esc` | 取消退出 |
| `←` `→` | 左右移动光标 / 切换图标网格列 |
| `↑` `↓` | 上下移动光标（网格模式下跨行） |

---

## 如何修改快捷键

| 桌面环境 | 配置文件 | 改完后如何生效 |
| :--- | :--- | :--- |
| Hyprland | `home/youth/hyprland/hypr/hyprland.lua` 第 10 节 | 按 `Super + Shift + R`，或执行 `hyprctl reload` |
| Niri | `home/youth/niri/config.kdl` 的 `binds { }` 块 | 保存即自动重载，或执行 `niri msg action do-reload-config` |

修改后需要重建系统才会写入用户目录：

```bash
sudo nixos-rebuild switch --flake .#levi
```

### 语法要点

**Hyprland**（Lua）：

```lua
hl.bind(mainMod .. "return", hl.dsp.exec_cmd(terminal))
--    ↑ 按键组合                    ↑ dispatcher（动作）
```

- 按键写法：`SUPER + RETURN`、`SUPER + SHIFT + B`、`mouse:272`
- 常用 dispatcher：
  - `hl.dsp.exec_cmd("命令")` — 执行程序
  - `hl.dsp.window.kill()` / `.fullscreen_state({...})` / `.float({...})` / `.move({...})` — 窗口操作
  - `hl.dsp.focus({ direction = "l" })` / `.focus({ workspace = 1 })` — 移动焦点
  - `hl.dsp.layout("togglesplit")` — 切换布局
  - `hl.dsp.workspace.toggle_special("名字")` — 特殊工作区

**Niri**（KDL）：

```kdl
Mod+D hotkey-overlay-title="打开应用启动器: fuzzel" { spawn "fuzzel"; }
// ↑按键    ↑速查浮层中显示的文字                ↑动作
```

- 常用属性：
  - `hotkey-overlay-title="..."` — 在速查浮层中显示的说明文字
  - `allow-when-locked=true` — 锁屏时仍然可用
  - `repeat=false` — 长按不重复触发
  - `cooldown-ms=150` — 触发冷却时间（滚轮绑定常用）
- 动作写在 `{ }` 内，多个动作用 `;` 分隔。

### 查看当前生效的快捷键

```bash
# Niri：显示内置速查浮层
niri msg action show-hotkey-overlay

# Hyprland：列出所有已绑定的按键与 dispatcher
hyprctl binds
```
