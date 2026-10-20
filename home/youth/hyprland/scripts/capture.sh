#!/usr/bin/env bash
# ============================================================================
# capture.sh —— 截图与录屏统一入口
# ----------------------------------------------------------------------------
# 该脚本由 Hyprland 快捷键调用（配置见 ../hypr/hyprland.lua），
# 也是 Waybar 状态栏录屏指示器（custom/wf-recorder）左键点击后的入口。
#
# 整体流程：
#   main()
#     ├─ 若正在录屏  -> 弹出二级菜单：停止录屏 / 全屏截图 / 区域截图 / 取消
#     └─ 若未在录屏  -> 弹出主菜单：全屏截图 / 区域截图 / 全屏录屏 / 区域录屏 / 取消
#
# 核心依赖：
#   grim     截屏（Wayland 原生截图工具）
#   slurp    区域选择（返回 "X Y W H" 几何信息）
#   satty    截图后的标注/裁剪编辑器
#   wf-recorder 录屏（支持 VA-API 硬件编码）
#   pw-dump / jq  枚举麦克风设备
#   wl-copy  复制图片到剪贴板
#   rofi     弹出选择菜单
#   notify-send 桌面通知（来自 libnotify，见 home/youth/default.nix）
#
# 取消约定：
#   所有选择函数在被 ESC 取消时统一返回字符串 "CANCELLED"，
#   上层据此跳过后续动作，避免与真实的空结果混淆。
#
# 文件产出：
#   截图 -> ~/screenshot/<时间戳>.png
#   录屏 -> ~/Videos/recordings/recording_<时间戳>.mp4
#
# 安装位置：~/.config/hypr/scripts/capture.sh
# ============================================================================

# 严格模式：命令出错立即退出、未定义变量报错、管道失败即失败
set -euo pipefail

# =============================================================================
# 配置常量
# 说明：readonly 表示常量，重复赋值会直接报错，防止误改
# =============================================================================
# 截图保存目录（由 home-manager 的激活钩子自动创建，见 home/youth/default.nix）
readonly SCREENSHOT_DIR="$HOME/screenshot"
readonly RECORDING_DIR="$HOME/Videos/recordings" # 录屏保存目录
readonly PIDFILE="/tmp/wf-recorder.pid"          # 录屏进程 PID 文件（供状态栏脚本检测）
readonly TIMESTAMP=$(date +%F-%H%M%S)            # 本次会话的时间戳，用于文件命名
readonly ROFI_THEME="${ROFI_THEME:-$HOME/.config/rofi/themes/screenshot.rasi}" # 菜单主题（可用环境变量覆盖）

# =============================================================================
# 工具函数
# =============================================================================

# 创建必要目录（幂等，目录已存在时不会报错）
create_directories() {
    mkdir -p "$SCREENSHOT_DIR" "$RECORDING_DIR"
}

# 检查依赖是否安装
# 用法：check_dependency <命令名>
# 缺失时通过 notify-send 弹出错误通知并返回 1，供调用方使用 return 提前退出
check_dependency() {
    if ! command -v "$1" >/dev/null 2>&1; then
        notify-send "❌ 错误" "$1 未安装"
        return 1
    fi
    return 0
}

# 获取屏幕列表
# 说明：wlr-randr 可查询/设置输出设备的分辨率、缩放与刷新率；
#       awk 提取每行行首的输出名（如 eDP-1、DP-1）。
get_screens() {
    if command -v wlr-randr >/dev/null 2>&1; then
        wlr-randr | awk '/^[^[:space:]]/ {print $1}'
    else
        echo ""
    fi
}

# 选择音频源
# 说明：返回可直接追加到 wf-recorder 命令行中的参数字符串；
#       用户 ESC 取消时返回 "CANCELLED"。
#   系统音频 -> -a --audio-backend=pipewire （直接抓取系统混音输出）
#   麦克风   -> 通过 pw-dump 枚举所有 Audio/Source 类型的节点，取其 node.name
select_audio() {
    local choices="系统音频\n麦克风\n无音频"
    local choice=$(echo -e "$choices" | rofi -theme "$ROFI_THEME" -dmenu -p "选择音频源")

    [ -z "$choice" ] && echo "CANCELLED" && return

    local audio_option=""
    case "$choice" in
        "系统音频")
            audio_option="-a --audio-backend=pipewire"
            ;;
        "麦克风")
            audio_option="-a $(pw-dump | jq -r '.[] | select(.type=="PipeWire:Interface:Node" and .info.props["media.class"]=="Audio/Source") | .info.props["node.name"]')"
            ;;
    esac

    echo "$audio_option"
}

