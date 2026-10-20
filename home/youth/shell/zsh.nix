# ============================================================================
# home/youth/shell/zsh.nix —— zsh 默认 Shell 与提示符配置
# ----------------------------------------------------------------------------
# 作用：
#   1. 启用 zsh，并集成 oh-my-zsh（git 插件）、语法高亮、自动建议；
#   2. 配置常用命令别名；
#   3. 提供 starship 提示符，同时保留 powerlevel10k 的可选加载方式
#      （配置见同目录 p10k.zsh，由 p10k 工具自动生成，不手工编辑）。
#
# 切换提示符：
#   当前生效：starship（见 programs.starship）
#   改用 p10k ：取消 initContent 中末尾几行的注释，并注释掉 starship.enable
# ============================================================================
# 模块参数：pkgs —— 包集合（用于引用 zsh-powerlevel10k）；... —— 接受其它未声明的参数
{pkgs, ...}: {
    # ------------------------------------------------------------------------
    # 提示符主题包
    # ------------------------------------------------------------------------
    home.packages = with pkgs; [
      zsh-powerlevel10k # 备选提示符：powerlevel10k（配置文件 p10k.zsh）
    ];

    # 把仓库中的 p10k.zsh 链接到 ~/.p10k.zsh
    # 说明：p10k.zsh 由 `p10k configure` 自动生成，文件大且无需手工注释
    home.file.".p10k.zsh" = {
      source = ./p10k.zsh; # 内容来源：本仓库内文件
    };

    # ------------------------------------------------------------------------
    # starship 提示符（当前默认使用）
    # ------------------------------------------------------------------------
    programs.starship = {
      enable = true; # 启用 starship
      enableZshIntegration = true; # 自动注入 zsh 初始化脚本
      settings = {
        add_newline = false; # 提示符前不额外换行，节省屏幕空间
      };
    };

    # 让 zsh 的命令补全、历史记录等能力由 home-manager 注入
    home.shell.enableZshIntegration = true;

    # ----------------------------------------------------------------------
    # zsh 本体配置
    # ----------------------------------------------------------------------
    programs.zsh = {
      enable = true; # 启用 zsh（与 configuration.nix 中 users.users.youth.shell 呼应）

      # 常用别名，等价于写入 ~/.zshrc
      shellAliases = {
        ll = "ls -l"; # 长格式列表
        la = "ls -la"; # 包含隐藏文件
        lta = "ls --tree --long --icons"; # 树形列表（eza 命令，需自行安装）
        nv = "nvim"; # 打开 neovim
        snv = "sudo nvim"; # 以 root 权限编辑配置文件
        ff = "fastfetch"; # 显示系统信息
        nlg = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations"; # 列出所有系统代次
        ncg = "sudo nix-collect-garbage -d"; # 清理 Nix store 中无用的旧代次
      };

      # --------------------------------------------------------------------
      # 交互式 shell 启动时执行的额外内容
      # 说明：前两行用于加载「不纳入 Git 管理」的个人脚本，
      #       便于存放机器专属配置与密钥而不污染仓库。
      # --------------------------------------------------------------------
      initContent = ''
        [ -f ~/.zsh_secrets ] && source ~/.zsh_secrets   # 存放敏感变量（勿提交到 Git）
        [ -f ~/.zsh_local ] && source ~/.zsh_local       # 存放机器专属别名（勿提交到 Git）

        # --------------------------------------------------------------------
        # 一、环境变量
        # --------------------------------------------------------------------
        export EDITOR=nvim           # 默认编辑器（git / crontab 等会读取）
        export VISUAL=nvim           # 需要全屏编辑的程序（如 git commit）
        export SYSTEMD_EDITOR=nvim   # systemctl edit 等 systemd 命令使用的编辑器
        export MANPAGER="sh -c 'col -bx | bat -l man -p'"  # man 手册交给 bat 渲染（高亮 + 分页）
        export BAT_THEME=Catppuccin-mocha  # 与 tool.nix 中 catppuccin.bat 的 flavor 保持一致

        # --------------------------------------------------------------------
        # 二、命令历史
        # 说明：也可改用声明式写法 programs.zsh.history = { size = 10000; ... };
        #       此处直接写 setopt，便于集中查看与临时调整。
        # --------------------------------------------------------------------
        export HISTSIZE=10000           # 内存中保留的历史条数
        export SAVEHIST=10000           # 落盘保存的历史条数
        export HISTFILE=~/.zsh_history  # 历史文件路径
        setopt APPEND_HISTORY           # 多终端追加写入，而非互相覆盖
        setopt INC_APPEND_HISTORY       # 命令执行完立即写入，不必等 shell 退出
        setopt HIST_IGNORE_ALL_DUPS     # 重复命令只保留一条
        setopt HIST_IGNORE_SPACE        # 以空格开头的命令不记录（临时隐私命令）
        setopt HIST_REDUCE_BLANKS       # 去除历史记录中多余的空格
        setopt HIST_VERIFY              # 历史展开（!! 等）先显示，回车确认后再执行

        # --------------------------------------------------------------------
        # 三、交互行为
        # --------------------------------------------------------------------
        setopt AUTO_CD                # 只输入目录名即可进入该目录（省去 cd）
        setopt CORRECT                # 目录名拼错时给出纠正提示
        setopt INTERACTIVE_COMMENTS   # 允许在命令行中用 # 书写注释
        unsetopt BEEP                 # 出错时不发出系统蜂鸣声
        stty -ixon 2>/dev/null        # 解除 Ctrl+S / Ctrl+Q 流控，把 Ctrl+S 让给程序（如 fzf）

        # --------------------------------------------------------------------
        # 四、补全外观
        # 说明：compinit 由 home-manager 自动调用（programs.zsh.enableCompletion 默认开启），
        #       这里只写 zstyle，避免重复初始化补全系统。
        # --------------------------------------------------------------------
        zstyle ':completion:*' menu select                   # 方向键选择候选，而非逐个循环填充
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # 大小写不敏感补全
        zstyle ':completion:*' special-dirs true             # 支持 ../.. 这类特殊目录补全
        zstyle ':completion:*' rehash true                   # 新安装命令无需重开 shell 也能补全
        zstyle ':completion:*' list-colors "di=34:ln=35:so=32:ex=31"  # 候选按类型着色：蓝目录/紫软链等

        # --------------------------------------------------------------------
        # 五、按键绑定（vi 风格编辑）
        # 说明：bindkey -v 启用 vi 行编辑后，
        #       Esc / Ctrl+[ 进入 normal 模式（移动、删除、粘贴），i / a 回到插入模式。
        #       fzf 的 Ctrl+R / Ctrl+T / Alt+C 在插入模式下照常可用。
        # --------------------------------------------------------------------
        export KEYTIMEOUT=1            # Esc 后的判定等待压缩到最小（10ms），模式切换不再卡顿
        bindkey -v                     # vi 风格行编辑（关键开关）

        # ---- 两种模式通用的光标移动 ----
        bindkey -M viins '^[[H' beginning-of-line  # Home：跳到行首（插入模式）
        bindkey -M viins '^[[F' end-of-line        # End：跳到行尾（插入模式）
        bindkey -M vicmd '^[[H' beginning-of-line  # Home：跳到行首（normal 模式）
        bindkey -M vicmd '^[[F' end-of-line        # End：跳到行尾（normal 模式）
        bindkey -M vicmd 'H' beginning-of-line     # normal 模式 H：跳到行首
        bindkey -M vicmd 'L' end-of-line           # normal 模式 L：跳到行尾

        # ---- 删除与行编辑 ----
        bindkey -M viins '^[[3~' delete-char       # Delete：删除光标处字符（插入模式）
        bindkey -M vicmd '^[[3~' delete-char       # Delete：删除光标处字符（normal 模式）
        bindkey -M viins '^U' backward-kill-line   # Ctrl+U：删除到行首，而不是整行
        bindkey -M viins '^[[1;5C' forward-word    # Ctrl+右：右移一个单词
        bindkey -M viins '^[[1;5D' backward-word   # Ctrl+左：左移一个单词

        # ---- normal 模式下用 $EDITOR 编辑当前命令行 ----
        autoload -Uz edit-command-line && zle -N edit-command-line  # 注册 edit-command-line 部件
        bindkey -M vicmd 'v' edit-command-line  # 按 v 打开 nvim 编辑长命令，写盘后自动执行

        # --------------------------------------------------------------------
        # 六、常用小函数
        # --------------------------------------------------------------------
        mkcd() { mkdir -p "$1" && cd "$1"; }  # 创建目录并立即进入

        # 登录时显示系统信息（会略微拖慢终端启动，需要请去掉下一行注释）
        # fastfetch

        # --------------------------------------------------------------------
        # Seven、config about app
        # --------------------------------------------------------------------
        eval "$(mise activate zsh)" # activate mise in zsh

        # ---- 以下为「切换到 powerlevel10k」所需的加载语句 ----
        # source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        # [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

        # ---- 备选方案：从 agenix 解密目录直接 source 密钥文件 ----
        #      （agenix 加解密流程当前已停用，恢复后才可使用）
        # for file in /run/agenix/ai_api_key.zsh; do
        #   [ -f "$file" ] && source "$file"
        # done
      '';

      autosuggestion.enable = true; # 依据历史输入给出灰字建议（zsh-autosuggestions）
      syntaxHighlighting.enable = true; # 命令语法着色（zsh-syntax-highlighting）

      oh-my-zsh = {
        enable = true; # 启用 oh-my-zsh 插件体系
        plugins = [
          "git" # git 插件：显示当前仓库状态，并附带常用 git 别名
        ];
      };
    };
}
