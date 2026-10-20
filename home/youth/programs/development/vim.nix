# ============================================================================
# home/youth/programs/development/vim.nix —— vim（救援用）基础配置
# ----------------------------------------------------------------------------
# 目的：提供一份「随时可用」的最小 vim 配置。
#   - 系统引导、GRUB、紧急修复时可能只有 vim 可用，此时读取不到
#     ~/.config/vim/vimrc（该文件由 home-manager 生成，可能尚未就绪）；
#   - 因此把关键设置直接内联在 extraConfig 中，保证任何情况下都有合理默认值。
#
# 注意：日常主力编辑器是 Neovim（nvim），其完整插件配置由 flake.nix 中的
#       CookNixvim 提供，本文件不涉及。
#
# 选项前缀说明：
#   programs.vim        —— 写入 ~/.config/vim/vimrc（用户级配置）
#   extraConfig         —— 直接追加到生成的 vimrc 末尾，优先级高于默认配置
#   " 注释符           —— vim 脚本的双引号注释
# ============================================================================
# 形参使用 `_` 表示不需要任何 home-manager 模块参数
_: {
  programs.vim.enable = true; # 安装 vim（configuration.nix 中也已装入 systemPackages 作为兜底）

  programs.vim.extraConfig = ''
        " =========================
    " 基本行为
    " =========================
    set nocompatible          " 不兼容 vi 老模式
    set encoding=utf-8
    set fileencoding=utf-8
    set hidden                " 允许切换 buffer 不保存
    set mouse=a               " 启用鼠标
    set clipboard=unnamedplus " 使用系统剪贴板（Wayland/X11）

    " =========================
    " 显示相关
    " =========================
    set number                " 行号
    set relativenumber        " 相对行号
    set cursorline            " 高亮当前行
    set showcmd               " 显示正在输入的命令
    set showmode              " 显示模式
    set ruler                 " 显示光标位置
    set signcolumn=yes        " 永远显示符号列（避免抖动）

    " =========================
    " 缩进 / 格式
    " =========================
    set tabstop=2             " Tab 显示宽度
    set shiftwidth=2          " 缩进宽度
    set softtabstop=2
    set expandtab             " Tab 转空格
    set autoindent
    set smartindent

    " =========================
    " 搜索
    " =========================
    set ignorecase            " 搜索忽略大小写
    set smartcase             " 有大写则区分
    set incsearch             " 实时搜索
    set hlsearch              " 高亮搜索结果

    " 取消搜索高亮
    nnoremap <Esc> :nohlsearch<CR>

    " =========================
    " 编辑体验
    " =========================
    set backspace=indent,eol,start
    set wrap                  " 自动换行
    set linebreak             " 不在单词中断行
    set scrolloff=5           " 上下保留 5 行
    set sidescrolloff=5

    " =========================
    " 语法 & 文件类型
    " =========================
    syntax on
    filetype plugin indent on
  '';
}
