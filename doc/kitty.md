# kitty 配置说明

## 一、文件分工

| 文件 | 作用 |
| --- | --- |
| `vars.nix` → `fonts.mono.*` / `theme.*` | 字体族名、字号、配色 |
| `modules/home/kitty.nix` | 用 `home.file.".config/kitty/kitty.conf"` 托管 |
| `dotfiles/kitty/kitty.conf` | 真正的配置文件 |
| `modules/nixos/desktop.nix` | 系统层安装 Maple Mono CN 字体 |

字体由 **NixOS 层**安装（`fonts.packages`），因为要写进 fontconfig；
配置由 **home-manager 层**用 `home.file` 托管，符合"dotfile 用 `home.file` 管理"的要求。

## 二、占位符（同 zsh，改 vars.nix 即生效）

```nix
# modules/home/kitty.nix
pkgs.replaceVars ../../dotfiles/kitty/kitty.conf {
  fontFamily = vars.fonts.mono.family;   # "MapleMonoNormal NF CN"
  fontSize   = toString vars.fonts.mono.size;
  accent     = vars.theme.accent;
  background = vars.theme.background;
  foreground = vars.theme.foreground;
  cursor     = vars.theme.cursor;
};
```

同样的铁律：文件里的 `@xxx@` 与这里的键必须**一一对应**，否则构建失败。

## 三、字体：Maple Mono CN

nixpkgs 26.05 里包名是 `pkgs.maple-mono`，它是一个**属性集合**，可选变体：

| 变体（`vars.fonts.mono.variant`） | 说明 |
| --- | --- |
| `Normal-NF-CN`（当前使用） | 正常连字 + Nerd Font 图标 + 中文 |
| `Normal-CN` | 正常连字 + 中文（无 NF 图标） |
| `NF-CN` / `NF-CN-unhinted` | Nerd Font + 中文 |
| `CN` / `CN-unhinted` | 纯中文等宽 |
| `NF` / `truetype` / `variable` / `woff2` / `opentype` | 不含中文的其它形态 |

组合规则是 `MapleMono<连字变体>-<字形变体>`，参考 `pkgs/data/fonts/maple-font/default.nix`。

### 字体族名怎么确认（重要）

`font_family` 必须用 **fontconfig 看到的家族名**，写错会静默回退到默认字体：

```bash
fc-list | grep -i maple
# 输出示例：.../MapleMonoNormal-NF-CN.ttf: MapleMonoNormal NF CN:style=Regular
#                                          ^^^^^^^^^^^^^^^^^^^^^ ← 填到 vars.nix 的 family

# 精确验证 kitty 会用什么字体：
fc-match "MapleMonoNormal NF CN"
```

若与默认值不同，改 `vars.nix`：

```nix
fonts.mono.family = "MapleMonoNormal NF CN";
```

Nerd Font 图标验证（装了带 NF 的变体才有用）：

```bash
printf '\ue718 \uf015 \uf07c \ue795\n'   # 应能看到图标而不是豆腐块
```

## 四、配置项逐项说明

### 外观精简

| 选项 | 值 | 说明 |
| --- | --- | --- |
| `hide_window_decorations` | `yes` | 去掉系统标题栏，窗口边框交给 niri 画（与需求"淡鹅黄边框"一致） |
| `background_opacity` | `0.94` | 半透明；改成 `1.0` 关闭。niri 下需合成器支持，niri 原生支持 |
| `window_padding_width` | `8` | 内容与窗口边缘的间距 |
| `placement_strategy` | `center` | 单窗口居中 |
| `confirm_os_window_close` | `0` | 关窗不弹确认 |
| `enable_audio_bell` | `no` | 关掉响铃 |

### 标签栏

| 选项 | 说明 |
| --- | --- |
| `tab_bar_edge top` | 标签栏在顶部 |
| `tab_bar_style powerline` | 斜角风格（其它可选 `fade` / `separator` / `hidden`） |
| `tab_bar_min_tabs 2` | 少于 2 个窗口时隐藏标签栏（更精简）；想常显改成 `1` |
| `active_tab_background @accent@` | 当前标签底色 = 主题淡鹅黄 |

### 滚动 / 历史

- `scrollback_lines 10000`：回滚缓冲行数。
- `scrollback_pager less --chop-long-lines`：按 `Ctrl+Shift+G` / `F3` 进入分页查看。
- `mouse_hide_wait 3.0`：停止输入 3 秒后隐藏鼠标指针。

### 光标

- `cursor_shape block`（其它：`beam` 竖线 / `underline`）
- `cursor_blink_interval 0`：不闪烁（改成 `0.5` 就闪）

### 配色

只定义 6 个关键项（前景/背景/选中/URL/活动边框/光标），其余由 kitty 默认推导，
这样换主题只改 `vars.nix` 的 `theme.*` 即可。**想用现成主题**：

```bash
mkdir -p ~/.config/kitty/themes
# 下载一个 kitty 主题到 ~/.config/kitty/themes/xxx.conf
```
在 `kitty.conf` 末尾加（注意：这是纯文本配置，不含占位符）：

```
include ./themes/xxx.conf
```
> 用 `home.file` 托管时，主题文件也要单独写一个 `home.file.".config/kitty/themes/xxx.conf".source = ./dotfiles/kitty/themes/xxx.conf;`。

### shell 集成

`shell_integration enabled` + `.zshrc` 里的 `kitty-integration` 提供：

- 提示符标记：可用 `Ctrl+Shift+P`(上一提示符) / `Ctrl+Shift+N`(下一提示符) 跳转；
- `clone-in-kitty`：在当前目录快速开新窗口/标签；
- `Ctrl+Shift+Up/Down` 滚动。

### 快捷键

`kitty_mod` 保持默认 `ctrl+shift`，**故意不改成 super**，避免和 niri 的 `super+*` 冲突。

## 五、常见扩展

### 分屏（splits）

kitty 原生支持，常用键（默认 `ctrl+shift`）：
`ctrl+shift+enter` 新窗口（沿用当前目录）、`ctrl+shift+t` 新标签。
方向分屏需要自己映射，例如加到 `kitty.conf`：

```
map ctrl+shift+left   neighboring_window left
map ctrl+shift+right  neighboring_window right
map ctrl+shift+up     neighboring_window up
map ctrl+shift+down   neighboring_window down
```

### 远程控制 / kittens

kitty 自带大量 `kitten`（`kitten icat` 显示图片、`kitten diff`、`kitten ssh` …），
例如让 `yazi` 能预览图片：确认 `~/.local/bin` 里有 kitty 的 `kitten`（已随包提供）。

### 改字号（不重启）

`ctrl+shift+=` / `ctrl+shift+-` / `ctrl+shift+backspace`（已在配置里映射）。

## 六、排错

| 现象 | 原因 / 处理 |
| --- | --- |
| 中文显示为方块/豆腐 | 换带 `-CN` 的变体；确认 `noto-fonts-cjk-sans` 已安装；`fc-match "sans:lang=zh"` |
| Nerd 图标是方块 | 换带 `NF` 的变体（`Normal-NF-CN`） |
| `font_family` 不生效 | 家族名写错，用 `fc-list \| grep -i maple` 核对 |
| 半透明没效果 | niri 默认支持；若无效检查是否开启了 `--single-instance` 之类的旧配置 |
| 改了配置没生效 | `sudo nixos-rebuild switch` 后重开 kitty；热加载 `Ctrl+Shift+F5` |
