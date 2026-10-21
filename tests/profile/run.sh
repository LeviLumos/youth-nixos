#!/usr/bin/env bash
# tests/profile/run.sh —— 测试 profile/ 开发工具包的 Nix profile 集成
# （status/check/build/list/rollback、操作锁、版本元数据、unmanaged profile
# 拒绝、异源同名不收编）。
# 调用方：.github/workflows/check.yml 的 flake-check job。
# 手段：用裁剪的 flake.lock 构建微型真实求值环境。
set -euo pipefail
repository_root=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/koru-profile-tests.XXXXXXXX")
trap 'rm -rf -- "$test_root"' EXIT
mkdir -p "$test_root/repository/profile" "$test_root/state"
export KORU_REPO=$test_root/repository
export XDG_STATE_HOME=$test_root/state
export XDG_RUNTIME_DIR=$test_root/state
export KORU_COLOR_HEADING='#123456'
profile=$test_root/state/nix/profiles/koru-dev
cli=$repository_root/scripts/koru.sh
run() { bash "$cli" profile "$@"; }

# Tiny real derivations exercise Nix manifests and profile publication without
# installing the host's tools or activating any Home Manager/system generation.
# 用 flake.lock 裁剪出微型真实求值环境
jq '{nodes: {root: {inputs: {nixpkgs: "nixpkgs"}}, nixpkgs: .nodes.nixpkgs}, root: "root", version: 7}' \
  "$repository_root/profile/flake.lock" > "$KORU_REPO/profile/flake.lock"
cat > "$KORU_REPO/profile/flake.nix" <<'FLAKE'
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }: let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
    version = builtins.readFile ./version;
    metadata = builtins.toJSON { fixture.tool = version; };
  in {
    packages.x86_64-linux.dev-tools = pkgs.runCommand "profile-fixture-${version}" {} ''
      mkdir -p $out/share/koru-dev
      printf '%s\n' '${metadata}' > $out/share/koru-dev/versions.json
    '';
    packages.x86_64-linux.unmanaged = pkgs.writeText "unmanaged-profile-fixture" "unmanaged";
  };
}
FLAKE
printf 1 > "$KORU_REPO/profile/version"
lock_before=$(sha256sum "$KORU_REPO/profile/flake.lock")
# 未安装→check 不发布→build 后 status 匹配
run status | rg 'Not installed' >/dev/null
run check >/dev/null 2>&1
[[ ! -e $profile && ! -L $profile ]]
run build >/dev/null 2>&1
first=$(readlink "$profile")
first_id=${first#koru-dev-}; first_id=${first_id%-link}
run status | rg 'Matches installed bundle' >/dev/null
run status | rg 'fixture/tool.*1' >/dev/null

# 操作锁下写操作被拒、读可用
# Mutations share Koru's real operation lock; reads remain available.
(
  flock 9
  status=0
  run build >/dev/null 2>&1 || status=$?
  [[ $status == 1 && $(readlink "$profile") == "$first" ]]
  run status | rg 'Matches installed bundle' >/dev/null
) 9> "$XDG_RUNTIME_DIR/koru-operation.lock"

# 版本变化→求值失败不换代→成功换代→回滚
printf 2 > "$KORU_REPO/profile/version"
run status | rg 'Differs from installed bundle' >/dev/null
cp "$KORU_REPO/profile/flake.nix" "$test_root/working-flake.nix"
sed -i 's/version = builtins.readFile/version = assert false; builtins.readFile/' "$KORU_REPO/profile/flake.nix"
status=0
run build >/dev/null 2>&1 || status=$?
[[ $status != 0 && $(readlink "$profile") == "$first" ]]
cp "$test_root/working-flake.nix" "$KORU_REPO/profile/flake.nix"
run build >/dev/null 2>&1
second=$(readlink "$profile")
[[ $first != "$second" ]]
run list | rg '2 \*' >/dev/null
run status | rg 'fixture/tool.*2' >/dev/null
run rollback --generation "$first_id" >/dev/null 2>&1
[[ $(readlink "$profile") == "$first" ]]
run status | rg 'Differs from installed bundle' >/dev/null

# 非法代拒绝、unmanaged 条目拒绝、flake.lock 不被改动
status=0
run rollback --generation 999999 >/dev/null 2>&1 || status=$?
[[ $status == 1 && $(readlink "$profile") == "$first" ]]
nix profile install --profile "$profile" --no-update-lock-file \
  "path:$KORU_REPO/profile#unmanaged" >/dev/null 2>&1
unmanaged=$(readlink "$profile")
unmanaged_id=${unmanaged#koru-dev-}; unmanaged_id=${unmanaged_id%-link}
status=0
run build > "$test_root/rejected.log" 2>&1 || status=$?
[[ $status == 1 && $(readlink "$profile") == "$unmanaged" ]]
rg 'Unmanaged profile entries' "$test_root/rejected.log" >/dev/null
run rollback --generation "$first_id" >/dev/null 2>&1
status=0
run rollback --generation "$unmanaged_id" >/dev/null 2>&1 || status=$?
[[ $status == 1 && $(readlink "$profile") == "$first" ]]
[[ $(sha256sum "$KORU_REPO/profile/flake.lock") == "$lock_before" ]]

# 异源同名包不被隐式收编
# A same-named bundle from a different source is not adopted implicitly.
rm "$profile"
mkdir -p "$test_root/other-source"
cp -a "$KORU_REPO/profile/." "$test_root/other-source/"
nix profile install --profile "$profile" --no-update-lock-file \
  "path:$test_root/other-source#dev-tools" >/dev/null 2>&1
foreign=$(readlink "$profile")
status=0
run build >/dev/null 2>&1 || status=$?
[[ $status == 1 && $(readlink "$profile") == "$foreign" ]]
printf '%s\n' 'Development profile integration tests passed.'
