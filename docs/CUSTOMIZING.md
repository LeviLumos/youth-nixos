# 自定义指南（Customizing）

本仓库是一份**个人单机配置**（主机 `koru`，用户 `koru`）。这篇文档讲两件事：
如何把它改造成你自己的配置，以及日常最常见的一些定制怎么做。

> :red_circle: **不要直接在任何机器上部署这个 flake。** 它带有这台笔记本的硬件
> 配置（UUID、磁盘布局、驱动黑名单），并且从本地 `hosts/koru/password` 文件读取
> 密码。正确用法是：按下面第一节搭出自己的骨架，再把感兴趣的模块抄过去。

所有命令都在仓库根目录执行。日常维护统一走 `koru` CLI（先 `check` 确认能构建，
再 `build` 应用；出问题用 `rollback` 回退）：

```sh
koru system check          # 只构建不切换（系统 + 内嵌用户层）
koru system build          # 构建并切换
koru home check / build    # 只构建/切换用户层
koru profile check / build # 开发工具链（独立 profile）
koru system list           # 列出保留的系统代
koru system rollback --generation <ID>
```

---

## 一、迁移到你自己的机器（一次性骨架搭建）

按顺序检查/修改以下入口，全部通过 `nixos-rebuild` 或 `koru system build`
求值报错来逐步排错：

| 步骤 | 要改什么 | 位置 |
| --- | --- | --- |
| 1. 用户名 | `username = "koru"` | `flake.nix` |
| 2. 主机名与架构 | 加一条 `你的主机名 = { system = "x86_64-linux"; }` | `hosts/inventory.nix` |
| 3. 主机目录 | 复制 `hosts/koru/` 为 `hosts/<你的主机名>/`，`default.nix` 里按需删减子模块 | `hosts/<你的主机名>/` |
| 4. 硬件配置 | 在目标机上用 `nixos-generate-config` 生成全新的 `hardware-configuration.nix`，**替换**掉抄来的那份（UUID/文件系统必须是你自己的） | `hosts/<你的主机名>/hardware-configuration.nix` |
| 5. 引导/显卡/文件系统 | 只保留适用的：Intel 核显模块对 AMD/NVIDIA 机器不适用；Btrfs 参数只在你同样用 Btrfs 时保留；`boot.nix` 的驱动黑名单是这台机器的实测结论，不要照抄 | `hosts/<你的主机名>/` 下对应文件 |
| 6. 账号与密码 | `user-account.nix` 从本地 `password` 文件读明文密码（单机个人的偷懒做法）。建议换成你自己可靠的方式（如 `users.users.<name>.hashedPassword` 或 secrets 管理），并把仓库里的 `password` 文件删掉 | `hosts/<你的主机名>/user-account.nix` |
| 7. 仓库路径 | `koru` CLI 默认在 `~/.config/nixos` 找仓库；放在别处就改 `repositoryRoot` | `lib/koru-package.nix` |
| 8. 电源策略 | 电池/刷新率/频率钳制全部针对 i7-13650HX + 1080p 144Hz 屏，换机器请按你的硬件重新验证 | `hosts/<你的主机名>/power-management.nix`、`display-power.nix` |

改完先求值验证（不构建也能查大部分错误）：

```sh
nix eval .#nixosConfigurations.<你的主机名>.config.system.build.toplevel.drvPath
```

---

## 二、改主机名 / 用户名

**主机名**由 `hosts/inventory.nix` 的键名决定（`flake.nix` 会把它作为
`hostname` 注入主机层），不需要去别处搜索替换：

```nix
# hosts/inventory.nix
{
  koru = { system = "x86_64-linux"; };
  # 改名：把键换成新名字，并把 hosts/koru/ 目录重命名为同名目录
}
```

**用户名**只有一处定义：`flake.nix` 顶部的 `username`。主机层账号
（`hosts/*/user-account.nix`）和用户层（home-manager）都从它取值。
注意同步修改：

- `hosts/<你的主机名>/user-account.nix` 中引用的密码/自动登录配置；
- `lib/koru-package.nix` 里 `repositoryRoot`（如 `~/.config/nixos`）等含用户名的路径。

---

## 三、安装 / 停用软件（用户层开关板）

用户层软件由**唯一开关板** `home/modules-enables.nix` 控制，一个布尔对应
`home/` 下的一个同名模块文件：

```nix
{
  enable = {
    kitty = true;       # 安装并生效
    alacritty = false;  # 模块文件保留，但不加载
    # ...
  };
}
```

**停用某个软件**：把对应布尔改成 `false`，然后 `koru home build`（或
`koru system build`）。

**启用/停用也可以不改文件**，用 CLI（它会原子改写开关板并先求值验证）：

