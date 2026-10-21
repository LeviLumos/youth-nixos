#!/usr/bin/env bash
# koru/system.sh —— NixOS 系统级子命令组：list/build/check/rollback。
# 由 koru.sh source 后调用 koru_system；全局变量（system_profile 等）
#   由 common.sh 的 koru_init 初始化。
# build 走 sudo nixos-rebuild switch；check 只构建不切换；
#   rollback 先切 profile 再执行目标代的 switch-to-configuration。
# Globals are initialized by koru.sh and common.sh.
# shellcheck disable=SC2154

koru_system() {
  local action=$1 target
  case $action in
    # 列出 /nix/var/nix/profiles/system 的保留代
    list) koru_generations "$system_profile" System ;;
    # sudo nixos-rebuild switch 切换系统配置；--no-update-lock-file 不自动更新 flake.lock
    build)
      koru_repository; koru_lock
      koru_line heading 'System build and switch'
      koru_run "$sudo_command" nixos-rebuild switch --flake "$repository_root#koru" --no-update-lock-file
      ;;
    # 只构建不切换：构建 toplevel 验证求值与构建通过
    check)
      koru_repository; koru_lock
      koru_line heading 'System build check'
      koru_run nix build --no-link --no-update-lock-file "$repository_root#nixosConfigurations.koru.config.system.build.toplevel"
      ;;
    # 回滚系统代：确认目标代的 switch-to-configuration 存在后，
    # 先 nix-env --switch-generation 切 profile，
    # 再运行目标代 bin/switch-to-configuration switch 实际生效
    rollback)
      koru_lock
      target=$system_profile-$generation-link
      [[ -L $target && -x $target/bin/switch-to-configuration ]] || koru_error "Generation $generation is unavailable."
      koru_line heading "System rollback to $generation"
      koru_run "$sudo_command" nix-env --profile "$system_profile" --switch-generation "$generation"
      koru_run "$sudo_command" "$target/bin/switch-to-configuration" switch
      ;;
  esac
}
