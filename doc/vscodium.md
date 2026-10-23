# VSCodium（配置 / 键位 / 插件）

## 1. 配置文件在哪

| 仓库里（改这里） | 部署到（只读，别手改） |
| --- | --- |
| `dotfiles/vscodium/settings.json` | `~/.config/VSCodium/User/settings.json` |
| `dotfiles/vscodium/keybindings.json` | `~/.config/VSCodium/User/keybindings.json` |
| `dotfiles/vscodium/extensions.txt` | `~/.config/VSCodium/extensions.txt` |

部署模块：`modules/home/vscodium.nix`（用 `home.file`，和其它 dotfile 同一套约定）。
改完仓库里的文件要 `just switch` 才会生效。

> VSCodium 在 Linux 上读 `~/.config/VSCodium`（**不是** `~/.config/Code`），
> 插件目录是 `~/.vscode-oss/extensions`。

文件是 **JSONC**（可以带注释），原样保留了你原来文件里的注释。

## 2. settings.json 里的两处变量

```jsonc
"editor.fontFamily": "@fontFamily@",   // ← 构建期替换成 vars.fonts.mono.family
"editor.fontSize": @fontSize@,         // ← vars.fonts.mono.size
```

改系统字体（`vars.nix` 的 `fonts.mono.*`）后 `just switch`，VSCodium 会跟着变。

顺带把 `terminal.integrated.defaultProfile.linux` 从 `bash` 改成了 `zsh`
（本系统的登录 shell 是 zsh）。

## 3. 装插件

```bash
just code-ext          # 等价于 vscodium-install-extensions
```

脚本逐行读 `~/.config/VSCodium/extensions.txt`，执行
`codium --install-extension <id> --force`；装不上的会打 `✗`。

⚠️ **微软专有插件在 VSCodium 上装不了** —— VSCodium 只用 OpenVSX，
而下面这些只发 VS Code Marketplace（当前清单里预计会失败）：

- `ms-python.vscode-pylance`（Pylance，许可证限制）
- `ms-vscode-remote.remote-ssh` / `remote-ssh-edit` / `remote-wsl`（Remote 系列）

替代：用 `ms-python.python` + `ms-python.debugpy` 自带的语言服务，
或自己从 VSIX 装（`codium --install-extension ~/xxx.vsix`）。

常用手动命令：

```bash
codium --list-extensions
codium --uninstall-extension <id>
```

> 没走 nix 声明式装插件（`pkgs.vscode-extensions.*`）的原因：
> 要为每个插件单独构建、OpenVSX 拉取慢，且同样缺上面那几个专有插件。
> 想要声明式（重装系统后自动恢复插件）也可以，说一声我加。

## 4. ⚠️ 与 keyd 的 Alt 冲突

`Alt + h/j/k/l` 已被 keyd 映射成方向键（`doc/whichkey.md` 第 6 节），
所以 `keybindings.json` 里这几条**触发不到**（VSCodium 收到的是方向键，不是 Alt+h）：

| 键位 | 原动作 | 现状 |
| --- | --- | --- |
| `alt + h` | `moveActiveEditorGroupLeft` | 变成 ← |
| `alt + l` | `moveActiveEditorGroupRight` | 变成 → |
| `alt + j` / `alt + k` | 终端向下/向上滚动 | 变成 ↓ / ↑ |

想保留的话二选一：

1. 把它们换成 `ctrl+shift+h` / `ctrl+shift+l`（文件里已有 `ctrl+shift+h/l` 用于
   `focusLeftGroup`/`focusRightGroup`，注意别重复）
2. 换回「Alt 是普通 Alt」：`vars.nix` 里 `keyboard.altHjklArrows = false`

## 5. 主题与图标

settings.json 里已指定：

- 主题：`workbench.colorTheme = "Catppuccin Frappé"` → 需要插件 `catppuccin.catppuccin-vsc`（清单里有）
- 图标：`workbench.iconTheme = "material-icon-theme"` → 需要 `pkief.material-icon-theme`（清单里有）

插件没装好之前这两项会回退到默认主题。
