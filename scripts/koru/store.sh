#!/usr/bin/env bash
# koru/store.sh —— Nix 存储子命令组：status 展示磁盘/store 占用与 nix-gc
# 服务状态；gc 触发一次垃圾回收。
# gc 不带 --delete-older-than，因此所有保留代仍然安全；写操作前加 koru 锁。
# Globals are initialized by common.sh.
# shellcheck disable=SC2154

koru_store() {
  case $1 in
    # df 读 /nix/store 分区用量；du 统计 store 实际大小（可能较慢，先提示）；
    # 从 systemd 读取 nix-gc.service 最近结果/完成时间与 nix-gc.timer 活跃状态
    status)
      local size used available percent store_size gc_result gc_time
      koru_line heading 'Nix storage'
      read -r size used available percent < <(df -h --output=size,used,avail,pcent /nix/store | tail -n 1)
      koru_field 'Disk total' "$size"
      koru_field 'Disk used' "$used ($percent)"
      koru_field 'Disk free' "$available"
      koru_line muted 'Measuring store size...'
      store_size=$(du -sh /nix/store | cut -f 1)
      koru_field 'Store size' "$store_size"
      gc_result=$(systemctl show nix-gc.service --property=Result --value)
      gc_time=$(systemctl show nix-gc.service --property=ExecMainExitTimestamp --value)
      koru_field 'Last GC' "${gc_result:-unknown}"
      koru_field 'GC finished' "${gc_time:-never}"
      koru_field 'GC timer' "$(systemctl is-active nix-gc.timer || true)"
      ;;
    # 加锁后用 sudo nix-collect-garbage；不带 --delete-older-than，因此所有保留代仍然安全
    gc)
      koru_lock
      koru_line heading 'Nix garbage collection'
      koru_line muted 'Retained generations are preserved.'
      koru_run "$sudo_command" nix-collect-garbage
      ;;
  esac
}
