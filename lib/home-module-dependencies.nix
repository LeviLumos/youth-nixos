# home-module-dependencies.nix —— Home 模块的“必需依赖表”：键为模块名，
# 值为启用该模块前必须同时启用的其他模块名列表。
# 由 home/default.nix 导入，配合开关板 home/modules-enables.nix 做断言检查：
#   选了模块但缺依赖时，构建报出 “<模块> requires <依赖>” 的明确错误。
# 只放必需依赖；可选的 shell/桌面集成跟随各自模块的开关，不写这里。
# Only essential dependencies belong here. Optional shell and desktop
# integrations follow their owning module switches instead.
{
  fzf = [  # fzf 依赖 fd（模糊查找数据源）与 zsh（按键绑定/补全集成）
    "fd"
    "zsh"
  ];
  tty-login = [  # TTY 登录依赖 niri（登录后启动的图形会话）与 zsh（登录 shell）
    "niri"
    "zsh"
  ];
}
