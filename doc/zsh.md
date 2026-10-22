# zsh 配置说明

本仓库中 zsh 相关文件的分工：

| 文件 | 作用 |
| --- | --- |
| `vars.nix` → `shell.bin` / `shell.editor` | 登录 shell 名、默认编辑器（`EDITOR`） |
| `modules/nixos/packages.nix` | 系统层安装 `zsh`、开启 `programs.zsh.enable` |
| `modules/nixos/user.nix` | 把用户的登录 shell 设为 zsh |
| `modules/home/zsh.nix` | 用 `home.file.".zshrc"` 托管配置文件 |
| `dotfiles/zsh/.zshrc` | 真正的 `.zshrc` 内容（可当普通 dotfile 阅读/改） |

## 一、为什么不在 home-manager 里用 `programs.zsh.enable`

`programs.zsh` 会自己生成 `~/.zshrc` / `~/.zshrc.d`，与"用 `home.file` 管理 dotfile"的要求冲突（会互相覆盖、报 collision）。
所以这里**只在 NixOS 层**启用 `programs.zsh.enable = true`，作用是"让系统里有 zsh、可以作为登录 shell"；
配置文件本身完全由 `home.file.".zshrc"` 提供。

> NixOS 层的 `programs.zsh.enable` 只写 `/etc` 下的系统级 zsh 配置，不会动 `~/.zshrc`，因此不冲突。

## 二、占位符机制（改一处，全局生效）

`dotfiles/zsh/.zshrc` 里的 `@editor@`、`@homeDir@`、`@hostname@`、`@repoDir@` 是占位符，
由 `pkgs.replaceVars` 在构建时替换：

```nix
# modules/home/zsh.nix
home.file.".zshrc".source =
  pkgs.replaceVars ../../dotfiles/zsh/.zshrc {
    editor   = vars.shell.editor;      # vars.nix
    homeDir  = vars.homeDirectory;     # vars.nix
    hostname = vars.hostname;          # vars.nix
    repoDir  = vars.repoDir;           # vars.nix
  };
```

⚠️ 两个坑（replaceVars 会**故意构建失败**来提醒你）：

1. 文件里出现了 `@xxx@` 但 `modules/home/zsh.nix` 里没提供同名键 → 报错退出；
2. `modules/home/zsh.nix` 里提供了文件里没有的键 → 报错退出。

所以：**加占位符就要同时加变量，删占位符就要同时删变量**。

## 三、.zshrc 段落逐项说明

### 1. 环境变量

```zsh
export EDITOR=vim
export PAGER=less
typeset -U path                 # -U：去重，避免重复 PATH
path=(~/.local/bin ~/.go/bin $path)
```

`~/.local/bin` 放第一位，因为 `uv`、`pnpm`、`nix profile install` 都会往这里放可执行文件，
必须能覆盖系统自带版本。

### 2. 历史记录

| setopt | 含义 |
| --- | --- |
| `appendhistory` | 追加而非覆盖历史文件 |
| `sharehistory` | 多个终端实时共享历史（很实用） |
| `incappendhistory` | 命令执行完立刻落盘 |
| `hist_ignore_all_dups` | 去掉重复条目 |
| `hist_ignore_space` | 以空格开头的命令不记录（写密码时用） |
| `hist_reduce_blanks` | 折叠多余空格 |
| `hist_verify` | `!!` 展开后先显示再执行，防误操作 |
| `extended_history` | 记录时间戳（`history -i` 可看时间） |

### 3. 补全

```zsh
autoload -Uz compinit && compinit -d ~/.cache/zsh/zcompdump
zstyle ':completion:*' menu select          # 方向键选择补全项
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # 大小写不敏感
```

补全缓存放在 `~/.cache/zsh/`，避免每次启动重扫 `$PATH`（也能避免"zsh 启动慢"）。
NixOS 上命令补全由包自带的 `share/zsh/site-functions` 提供，无需额外配置。

