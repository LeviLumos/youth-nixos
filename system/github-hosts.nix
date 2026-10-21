# github-hosts.nix —— GitHub 加速 hosts 覆写。
# 作用：把 GitHub520 仓库的 hosts 追加进 /etc/hosts，缓解直连 GitHub 的
#   污染/超时。
# 导入：由 system/default.nix 显式导入。
# 机制：networking.extraHosts 直接拼接进生成的 /etc/hosts（静态文件，非服务）。
# 依赖：数据来自 flake input github-hosts（由 flake.lock 锁定版本），
#   手动 nix flake update github-hosts 后重建才更新内容。
# Pinned GitHub host overrides; refresh the github-hosts flake input explicitly.
{ inputs, ... }:
{
  # The GitHub520 repo is a flake input pinned by flake.lock. Refresh it with
  # `nix flake update github-hosts`, then rebuild from the reviewed lock file.
  networking.extraHosts = builtins.readFile "${inputs.github-hosts}/hosts";
}