```sh
koru home modules            # 列出全部开关
koru home disable alacritty
koru home enable alacritty
koru home validate
```

注意两点：

1. 开关板与 `home/` 目录**强制双向一致**：目录里有模块而开关板没列（或反之）
   会直接求值失败——这是刻意设计，防止模块被遗忘。
2. 有的模块有硬依赖（登记在 `lib/home-module-dependencies.nix`，目前
   `fzf → [fd, zsh]`、`tty-login → [niri, zsh]`）。缺依赖时求值会报
   `<模块> requires <依赖>`，把依赖一起打开即可。

### 添加一个全新模块

1. 新建 `home/<软件名>.nix`，最简骨架（以纯安装为例）：

   ```nix
   { pkgs, ... }:
   {
     home.packages = [ pkgs.<软件名> ];
   }
   ```

   需要主题色/字体时，从参数里取 `theme`（模块自动发现机制会把
   `theme`/`username`/`enabled` 传进来），参考 `home/kitty.nix` 的写法。

2. 在 `home/modules-enables.nix` 的 `enable` 下加同名布尔。

3. 若它依赖其他模块，在 `lib/home-module-dependencies.nix` 登记一条。

4. `koru home check && koru home build`。

### 软件装在哪一层？

| 需求 | 放哪层 | 入口 |
| --- | --- | --- |
| 终端工具、桌面应用、用户配置 | 用户层 | `home/modules-enables.nix` |
| 系统服务、驱动、内核参数、防火墙 | 系统层 | `system/default.nix`（显式 imports） |
| 编译器/运行时等开发工具 | 工具链层 | `profile/packages/`（见下文第五节） |

判断标准：看它需要 `systemd` 服务/内核/全局用户，还是只是"我这个用户要用"。
禁用用户层开关**不会卸载**其他层或别的模块依赖带入的包。

---

## 四、主题、字体、键位

- **配色/字体/字号/光标**：全部来自 `system/theme.nix` 这一个纯数据文件
  （Koru Fern 调色板 + Maple Mono NF CN）。kitty、GTK、btop、fastfetch、
  fcitx5、TTY、Neovim、鼠标指针等全部引用它，改一处全局换肤，无需逐个改。
- **键位**：`home/niri/keybindings.nix`（纯数据表，每条键位都有中文注释）。
  依赖可选模块的键位会随开关自动出现/消失。
- **Niri 布局/启动项**：`home/niri.nix`。

---

## 五、开发工具链（`profile/`）

编译器与运行时在独立锁定的 flake 里，升级**不会**触发系统重建：

```sh
koru profile status   # 对比已安装版本与当前源
koru profile build    # 安装/升级 dev-tools
koru profile list     # 保留代
```

- 增删工具：改 `profile/packages/` 下对应模块，或新建一个模块并在
  `profile/default.nix` 登记；`profile/toolchain-checks.nix` 里的冒烟检查
  保证"装出来的东西真的能编译运行"。
- Rust 版本钉在 `profile/packages/rust.nix`（精确版本），升级 = 改这一处 +
  `koru profile build`。
- 锁文件升级：`cd profile && nix flake update`（注意与根 `flake.lock` 相互独立）。

---

## 六、系统服务的增删

系统层模块在 `system/default.nix` 中**显式** import（按字母序），加一个系统
能力 = 新建 `system/<名字>.nix` + 在 `default.nix` 加一行 import。删掉 import
行即停用。常用的现成开关：

| 想改什么 | 文件 |
| --- | --- |
| SSH（端口/密码登录） | `system/openssh-server.nix` |
| 防火墙放行端口 | `system/firewall.nix` |
| 代理（mihomo） | `system/mihomo.nix` + `koru proxy ...` |
| Nix 镜像源/并行度/GC | `system/nix-daemon.nix`、`nix-garbage-collection.nix` |
| DNS / Wi-Fi 省电 | `system/network-manager.nix` |
| zram / 内核回收参数 | `system/memory-zram.nix` |

---

## 七、改完之后：检查与回退

```sh
koru system check        # 真实构建，但不切换（比 nix flake check 轻）
koru system build        # 应用；出问题可立即回退
koru system rollback --generation <ID>
```

提交前建议本地跑一遍 CI 同款静态检查（CI 在 `.github/workflows/check.yml`）：

```sh
nix flake check          # 格式(nixfmt)/lint(statix)/死代码(deadnix)/代理VM测试
```

> 顺手约定：本仓库的 Nix 代码用 `nix fmt` 格式化，shell 用 ShellCheck 把关，
> 新增注释请与现有风格一致（英文既有注释保留，新增可为中文）。

回退语义提醒：rollback 恢复的是**该层 profile 的构建产物与被管理配置**，
不回滚 Git 工作区、npm 安装的软件（如 Codex CLI）和你自己的运行时数据。
