#!/usr/bin/env bash
# tests/home-modules/run.sh —— 测试 scripts/home-modules.sh（home 模块
# enable/disable 的 CLI 契约）。
# 调用方：.github/workflows/check.yml 的 flake-check job。
# 覆盖：幂等、未知模块报错、依赖缺失拒绝、批量事务失败不改文件、
#   nix eval 断言集成配置消失、flock 防并发（退出码 124）。
set -euo pipefail

repository_root=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/home-modules-tests.XXXXXXXX")
trap 'rm -rf -- "$test_root"' EXIT

# 每个场景复制独立仓库副本，互不干扰
copy_repository() {
  local name=$1
  mkdir -p "$test_root/$name"
  cp -a -- "$repository_root/." "$test_root/$name/repository"
  printf '%s\n' "$test_root/$name/repository"
}

# 重复执行同一开关：应幂等，文件内容不变
idempotent_root=$(copy_repository idempotent)
idempotent_output=$("$idempotent_root/scripts/home-modules.sh" enable kitty)
grep -F 'Already enabled: kitty' <<< "$idempotent_output" >/dev/null

set +e
unknown_output=$("$idempotent_root/scripts/home-modules.sh" enable unknown-module 2>&1)
unknown_status=$?
set -e
[[ $unknown_status == 2 ]]
grep -F "unknown Home Manager module 'unknown-module'" <<< "$unknown_output" >/dev/null

# 未知模块名：报错且退出码 2
malformed_root=$(copy_repository malformed)
sed -i 's/    gh = true;/    gh = maybe;/' "$malformed_root/home/modules-enables.nix"
set +e
malformed_output=$("$malformed_root/scripts/home-modules.sh" list 2>&1)
malformed_status=$?
set -e
[[ $malformed_status != 0 ]]
grep -F 'unsupported or ambiguous switchboard syntax' <<< "$malformed_output" >/dev/null

# 畸形开关板：解析必须失败而不是静默误读
dependency_root=$(copy_repository dependency)
before=$(sha256sum "$dependency_root/home/modules-enables.nix" | cut -d ' ' -f1)
set +e
dependency_output=$("$dependency_root/scripts/home-modules.sh" disable fd 2>&1)
dependency_status=$?
set -e
after=$(sha256sum "$dependency_root/home/modules-enables.nix" | cut -d ' ' -f1)
[[ $dependency_status != 0 && $before == "$after" ]]
grep -F 'fzf requires fd' <<< "$dependency_output" >/dev/null

# 依赖缺失：拒绝 enable 且文件保持不变
success_root=$(copy_repository success)
"$success_root/scripts/home-modules.sh" disable gh libreoffice zen-browser fastfetch btop bat eza imv satty clipboard-history fcitx5 >/dev/null
grep -F 'gh = false;' "$success_root/home/modules-enables.nix" >/dev/null
grep -F 'libreoffice = false;' "$success_root/home/modules-enables.nix" >/dev/null
grep -F 'zen-browser = false;' "$success_root/home/modules-enables.nix" >/dev/null
# Assert that integrations and direct installations disappear together.
nix eval --no-update-lock-file --json \
  "path:$success_root#homeConfigurations.koru.config" --apply 'c: {
    aliases = c.programs.zsh.shellAliases;
    shell = c.programs.zsh.initContent;
    binds = builtins.attrNames c.wayland.windowManager.niri.settings.binds;
    startup = c.wayland.windowManager.niri.settings._children;
    packages = map (p: p.pname or p.name) c.home.packages;
  }' > "$test_root/disabled.json"
jq -e '
  (.aliases | has("cat") or has("ls") or has("fetch") | not) and
  (.shell | test("(?m)^\\s*(topdf|f|ll)\\(\\)") or contains("MANPAGER=") | not) and
  (.binds | index("Alt+l") == null and index("Alt+i") == null and index("Alt+v") == null and index("Alt+s") == null) and
  (.startup | tostring | contains("fastfetch") or contains("btop") or contains("fcitx5") | not) and
  (.packages | index("libreoffice") == null and index("eza") == null and index("imv") == null and index("satty") == null)
' "$test_root/disabled.json" >/dev/null

# 批量 disable 后用 nix eval 断言集成配置确实消失
batch_before=$(sha256sum "$success_root/home/modules-enables.nix" | cut -d ' ' -f1)
batch_status=0
"$success_root/scripts/home-modules.sh" enable gh unknown-module >/dev/null 2>&1 || batch_status=$?
[[ $batch_status == 2 ]]
[[ $batch_before == "$(sha256sum "$success_root/home/modules-enables.nix" | cut -d ' ' -f1)" ]]

# 批量事务中途失败：文件不得被部分修改
failed_batch_before=$batch_before
failed_batch_status=0
"$success_root/scripts/home-modules.sh" disable fzf zsh >/dev/null 2>&1 || failed_batch_status=$?
[[ $failed_batch_status != 0 ]]
[[ $failed_batch_before == "$(sha256sum "$success_root/home/modules-enables.nix" | cut -d ' ' -f1)" ]]

# flock 防并发：第二个进程应超时退出（124）
# Complementary batch edits are evaluated as one transaction.
"$success_root/scripts/home-modules.sh" disable fzf fd >/dev/null
grep -F 'fzf = false;' "$success_root/home/modules-enables.nix" >/dev/null
grep -F 'fd = false;' "$success_root/home/modules-enables.nix" >/dev/null
nix eval --no-update-lock-file --json \
  "path:$success_root#homeConfigurations.koru.config.programs.zsh.initContent" |
  jq -e 'contains("fzf-history-widget") | not' >/dev/null
nix eval --no-update-lock-file --json \
  "path:$success_root#homeConfigurations.koru.config.programs.kitty.keybindings" |
  jq -e 'has("super+j") or has("super+k") or has("super+l") | not' >/dev/null
repeat_output=$("$success_root/scripts/home-modules.sh" disable gh)
grep -F 'Already disabled: gh' <<< "$repeat_output" >/dev/null

# validate 子命令：通过/失败两种路径
lock_root=$(copy_repository lock)
lock_file=$lock_root/.git/home-modules.lock
set +e
(
  flock 9
  timeout 0.2 "$lock_root/scripts/home-modules.sh" disable gh >/dev/null 2>&1
) 9> "$lock_file"
lock_status=$?
set -e
[[ $lock_status == 124 ]]
grep -F 'gh = true;' "$lock_root/home/modules-enables.nix" >/dev/null

printf '%s\n' 'home-modules tests passed'
