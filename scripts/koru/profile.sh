#!/usr/bin/env bash
# koru/profile.sh —— 开发工具链 profile 子命令组：管理独立的 nix profile
# （koru-dev），安装本仓库 profile/flake.nix 的 dev-tools 包，
# 并提供 status 校验安装来源一致性。
# 全局变量（profile_flake、profile_name 等）由 common.sh 初始化。
# 安全设计：严格校验 profile 只含本仓库这一个 dev-tools 条目，
#   混入手动安装项或其他来源同名包时拒绝操作，防止误升级/覆盖。
# Globals are initialized by common.sh.
# shellcheck disable=SC2154

# 校验 profile 源与 lock 文件存在，并确定求值 URL 与 attribute
koru_profile_source() {
  [[ -f $repository_root/profile/flake.nix && -f $repository_root/profile/flake.lock ]] ||
    koru_error 'Development profile source or lock file is missing.'
  profile_url=path:$repository_root/profile
  profile_attribute=packages.x86_64-linux.dev-tools
  profile_installable=$profile_url#dev-tools
}

# 读取 profile 清单 JSON；profile 尚不存在时返回空清单
koru_profile_manifest() {
  if [[ -e $dev_profile || -L $dev_profile ]]; then
    nix profile list --profile "$dev_profile" --json
  else
    printf '%s\n' '{"elements":{}}'
  fi
}

# 严格校验：该 profile 必须只含本仓库这一个 dev-tools 条目；
# 若混入手动安装项或其他来源同名包，拒绝操作，防止误升级/覆盖
koru_profile_validate() {
  local manifest=$1
  # This profile belongs to one bundle from this repository. Do not overwrite
  # hand-installed entries or a same-named bundle from a different source.
  jq -e --arg url "$profile_url" --arg attribute "$profile_attribute" '
    (.elements | type == "object") and
    ((.elements | length) == 0 or
      ((.elements | keys) == ["dev-tools"] and
       .elements["dev-tools"].originalUrl == $url and
       .elements["dev-tools"].attrPath == $attribute and
       .elements["dev-tools"].active == true and
       (.elements["dev-tools"].storePaths | length) == 1))
  ' <<< "$manifest" >/dev/null ||
    koru_error 'Unmanaged profile entries found. Inspect with nix profile list --profile PATH; original profile preserved.'
}

koru_profile() {
  local action=$1 manifest installed expected target
  case $action in
    list) koru_generations "$dev_profile" 'Development profile' ;;
    check)
      koru_profile_source; koru_lock
      koru_line heading 'Development profile build check'
      koru_run nix build --no-link --no-update-lock-file "$profile_installable"
      ;;
    # 空清单走 install，否则 upgrade dev-tools；nix add/upgrade 先构建成功才发布新代，
    # 失败时代保持不变，不会出现“先卸载后安装”的空窗
    build)
      koru_profile_source; koru_lock
      manifest=$(koru_profile_manifest) || koru_error 'Cannot read development profile.'
      koru_profile_validate "$manifest"
      koru_line heading 'Development profile build and install'
      mkdir -p -- "$(dirname -- "$dev_profile")"
      # add/upgrade builds before publishing a new profile generation. Failed
      # builds leave the installed generation intact; no remove/add gap.
      if jq -e '.elements | length == 0' <<< "$manifest" >/dev/null; then
        koru_run nix profile install --profile "$dev_profile" --no-update-lock-file "$profile_installable"
      else
        koru_run nix profile upgrade --profile "$dev_profile" --no-update-lock-file dev-tools
      fi
      ;;
    # 对比已安装 store path 与当前源求值的 outPath，提示是否需要 build；
    # 再读取包内置 versions.json 展示各工具版本
    status)
      koru_profile_source
      manifest=$(koru_profile_manifest) || koru_error 'Cannot read development profile.'
      koru_profile_validate "$manifest"
      koru_line heading 'Development profile'
      koru_field Path "$dev_profile"
      if jq -e '.elements | length == 0' <<< "$manifest" >/dev/null; then
        koru_line muted 'Not installed. Run koru profile build.'
        return 0
      fi
      installed=$(jq -r '.elements["dev-tools"].storePaths[0]' <<< "$manifest")
      expected=$(nix eval --no-update-lock-file --raw "$profile_installable.outPath") ||
        koru_error 'Cannot evaluate the current profile source.'
      if [[ $installed == "$expected" ]]; then
        koru_field Source 'Matches installed bundle'
      else
        koru_field Source 'Differs from installed bundle; run koru profile build to apply'
      fi
      [[ -r $installed/share/koru-dev/versions.json ]] || koru_error 'Installed version metadata is missing.'
      while IFS=$'\t' read -r name version; do
        koru_field "$name" "$version"
      done < <(jq -r 'to_entries[] | .key as $tool | .value | to_entries[] | [($tool + "/" + .key), .value] | @tsv' "$installed/share/koru-dev/versions.json")
      ;;
    # 回滚前先读取目标代清单并做同样的归属校验，防止被保留的历史非托管代带入无关包
    rollback)
      koru_lock
      target=$dev_profile-$generation-link
      [[ -L $target ]] || koru_error "Generation $generation is unavailable."
      # Inspect the target without changing the current profile. A retained
      # unmanaged generation must not reintroduce unrelated packages.
      koru_profile_source
      manifest=$(nix profile list --profile "$target" --json) || koru_error 'Cannot read target generation.'
      koru_profile_validate "$manifest"
      koru_line heading "Development profile rollback to $generation"
      koru_run nix profile rollback --profile "$dev_profile" --to "$generation"
      ;;
  esac
}
