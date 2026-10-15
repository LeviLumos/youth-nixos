# NixOS Flake 配置

基于 **Nix Flakes** 的 NixOS 系统配置，使用 niri（Wayland 合成器）作为桌面环境，通过 home-manager 管理用户级配置。

- **主机名**：`nixos`
- **用户名**：`youth`
- **系统架构**：`x86_64-linux`
- **NixOS 版本**：`26.05`

---

## 目录结构

```
/etc/nixos
├── flake.nix                    # Flake 入口：声明输入，导入各模块
├── flake.lock                   # 锁定各输入的确切版本（自动生成，勿手改）
├── hardware-configuration.nix   # 硬件配置（由 nixos-generate-config 生成，勿手改）
├── home.nix                     # 用户级配置（home-manager，管理 youth 用户）
├── modules/                     # 系统级配置，按主题拆分
│   ├── core.nix                 # 引导、网络、时区、Nix 缓存、nix-ld
│   ├── desktop.nix              # niri（Wayland 合成器）+ greetd
│   ├── proxy.nix                # clash-verge + TUN 防火墙调整
│   ├── users.nix                # 用户与 shell
│   ├── packages.nix             # 系统软件包
│   └── fonts.nix                # 字体
└── README.md                    # 本文件
```

各文件职责：

| 文件 | 层级 | 说明 |
| --- | --- | --- |
| `flake.nix` | 入口 | 声明 `nixpkgs` 与 `home-manager` 输入，导入各模块并组装 `nixosConfigurations.nixos` |
| `modules/core.nix` | 系统 | 引导、网络、防火墙基础、时区、Nix 设置、nix-ld、`stateVersion` |
| `modules/desktop.nix` | 系统 | niri 合成器与 greetd 登录管理器 |
| `modules/proxy.nix` | 系统 | Clash Verge 及 TUN 模式防火墙规则 |
| `modules/users.nix` | 系统 | 用户 `youth` 与 zsh |
| `modules/packages.nix` | 系统 | 系统级软件包 |
| `modules/fonts.nix` | 系统 | 系统字体 |
| `hardware-configuration.nix` | 硬件 | 文件系统挂载、内核模块、CPU 微码等，由硬件探测生成 |
| `home.nix` | 用户 | 用户 `youth` 的家目录配置、dotfiles、用户级软件包 |
| `flake.lock` | 依赖 | 锁定 flake 输入的提交哈希，保证可复现 |

---

## 硬件与文件系统

来自 `hardware-configuration.nix`：

- **CPU**：AMD（启用 `kvm-amd` 模块与 AMD 微码更新）
- **磁盘**：单块 NVMe，使用 **Btrfs**，按子卷划分并启用 `compress=zstd` 压缩：

  | 挂载点 | 子卷 | 说明 |
  | --- | --- | --- |
  | `/` | `subvol=root` | 系统根目录 |
  | `/home` | `subvol=home` | 用户数据，独立子卷便于快照/回滚 |
  | `/nix` | `subvol=nix` | Nix store，额外启用 `noatime` 减少写入 |
  | `/boot` | — | EFI 分区（`vfat`），独立磁盘 UUID |

- **交换分区**：未配置（`swapDevices = []`）

> ⚠️ `hardware-configuration.nix` 由 `nixos-generate-config` 自动生成，重新生成时会被覆盖。所有自定义改动应写入 `modules/` 下的对应模块。

---

## 系统组件

### 引导

```nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
```

使用 **systemd-boot**（UEFI 引导）。

### 网络

- `NetworkManager` 管理网络连接。
- 开启 **OpenSSH** 服务并放行防火墙端口。

### 桌面环境：niri + greetd

```nix
programs.niri.enable = true;
services.greetd = {
  enable = true;
  useTextGreeter = true;
  settings.default_session.command =
    "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --sessions ...";
};
```

- **niri**：一款可滚动平铺（scrollable-tiling）的 Wayland 合成器。
- **greetd + tuigreet**：文本界面登录管理器，支持会话选择与「记住上次会话」。

### nix-ld（运行非 Nix 二进制）

```nix
programs.nix-ld.enable = true;
```

提供常见动态库（zlib、openssl、curl、libxml2 等），使预编译的第三方二进制（如 VS Code Server、部分 npm 原生模块）无需打补丁即可运行。

### Clash Verge（网络代理）

```nix
programs.clash-verge = {
  enable = true;
  package = pkgs.clash-verge-rev;   # 更活跃维护的社区版
  serviceMode = true;               # TUN 模式必需
  tunMode = true;                   # 虚拟网卡全局代理
  autoStart = true;                 # 开机自启
};
```

**TUN 模式防火墙调整**（关键）：

```nix
networking.firewall = {
  enable = true;
  trustedInterfaces = [ "Mihomo" "Meta" ];
  extraReversePathFilterRules = ''
    iifname { "Mihomo", "Meta" } accept comment "clash-verge tun"
  '';
};
```