# 选择屏幕
# 逻辑：0 个屏幕 -> 报错；1 个屏幕 -> 直接使用；多个屏幕 -> 弹出 rofi 选择
select_screen() {
    local screens=($(get_screens))

    if [ "${#screens[@]}" -eq 0 ]; then
        notify-send "❌ 错误" "未检测到屏幕"
        echo "CANCELLED"
        return
    elif [ "${#screens[@]}" -eq 1 ]; then
        echo "${screens[0]}"
    else
	local selected=$(echo "${screens[@]}" | tr ' ' '\n' | rofi -theme "$ROFI_THEME" -dmenu -p "选择屏幕")
	# 如果按 ESC，selected 为空
        if [ -z "$selected" ]; then
            echo "CANCELLED"
        else
            echo "$selected"
        fi
    fi
}

# 选择区域（ESC 取消）
select_region() {
    if ! check_dependency "slurp"; then
        echo "CANCELLED"
        return
    fi
    
    local region=$(slurp)
    # 如果用户按 ESC 选择区域，slurp 会返回非零退出码，region 为空
    if [ -z "$region" ]; then
        echo "CANCELLED"
    else
        echo "$region"
    fi
}

# 启动录屏
# 参数：<输出文件> [区域几何信息] [输出屏幕名] [音频参数字符串]
# 说明：
#   -f         指定输出文件
#   -c h264_vaapi  使用 Intel 核显的 VA-API 硬件编码（低 CPU 占用）
#   -r 30      目标帧率 30fps
#   后台启动（&）并把进程号写入 PIDFILE，供状态栏脚本与后续停止操作使用。
start_recording() {
    local file="$1"
    local region="${2:-}"
    local screen="${3:-}"
    local audio="${4:-}"

    local cmd=(wf-recorder -f "$file" -c h264_vaapi -r 30)

    [ -n "$region" ] && cmd+=(-g "$region")
    [ -n "$screen" ] && cmd+=(-o "$screen")
    if [ -n "$audio" ] && [ "$audio" != "CANCELLED" ]; then
        eval "cmd+=($audio)"
    fi

    "${cmd[@]}" &
    echo $! > "$PIDFILE"
}

# 处理截图后续操作
# 参数：<截图文件路径>
# 四种处理方式：
#   编辑并保存     —— 用 satty 打开标注编辑器，结果覆盖原文件，并复制到剪贴板
#   仅保存         —— 保留文件，发送通知
#   仅复制到剪贴板 —— wl-copy 复制后删除临时文件（适合「截图即粘贴」场景）
#   取消           —— 删除临时文件
handle_screenshot_action() {
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local action=$(echo -e "编辑并保存\n仅保存\n仅复制到剪贴板\n取消" | \
                   rofi -theme "$ROFI_THEME" -dmenu -p "截图完成，选择操作:")

    # 如果按 ESC，action 为空，等同于取消
    if [ -z "$action" ]; then
        action="取消"
    fi

    sleep 0.2

    case "$action" in
        "编辑并保存")
            satty -f "$file" -o "$file"
            wl-copy --type image/png < "$file"
            notify-send "📸 截图已保存并复制到剪贴板" "$file"
            ;;
        "仅保存")
            notify-send "📸 截图已保存" "$file"
            ;;
        "仅复制到剪贴板")
            wl-copy --type image/png < "$file"
            rm "$file"
            notify-send "📋 截图已复制到剪贴板"
            ;;
        "取消")
            rm "$file"
            notify-send "❌ 截图已取消"
            ;;
    esac
}

# =============================================================================
# 截图功能
# =============================================================================

# 全屏截图：grim 直接抓取整块屏幕并输出文件路径
take_fullscreen_screenshot() {
    local file="$SCREENSHOT_DIR/${TIMESTAMP}.png"

    if ! check_dependency "grim"; then
        return 1
    fi

    grim "$file"
    echo "$file"
}

# 区域截图：先由 slurp 让用户框选，再 grim 按几何信息截取
take_region_screenshot() {
    local file="$SCREENSHOT_DIR/${TIMESTAMP}.png"

    if ! check_dependency "grim" || ! check_dependency "slurp"; then
        return 1
    fi

    local region=$(select_region)
    # 如果用户在选择区域时按 ESC，取消截图
    if [ "$region" = "CANCELLED" ]; then
        # 删除可能已经创建的文件
        [ -f "$file" ] && rm "$file"
        echo "CANCELLED"
        return
    fi

    grim -g "$region" "$file"
    echo "$file"
}

