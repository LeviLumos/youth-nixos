#!/usr/bin/env bash
# koru/home.sh —— home-manager 子命令组：modules/enable/disable/validate、
# list/build/check/rollback。
# 由 koru.sh source 后调用 koru_home；全局变量（home_profile、
#   modules_command 等）由 common.sh 初始化。
# 模块开关的“编辑+格式化+候选求值+原子替换”逻辑在 scripts/home-modules.sh，
#   本文件只负责加锁与调用；build 走 home-manager switch --no-update-lock-file。
# Globals are initialized by koru.sh and common.sh.
# shellcheck disable=SC2154

koru_home() {
  local action=$1 target data name state
  case $action in
    # 列出模块开关：复用 home-modules.sh list 的解析结果逐行着色显示
    modules)
      # 列出 home-manager 保留代
      data=$(KORU_REPO=$repository_root bash "$modules_command" list) || koru_error 'Cannot read module switches.'
      koru_line heading 'Home modules'
      while read -r name state; do
        if [[ $state == true ]]; then
          koru_line success "  enabled   $name"
        else
          koru_line muted "  disabled  $name"
        fi
      done <<< "$data"
      ;;
    # 修改类操作先取 flock 互斥锁，再交给 home-modules.sh 完成
    # “编辑+格式化+候选求值+原子替换”
    enable | disable | validate)
      koru_lock
      koru_line heading "Home modules: $action"
      koru_run env KORU_REPO="$repository_root" bash "$modules_command" "$action" "${module_names[@]}"
      ;;
    list) koru_generations "$home_profile" Home ;;
    # 构建并切换：先 koru_repository 检查（含未跟踪文件告警），
    # home-manager switch --no-update-lock-file 不自动改 lock
    build)
      koru_repository; koru_lock
      koru_line heading 'Home build and switch'
      koru_run home-manager switch --flake "$repository_root#koru" --no-update-lock-file
      ;;
    # 只构建不激活：nix build --no-link 构建 activationPackage 验证可求值可构建
    check)
      koru_repository; koru_lock
      koru_line heading 'Home build check'
      koru_run nix build --no-link --no-update-lock-file "$repository_root#homeConfigurations.koru.activationPackage"
      ;;
    # 回滚到指定代：先确认 <profile>-<N>-link 存在且含可执行 activate，再执行激活脚本
    rollback)
      koru_lock
      target=$home_profile-$generation-link
      [[ -L $target && -x $target/activate ]] || koru_error "Generation $generation is unavailable."
      koru_line heading "Home rollback to $generation"
      koru_run "$target/activate"
      ;;
  esac
}