> ⚠️ 在 nftables 下，Clash 的 TUN 虚拟网卡流量会被反向路径过滤（rpfilter）与输入过滤规则丢弃。因此必须：
> 1. 将虚拟网卡加入 `trustedInterfaces`；
> 2. 放行 rpfilter。
>
> 网卡名可能是 `Mihomo` 或 `Meta`，取决于内核与 Clash 配置，两个名字都已加入白名单。

### 字体

```nix
fonts.packages = with pkgs; [
  maple-mono.NF-CN
];
```

- **Maple Mono CN（NF 变体）**：来自 `pkgs.maple-mono` 包集（v7.9），是一款带圆角与编程连字（ligatures）的等宽字体，NF 变体额外包含 Nerd Font 图标，适合终端与状态栏。
- 其他可选变体：`maple-mono.CN`（标准）、`maple-mono.NL-CN`（无连字）、`maple-mono.Normal-CN`。
- 验证：`fc-list | grep -i maple`

### 用户与 Shell

- 用户 `youth` 为普通用户，默认 shell 为 **zsh**。
- 附加用户组：`networkmanager`、`wheel`（sudo）、`root`、`users`。

---

## home-manager（用户级配置）

`home.nix` 通过 home-manager 管理 `youth` 的家目录：

| 项目 | 说明 |
| --- | --- |
| `home.packages` | 用户级包：`mise`（运行时版本管理器）、`vim` |
| `programs.zsh` | 启用 zsh |
| `programs.git` | 用户名 `levilumos` / 邮箱 `v227to.me@gmail.com` |
| `programs.firefox` | Firefox 浏览器 |
| `programs.alacritty` | Alacritty 终端 |
| `programs.home-manager` | 启用 home-manager 本体 |

在 `flake.nix` 中启用方式：

```nix
home-manager.useGlobalPkgs = true;      # 复用系统 nixpkgs，避免重复下载
home-manager.useUserPackages = true;    # 将用户包安装到 /etc/profiles
home-manager.users.youth = import ./home.nix;
```

---

## Nix 配置（国内镜像加速）

```nix
nix.settings = {
  experimental-features = [ "nix-command" "flakes" ];
  substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.sjtu.edu.cn/nix-channels/store"
  ];
  trusted-substituters = [ ... ];
};
```

使用**清华**与**上交**镜像作为二进制缓存源，加速国内下载。官方源 `cache.nixos.org` 已注释保留，可作备用（镜像缺失个别包时启用）。

---

## 常用命令

> 需要 root 权限（`sudo`）。若使用 flake，需在命令中带上配置路径 `.#nixos`（或依赖当前目录）。

### 应用配置

```bash
# 构建并切换到新配置（推荐，可回滚）
sudo nixos-rebuild switch --flake /etc/nixos#nixos

# 仅构建，不切换（检查是否可编译）
sudo nixos-rebuild build --flake /etc/nixos#nixos

# 应用配置但不更新引导项（临时测试）
sudo nixos-rebuild test --flake /etc/nixos#nixos

# 应用并设为下次启动默认
sudo nixos-rebuild boot --flake /etc/nixos#nixos
```

### 更新依赖

```bash
# 更新 flake.lock 中锁定的所有输入到最新
sudo nix flake update --flake /etc/nixos

# 只更新单个输入
sudo nix flake update nixpkgs --flake /etc/nixos
```

更新后需再次执行 `nixos-rebuild switch` 才会生效。

### 检查与格式化

```bash
# 检查 flake 输出是否正常
nix flake check /etc/nixos

# 格式化所有 nix 文件（需安装 nixpkgs-fmt 或 alejandra）
nixfmt /etc/nixos/*.nix
```

### 回滚

```bash
# 列出历史配置（可启动的系统）
sudo nixos-rebuild list-generations

# 回滚到上一代
sudo nixos-rebuild switch --rollback

# 切换到指定代
sudo nixos-rebuild switch --flake /etc/nixos#nixos   # 换到某代需用系统菜单或指定
```

> 开机时在 systemd-boot 菜单中也可选择历史系统代（generations）启动，这是 NixOS 的核心安全网。

---

## 版本说明

- `system.stateVersion = "26.05"`（见 `modules/core.nix`）
- `home.stateVersion = "26.05"`（见 `home.nix`）

**不要**随意修改 `stateVersion`：它用于标记首次安装的版本，控制数据迁移行为。跨大版本升级时按发行说明调整，通常保持安装时的值不变。

---

## 注意事项

1. **不要手改 `hardware-configuration.nix`**，自定义内容写入 `modules/` 下的对应模块。
2. **不要手改 `flake.lock`**，使用 `nix flake update` 更新。
3. 修改配置后，务必先 `build` 或 `test` 验证，再 `switch`，避免系统进入不可用状态。
4. Clash Verge 若 TUN 模式不通，优先检查虚拟网卡名是否与防火墙白名单（`Mihomo` / `Meta`）一致。
5. 变更涉及密钥、密码或个人隐私的内容前，注意本仓库可能被推送到远程（当前用户为 `levilumos`，邮箱 `v227to.me@gmail.com`）。