### 4. 按键绑定

```zsh
bindkey -e                       # emacs 风格（Ctrl+A/E/U/K 可用）
# 想用 vi 风格就改成 bindkey -v（$KEYTIMEOUT=10 减少 Esc 延迟）
```

`up-line-or-beginning-search`：输入 `git` 再按 ↑，只搜以 `git` 开头的历史，非常提效。

### 5. 提示符

```zsh
PROMPT='%F{yellow}%n@%m%f %F{blue}%~%f %F{green}❯%f '
RPROMPT='%F{240}%*%f'
```

| 转义 | 含义 |
| --- | --- |
| `%n` | 用户名 | 
| `%m` | 主机名（短） |
| `%~` | 当前目录（`~` 缩写家目录） |
| `%F{color}` / `%f` | 前景色开始 / 结束 |
| `%*` | 当前时间 |

颜色可用 `yellow/red/green/blue/magenta/cyan/white/black`，或用 `%{039}` 这类 256 色号。

### 6. 别名

`rebuild` / `rebuild-test` / `flake-update` 三个别名直接绑定了本仓库，
需要仓库克隆在 `~/$repoDir`（默认 `~/youth-nixos`）；改位置就改 `vars.nix` 的 `repoDir`。

## 四、常见扩展怎么做

### 加一个 oh-my-zsh 插件（推荐方式：Nix 安装 + 手写 source）

以 `zsh-autosuggestions` 为例：

```nix
# modules/home/packages.nix
home.packages = with pkgs; [
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-substring-search
];
```

```zsh
# dotfiles/zsh/.zshrc 末尾追加
source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```
> 注意：`.zshrc` 里**不能**直接用 `${pkgs.xxx}`，因为它是纯文本文件不是 Nix。
> 解决办法：在 `modules/home/zsh.nix` 里再加一个占位符，例如
> `autosuggest = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";`
> 然后 `.zshrc` 里写 `source @autosuggest@`。

```nix
# modules/home/zsh.nix
pkgs.replaceVars ../../dotfiles/zsh/.zshrc {
  editor = vars.shell.editor;
  homeDir = vars.homeDirectory;
  hostname = vars.hostname;
  repoDir = vars.repoDir;
  autosuggest = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";
  syntaxhl = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
};
```

```zsh
# dotfiles/zsh/.zshrc
source @autosuggest@
source @syntaxhl@
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
```

### 换成 starship 提示符

```nix
# modules/home/packages.nix 里加 pkgs.starship
# 新建 modules/home/starship.nix
{ pkgs, ... }: {
  home.file.".config/starship.toml".text = ''
    add_newline = false
    [character]
    success_symbol = "[❯](bold green)"
  '';
}
```
再在 `.zshrc` 末尾加 `eval "$(starship init zsh)"`，并把上面的 `PROMPT/RPROMPT` 两行删掉。

### 让 zsh 成为默认 shell（已由 NixOS 配置完成）

```nix
users.users.<name>.shell = pkgs.zsh;   # modules/nixos/user.nix 已做
```

手动检查：`echo $SHELL` 应为 `/run/current-system/sw/bin/zsh` 或 `/nix/store/.../bin/zsh`。

## 五、排错

| 现象 | 原因 / 处理 |
| --- | --- |
| `~/.zshrc` 只读，改不了 | 文件是 `/nix/store` 的软链。改 `dotfiles/zsh/.zshrc` 后 `rebuild`；或写 `~/.zshrc.local` |
| 改了 `.zshrc` 没生效 | 需要 `sudo nixos-rebuild switch`；改完立即看效果可 `exec zsh` |
| `compinit: insecure directories` | 执行 `compaudit | xargs chmod g-w` |
| 启动慢 | 确认 `compinit -d ~/.cache/zsh/zcompdump`；`zsh -x -i -c exit` 可追踪耗时 |
| 命令找不到 | `rehash`；或确认包确实装进了 `home.packages` |
