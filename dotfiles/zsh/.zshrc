# =============================================================================
#  .zshrc —— zsh 交互式配置
# -----------------------------------------------------------------------------
#  部署方式：home-manager 的 home.file → ~/.zshrc
#  变量来源：vars.nix，占位符 @editor@ / @homeDir@ / @hostname@ / @repoDir@
#  详细说明（每个段落怎么改、还能加什么）：doc/zsh.md
#
#  ⚠️ 该文件由 nix 托管，默认只读。想“本机临时加东西”，写到 ~/.zshrc.local
#     （本文件最后会自动 source 它），这样不会被下次 switch 覆盖。
# =============================================================================

# ---- 基础环境变量 ------------------------------------------------------------
export EDITOR=@editor@
export VISUAL=$EDITOR
export PAGER=less
export LESS="-R -F -X"

# PATH：把 ~/.local/bin 放前面（uv / pnpm / 自己装的脚本都会放这里）
typeset -U path
path=(
  @homeDir@/.local/bin
  @homeDir@/go/bin
  $path
)
export PATH

# ---- 历史记录 ----------------------------------------------------------------
HISTFILE=@homeDir@/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

setopt appendhistory          # 追加而不是覆盖
setopt sharehistory           # 多终端共享历史
setopt incappendhistory       # 命令执行完立刻写入
setopt hist_ignore_all_dups   # 去重
setopt hist_ignore_space      # 以空格开头的命令不记录
setopt hist_reduce_blanks     # 去掉多余空格
setopt hist_verify            # 展开历史后先确认再执行
setopt extended_history       # 记录时间戳

# ---- 目录与杂项行为 ----------------------------------------------------------
setopt auto_cd                # 输入目录名直接 cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt correct                # 命令纠错提示
setopt interactive_comments   # 交互模式下支持 # 注释
setopt no_beep                # 不要响铃

# ---- 补全 --------------------------------------------------------------------
mkdir -p @homeDir@/.cache/zsh
autoload -Uz compinit && compinit -d @homeDir@/.cache/zsh/zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # 大小写不敏感
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes

# ---- 按键绑定（emacs 风格）----------------------------------------------------
bindkey -e
bindkey '^[[1;5C' forward-word      # ctrl + →
bindkey '^[[1;5D' backward-word     # ctrl + ←
bindkey '^[[H'    beginning-of-line # home
bindkey '^[[F'    end-of-line       # end
bindkey '^[[3~'   delete-char       # delete

# ↑/↓ 按已输入前缀搜索历史
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# ---- 提示符（不依赖 oh-my-zsh / starship，保持精简）----------------------------
autoload -Uz colors && colors
#  左：user@host  当前目录   右：上一条命令耗时
PROMPT='%F{yellow}%n@%m%f %F{blue}%~%f %F{green}❯%f '
RPROMPT='%F{240}%*%f'

# ---- 别名 --------------------------------------------------------------------
alias ll='ls -alFh --color=auto'
alias la='ls -A --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias lg='lazygit'
alias y='yazi'
alias py='python3'
alias v='$EDITOR'

# 重建系统（假设仓库克隆在 @homeDir@/@repoDir@）
alias rebuild='sudo nixos-rebuild switch --flake @homeDir@/@repoDir@#@hostname@'
alias rebuild-test='sudo nixos-rebuild test --flake @homeDir@/@repoDir@#@hostname@'
alias flake-update='cd @homeDir@/@repoDir@ && nix flake update && cd -'

# ---- kitty 终端集成（仅在 kitty 内运行时生效）---------------------------------
if [ -n "$KITTY_INSTALLATION_DIR" ]; then
  export PATH="$KITTY_INSTALLATION_DIR/../kitty/bin:$PATH"
  autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
  kitty-integration
  unfunction kitty-integration
fi

# ---- 本机私有配置（不会被 nix 覆盖）--------------------------------------------
[ -f "@homeDir@/.zshrc.local" ] && source "@homeDir@/.zshrc.local"
