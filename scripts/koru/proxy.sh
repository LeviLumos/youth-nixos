#!/usr/bin/env bash
# koru/proxy.sh —— 代理子命令组：是 proxyctl 的薄包装（KORU_PROXYCTL 指定路径）。
# status/list 解析 proxyctl 的 --json 输出用 render.py 着色；
#   start/refresh/stop/autostart 加锁后透传（--color never 便于日志整理）。
# proxyctl 本体由 system/mihomo.nix 打包进系统 profile。
# Globals are initialized by common.sh.
# shellcheck disable=SC2154

koru_proxy() {
  local action=$1 data node delay count status=0
  # proxyctl 未安装（system profile 缺少该可执行）时直接报错
  [[ -x $proxy_command ]] || koru_error 'Proxy service tools are not installed.'
  case $action in
    # 解析 status --json：校验 JSON 结构后再逐字段展示，保留 proxyctl 的退出码
    status)
      data=$("$proxy_command" status --json) || status=$?
      jq -e 'type == "object" and has("service")' <<< "$data" >/dev/null || koru_error 'Proxy status query failed.'
      koru_line heading 'Proxy status'
      koru_field Service "$(jq -r '.service' <<< "$data")"
      koru_field Controller "$(jq -r '.controller' <<< "$data")"
      koru_field TUN "$(jq -r '.tun' <<< "$data")"
      koru_field Node "$(jq -r '.node // "none"' <<< "$data")"
      koru_field 'Cached delay' "$(jq -r 'if .node_latency_ms == null then "unknown" else "\(.node_latency_ms) ms" end' <<< "$data")"
      koru_field Nodes "$(jq -r '.cache.usable_nodes' <<< "$data")"
      return "$status"
      ;;
    # 展示缓存节点列表（延迟+名称）；节点名中的控制字符替换为问号，防终端注入
    list)
      data=$("$proxy_command" nodes --json) || koru_error 'No node cache. Run koru proxy refresh.'
      count=$(jq 'length' <<< "$data")
      koru_line heading "Proxy nodes ($count)"
      while IFS=$'\t' read -r delay node; do
        koru_field "$delay ms" "$node"
      done < <(jq -r '.[] | [.latency_ms, (.name | gsub("[\\x00-\\x1F\\x7F]"; "?"))] | @tsv' <<< "$data")
      ;;
    # start 需交互终端做 fzf 选节点，非交互要求用 autostart；
    # 修改类操作统一先取 koru 锁
    start)
      [[ -t 0 && -t 1 ]] || koru_error 'Interactive terminal required. Use autostart.'
      koru_lock
      koru_run "$proxy_command" --color never start
      ;;
    # --color never 确保 proxyctl 输出无 ANSI 转义，便于 koru_run 日志整理
    refresh) koru_lock; koru_line heading 'Proxy refresh'; koru_run "$proxy_command" --color never refresh --restore ;;
    stop) koru_lock; koru_line heading 'Proxy stop'; koru_run "$proxy_command" --color never shutdown ;;
    autostart) koru_lock; koru_line heading 'Proxy autostart'; koru_run "$proxy_command" --color never autostart ;;
  esac
}
