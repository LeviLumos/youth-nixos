# ============================================================================
# secrets/secrets.nix —— agenix 加密目标描述【已禁用】
# ----------------------------------------------------------------------------
# 作用：
#   本文件用「公钥」声明本目录中每个 .age 密文文件是加密给谁的。
#   它不含任何明文密钥，因此可以安全地提交到 Git 仓库。
#
# 注意：本文件不参与 NixOS 构建，只在使用 agenix 命令行手动加解密时被读取。
#       加解密流程当前已整体停用（flake.nix / configuration.nix /
#       modules/systemd.nix 中的相关配置均已注释），因此下方内容一并注释。
#
# 恢复步骤：见 flake.nix 中 agenix input 处的说明；随后取消下方整段注释，
#       并把 .age 文件交给 agenix 管理即可。
#
# 使用流程（恢复后的加密操作）：
#   1. 文件内容形如一行或多行 shell 赋值语句，变量名即最终的环境变量名：
#        ai_api_key=sk-xxxxxxxxxxxxxxxx
#   2. 在仓库根目录执行（agenix 会自动读取本文件确定用哪些公钥加密）：
#        cd ~/nixos-config
#        agenix -e secrets/ai_api_key.age  # 编辑：解密到临时文件 → 打开 $EDITOR
#                                          #       → 保存后用本文件的公钥重新加密
#        agenix -d secrets/ai_api_key.age  # 查看：解密并输出到 stdout（不落盘）
#        agenix -r                         # 重加密：按本文件公钥重新加密所有 .age
#   3. 把 .age 提交到仓库即可。agenix 全程使用临时文件，明文不会残留在仓库中。
#
# ⚠ 安全提示：
#   - 下方公钥可公开；若私钥泄露，请立即用 ssh-keygen 生成新密钥并重新加密；
#   - 新增机器时把新公钥追加到对应文件的 publicKeys 列表中即可。
# ============================================================================

# 内容整体停用，保留空属性集以保证文件仍是合法的 Nix 表达式。
{}

# ---- 以下为停用前的完整配置，恢复时整段取消注释即可 ----
#
# let
#   # 本机解密私钥对应的公钥（对应 ~/.ssh/id_ed25519 派生的 age 身份）
#   youth = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM5SG/6FWHxFnQSRFXfXKgg2kmhLrRJeuw7yCcAZxCgH agenix key";
# in {
#   # 文件名 -> 可解密该文件的公钥列表（可配置多把公钥，便于多机共用仓库）
#   "ai_api_key.age".publicKeys = [youth];
# }
