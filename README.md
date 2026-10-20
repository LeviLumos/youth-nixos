# nixos-config

这是我的个人 **NixOS 配置仓库**。

## 简介

- 系统：NixOS（稳定分支 `nixos-26.05`）
- 用途：日常使用的系统配置
- 状态：持续调整中
- 声明式管理：系统级用 `configuration.nix`，用户级用 `home-manager`
- 桌面环境：Hyprland 与 Niri 双 Wayland 合成器（登录时可选）

## 说明

- 本仓库主要用于个人使用
- 配置会不定期变动
- 仅供参考，使用请自行调整

---

## 目录结构

```
nixos-config/
├── flake.nix                  # 仓库入口：声明所有外部依赖与系统/用户配置装配
├── flake.lock                 # 依赖版本锁定（自动生成，勿手工编辑）
├── configuration.nix          # 系统级主配置：包、用户、引导、网络、音频、显卡
├── hardware-configuration.nix # 硬件描述（由安装器生成，重装时会被覆盖）
│
├── modules/                   # 自定义 NixOS 系统模块
│   ├── default.nix            #   模块聚合入口
│   ├── clash.nix              #   代理客户端与系统代理变量
│   ├── virtualization.nix     #   Docker / libvirt / virt-manager
│   ├── documentation.nix      #   man 手册与文档工具
│   └── systemd.nix            #   把 agenix 解密的密钥注入图形会话
│
├── docs/                      # 使用文档
│   └── KEYBINDS.md            #   快捷键速查表（Hyprland 与 Niri 两套）
│
├── secrets/                   # agenix 加密的敏感信息【当前已停用】
│   ├── secrets.nix            #   声明每个 .age 文件用哪些公钥加密（已注释）
│   └── ai_api_key.age         #   密文（明文勿提交）
│
└── home/youth/                # 用户 youth 的 home-manager 配置
    ├── default.nix            #   用户级入口：XDG 关联、光标、会话变量
    ├── shell/                 #   zsh、starship / powerlevel10k、别名
    ├── terminal/              #   kitty / alacritty
    ├── programs/              #   应用与开发工具
    │   ├── default.nix        #     聚合入口
    │   ├── app.nix            #     图形应用（微信、VLC、Zen Browser、mpv、OBS…）
    │   ├── tool.nix           #     命令行工具（fzf、ripgrep、eza、bat、yazi…）
    │   ├── fastfetch.nix      #     系统信息速览
    │   └── development/       #     开发环境（VS Code、Zed、tmux、工具链…）
    ├── hyprland/              #   Hyprland 桌面环境
    │   ├── default.nix        #     聚合入口
    │   ├── hypr/hyprland.lua  #     主配置（Lua 脚本形式）
    │   ├── scripts/           #     截图 / 录屏 / 壁纸切换脚本
    │   ├── waybar/            #     状态栏（配置 + style.css + 脚本）
    │   ├── wlogout/           #     关机 / 重启 / 注销 / 锁屏菜单
    │   └── hyprlock/          #     锁屏界面
    ├── niri/                  #   Niri 桌面环境（config.kdl + fuzzel）
    ├── noctalia/              #   Noctalia 桌面 Shell（Quickshell）
    ├── fcitx5/                #   中文输入法（Rime 引擎）
    ├── rofi/                  #   rofi 启动器与多套 .rasi 主题
    ├── wallpaper/             #   动态壁纸（awww）与壁纸图片
    └── music/                 #   音乐（mpd + ncmpcpp、go-musicfox）
```

## 快捷键

完整的快捷键速查表见 [docs/KEYBINDS.md](docs/KEYBINDS.md)，
涵盖 Hyprland 与 Niri 两套桌面环境。
Niri 下也可直接按 `Super + Shift + /` 唤出内置速查浮层。

## 常用命令

```bash
# 构建并切换到当前配置（需 root）
sudo nixos-rebuild switch --flake .#levi

# 仅构建不切换，用于验证配置是否能通过
nixos-rebuild build --flake .#levi

# 查看 flake 提供的输出
nix flake show

# 清理旧的 Nix store 代次
sudo nix-collect-garbage -d
```

## 注意事项

- `hardware-configuration.nix` 由安装器生成，重新运行安装流程会被覆盖，
  自定义配置请写到 `configuration.nix` 或 `modules/` 中。
- `secrets/*.age` 依赖本机 `~/.ssh/id_ed25519` 私钥解密，换机时须先迁移私钥。
- 加解密流程（agenix）当前整体停用，相关配置已注释，恢复步骤见
  `flake.nix` 中 agenix input 处的说明（需同时恢复 5 处，缺一会导致构建失败）。
- 含 Nerd Font 图标字符的文件（`hyprland.lua`、`waybar/waybar.nix`、
  `rofi/*.rasi` 等）中的图标在部分编辑器中显示为不可见或方块，
  请勿当作空格删除。
- `home/youth/shell/p10k.zsh` 由 `p10k configure` 自动生成，不手工编辑。
