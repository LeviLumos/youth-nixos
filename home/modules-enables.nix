# modules-enables.nix —— 用户层唯一的软件开关板（enabled 开关清单）。
# 角色：非模块，是控制文件。flake.nix 读取它生成 homeConfigurations.<host>
#   （按开关裁剪）与 homeConfigurations.all（全部强制打开，防止闲置模块腐化）；
#   home/default.nix 以参数默认值 import 它，并断言其键名与 home/ 目录下的
#   模块文件严格双向一致（多列/漏列都导致求值失败），同时经 extraSpecialArgs
#   以 enabled 注入各模块，供模块内按需启用片段。
# 约定：一个布尔对应一个 home/<name>.nix；true=安装（包+配置），
#   false=文件保留但不生效。运行时可用 koru home enable/disable 修改。
# --- enabled ---
# The single software switchboard for the user layer: one boolean per home
# module, which is also the inventory of what home/ can install.
#
#   enable: true installs the module (package + its config), false keeps the
#           file in the repo unused. One boolean, one question: installed or
#           not.
#
# The keys must match the home/ module files exactly in both directions
# (asserted in home/default.nix). So a new module that is not listed here, or a
# flag with no file, fails evaluation instead of being dropped silently.
{
  enable = {
    alacritty = false;
    bat = true;
    btop = true;
    chsrc = true;
    clipboard-history = true;
    codex = true;
    cursor-theme = true;
    drawio = true;
    eza = true;
    fastfetch = true;
    fcitx5 = true;
    fd = true;
    fzf = true;
    gh = true;
    git = true;
    gtk = true;
    imv = true;
    jq = true;
    kitty = true;
    libreoffice = true;
    neovim = true;
    niri = true;
    opencode = true;
    poppler-utils = true;
    ripgrep = true;
    satty = true;
    tty-login = true;
    unrar = true;
    unzip = true;
    zathura = true;
    zen-browser = true;
    zoxide = true;
    zsh = true;
  };
}
