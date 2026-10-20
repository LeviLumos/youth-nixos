# ============================================================================
# modules/systemd.nix —— 密钥注入图形会话的 systemd 用户服务【已禁用】
# ----------------------------------------------------------------------------
# 背景问题（停用前的设计）：
#   configuration.nix 中通过 agenix 解密出的密钥以「文件」形式落在 /run 下，
#   仅作为该服务的环境变量存在。图形程序（由 systemd --user 拉起）无法
#   读取到该变量，导致 rofi / 各类 GUI 启动器里拿不到 AI API Key。
#
# 解决方案（停用前的设计）：
#   定义一个一次性（oneshot）用户服务，在 graphical-session.target 之前运行：
#     1. source 解密后的密钥文件，并自动导出其中所有变量；
#     2. 解析出文件中的变量名列表；
#     3. 通过 D-Bus 更新 activation environment，让 GUI 程序感知；
#     4. 同步写入 systemd 用户环境管理器，供后续进程继承。
#
# 为什么当前被注释：
#   本服务依赖 config.age.secrets.ai_api_key.path，而加解密流程
#   （agenix）已整体停用，age.* 选项不再存在，导入本模块会构建失败。
#   因此整段配置被注释，且 modules/default.nix 中也已注释对本文件的导入。
#
# 恢复步骤：
#   1. flake.nix：取消 agenix input、agenix.nixosModules.default、
#      agenix CLI 安装的注释；
#   2. configuration.nix：取消 age.identityPaths 与 age.secrets 的注释；
#   3. modules/default.nix：取消 ./systemd.nix 的导入注释；
#   4. 取消下方整段配置的注释；
#   5. hyprland.lua：取消 `systemctl --user start env-loader.service` 的注释。
#
# 验证方式（恢复后）：
#   systemctl --user status env-loader
#   systemctl --user show-environment | grep ai_api_key
# ============================================================================

# 模块内容整体停用，保留空属性集以保证文件仍是合法的 NixOS 模块。
{
}

# ---- 以下为停用前的完整配置，恢复时整段取消注释即可 ----
#
# {
#   # config 用于引用 configuration.nix 中声明的 age.secrets.ai_api_key.path
#   config,
#   # pkgs 用于在生成的脚本里引用 dbus / systemd 命令的绝对路径
#   pkgs,
#   # ... 表示接受其它未声明的模块参数
#   ...
# }: {
#   # --------------------------------------------------------------------------
#   # systemd --user 服务：env-loader
#   # --------------------------------------------------------------------------
#   systemd.user.services.env-loader = {
#     description = "Load API keys from agenix into graphical session";
#
#     # 在图形会话准备阶段被拉起（早于桌面 UI 完全启动）
#     wantedBy = ["graphical-session-pre.target"];
#     # 并确保本服务先于 graphical-session.target 完成
#     before = ["graphical-session.target"];
#
#     serviceConfig = {
#       Type = "oneshot"; # 执行一次即退出
#       RemainAfterExit = true; # 执行成功后保持「active (exited)」状态，便于 status 查看
#
#       ExecStart = pkgs.writeShellScript "env-loader" ''
#         # 密钥解密后的实际路径（形如 /run/agenix/ai_api_key），由 Nix 注入
#         SECRET_FILE="${config.age.secrets.ai_api_key.path}"
#
#         # 若解密文件不存在（例如首次启动前未重建系统），静默跳过，避免服务失败
#         if [ -f "$SECRET_FILE" ]; then
#           # 1. set -a 使后续 source 的赋值自动 export，随后 set +a 恢复默认
#           set -a
#           . "$SECRET_FILE"
#           set +a
#
#           # 2. 用 grep 提取所有合法的 shell 变量名（等号左侧的标识符）
#           VARS=$(grep -oP '^[a-zA-Z_][a-zA-Z0-9_]*(?==)' "$SECRET_FILE")
#
#           # 3. 更新 D-Bus 激活环境：解决 rofi / GUI 应用无法识别变量的问题
#           ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd $VARS
#
#           # 4. 同步到 systemd 用户环境管理器，供之后启动的进程继承
#           for var in $VARS; do
#             val=$(eval echo \$$var) # 取出变量当前值
#             ${pkgs.systemd}/bin/systemctl --user set-environment "$var"="$val"
#           done
#         fi
#       '';
#     };
#   };
# }
