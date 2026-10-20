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