# 录屏状态下的截图处理
# 参数：<"full" 或 "region">
# 说明：录屏时仍允许截图，截图同样进入完整的二级操作菜单
handle_recording_screenshot() {
    local type="$1"  # "full" 或 "region"
    local file

    if [ "$type" = "full" ]; then
        file=$(take_fullscreen_screenshot)
    else
        file=$(take_region_screenshot)
    fi

    # 截图被取消（包括 ESC 按键）
    if [ "$file" = "CANCELLED" ]; then
        notify-send "📸 截图已取消"
        return
    fi

    if [ -n "$file" ]; then
        # 在录屏状态下也显示完整的二级菜单
        handle_screenshot_action "$file"
    fi
}

# =============================================================================
# 录屏功能
# =============================================================================

# 开始录屏
# 参数：<"fullscreen" 或 "region">
# 流程：选择音频 -> 选择屏幕 -> （区域录屏时）选择区域 -> 启动 wf-recorder
# 任意一步被 ESC 取消都会发送通知并提前返回
start_screen_recording() {
    local recording_type="$1"  # "fullscreen" 或 "region"
    local timestamp=$(date +%F-%H%M%S)
    local file="$RECORDING_DIR/recording_${TIMESTAMP}.mp4"

     # 选择音频（ESC 取消）
    local audio=$(select_audio)
    if [ "$audio" = "CANCELLED" ]; then
        notify-send "🎬 录屏已取消" "用户取消了音频选择"
        return 1
    fi

    # 选择屏幕（ESC 取消）
    local screen=$(select_screen)
    if [ "$screen" = "CANCELLED" ]; then
        notify-send "🎬 录屏已取消" "用户取消了屏幕选择"
        return 1
    fi

    local region=""

    [ -z "$screen" ] && return 1

    if [ "$recording_type" = "region" ]; then
        # 选择区域（ESC 取消）
	region=$(select_region)
        if [ "$region" = "CANCELLED" ]; then
            notify-send "🎬 录屏已取消" "用户取消了区域选择"
            return 1
        fi
    fi

    start_recording "$file" "$region" "$screen" "$audio"
    notify-send "🎬 录屏开始" "屏幕: $screen\n文件: $file\n音频: ${audio:-无}"
}

# =============================================================================
# 主函数
# =============================================================================

# 脚本入口：按当前是否在录屏，展示不同的菜单
main() {
    create_directories # 确保截图与录屏目录存在

    # 检查是否正在录屏（PID 文件存在且进程存活）
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
       local action=$(echo -e "停止录屏\n全屏截图\n区域截图\n取消" | rofi -theme "$ROFI_THEME" -dmenu -p "录屏中，选择操作:")

        # 按 ESC，action 为空，等同于取消
        if [ -z "$action" ]; then
            action="取消"
        fi

        case "$action" in
            "停止录屏")
                kill "$(cat "$PIDFILE")"
                rm "$PIDFILE"
                notify-send "🎬 录屏已停止"
                ;;
            "全屏截图")
                sleep 0.2
                handle_recording_screenshot "full"
                ;;
            "区域截图")
                handle_recording_screenshot "region"
                ;;
            "取消")
                # 什么都不做，直接退出
                ;;
        esac
        exit 0
    fi

    # 主菜单选择（未录屏时的默认入口）
    local choice=$(echo -e "全屏截图\n区域截图\n全屏录屏\n区域录屏\n取消" | \
                   rofi -theme "$ROFI_THEME" -dmenu -p "选择操作:")

    # 按 ESC，choice 为空，等同于取消
    if [ -z "$choice" ]; then
        choice="取消"
    fi

    sleep 0.2

    local screenshot_file=""

    case "$choice" in
        "全屏截图")
            screenshot_file=$(take_fullscreen_screenshot)
            ;;
        "区域截图")
            screenshot_file=$(take_region_screenshot)
            ;;
        "全屏录屏")
            start_screen_recording "fullscreen"
            exit 0
            ;;
        "区域录屏")
            start_screen_recording "region"
            exit 0
            ;;
        "取消")
            exit 0
            ;;
    esac

    # 处理截图后续操作
    if [ -n "$screenshot_file" ] && [ "$screenshot_file" != "CANCELLED" ]; then
        handle_screenshot_action "$screenshot_file"
    elif [ "$screenshot_file" = "CANCELLED" ]; then
        notify-send "📸 截图已取消"
    fi
}

# =============================================================================
# 脚本入口
# 说明：main 处理全部逻辑，此处直接调用即可
# =============================================================================
main "$@"
