-- ============================================================================
-- hyprland.lua —— Hyprland 主配置（Lua 脚本形式）
-- ----------------------------------------------------------------------------
-- 安装位置：~/.config/hypr/hyprland.lua（由 ../default.nix 递归链接）
--
-- 为什么用 Lua 而不是经典的 hyprland.conf？
--   新版 Hyprland 支持用 Lua 编写配置，借此可以使用变量、函数与条件判断，
--   配置片段之间可复用，便于维护。本文件中的 hl 是一个全局表，
--   由 Hyprland 在加载配置时注入，封装了全部配置接口。
--
-- 常用 hl 接口速查：
--   hl.monitor{}                    显示器设置（分辨率/刷新率/缩放）
--   hl.env{"键","值"}                设置会话环境变量
--   hl.config{...}                  设置配置块（general/decoration/debug 等）
--   hl.on(event, fn)                注册事件回调（如 hyprland.start）
--   hl.exec_cmd(cmd)                执行一条命令
--   hl.curve(name, bezier)          定义动画贝塞尔曲线
--   hl.animation{...}               配置动画（开关/速度/曲线/样式）
--   hl.window_rule{...}             窗口匹配规则
--   hl.layer_rule{...}              图层（layer）规则，常用于设置模糊
--   hl.bind(key, dispatcher)        绑定快捷键
--
-- 文件结构：
--   1. 程序启动命令变量
--   2. 修饰键变量
--   3. 显示器配置
--   4. 开机自启动
--   5. 环境变量（语言、字体渲染、缩放、光标）
--   6. 通用与生态设置
--   7. 布局与窗口外观（圆角/透明度/阴影/模糊）
--   8. 动画曲线与动画定义
--   9. 窗口规则与图层规则
--  10. 快捷键绑定
--
-- 调试技巧：
--   hyprctl reload            重新加载配置（Lua 配置支持热重载）
--   hyprctl config get <项>    查询当前配置值
--   hyprctl systemInfo        查看 Wayland 后端与显卡驱动信息
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. 常用外部程序（集中定义，便于统一修改）
-- ---------------------------------------------------------------------------
local terminal = "kitty"                                                     -- 默认终端
local yazi_filemanager = "yazi"                                              -- 终端文件管理器
local menu = "rofi -show drun -theme ~/.config/rofi/themes/app.rasi"         -- 应用启动器（rofi）
local google_browser = "google-chrome-stable"                                -- 谷歌浏览器
local zen_browser = "zen"                                                    -- Zen Browser（Firefox 的开源替代）
local music = "spotify"                                                      -- 音乐播放器

-- ---------------------------------------------------------------------------
-- 2. 修饰键前缀
-- 说明：把修饰键抽成变量，后续只需写 hl.bind(mainMod .. "x", ...)
--       即可整体更换修饰键（例如改成 Mod4 或 Super_L）。
-- ---------------------------------------------------------------------------
local mainMod = "SUPER + "      -- 主修饰键（Win/Super 键）
local super_shift = "SUPER + SHIFT + "  -- 主键 + Shift
local super_alt = "SUPER + ALT + "      -- 主键 + Alt

-- ---------------------------------------------------------------------------
-- 3. 显示器配置
-- 说明：output = "" 表示对所有显示器生效；
--       position = "auto" 由系统自动排列；scale 用于 HiDPI 缩放。
-- ---------------------------------------------------------------------------
hl.monitor({
	output = "",
	mode = "1920x1080@144", -- 目标分辨率与刷新率（需显示器支持）
	position = "auto",     -- 自动排列多显示器位置
	scale = 1,             -- 缩放比例（1080p 下保持 1）
})

-- ---------------------------------------------------------------------------
-- 4. 开机自启动
-- 触发时机：Hyprland 启动完成（hyprland.start）后依次执行。
-- ---------------------------------------------------------------------------
hl.on("hyprland.start", function()
	-- ---- 让 GUI 程序能正确识别当前 Wayland 会话 ----
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	-- ---- 桌面门户：负责截屏、文件选择、屏幕共享等系统级交互 ----
	hl.exec_cmd("xdg-desktop-portal-hyprland")
	hl.exec_cmd("xdg-desktop-portal")
	hl.exec_cmd("xdg-desktop-portal-hyprland --force-global") -- 全局模式，供 XWayland 使用

	-- ---- 自定义用户服务：把 agenix 解密的密钥注入当前图形会话【已禁用】----
	--      该服务定义在系统级 modules/systemd.nix，加解密流程停用后一并注释。
	-- hl.exec_cmd("systemctl --user start env-loader.service")

	-- ---- 音频服务重启：确保 PipeWire / WirePlumber 在会话中可用 ----
	hl.exec_cmd("systemd --user restart pipewire.service")
	hl.exec_cmd("systemd --user restart pipewire-pulse.service")
	hl.exec_cmd("systemd --user restart wireplumber.service")

	-- ---- 开机自启动软件 ----
	hl.exec_cmd("nm-applet")             -- NetworkManager 托盘图标
	hl.exec_cmd("wayvnc 0.0.0.0")         -- 远程桌面服务，监听所有网卡
	hl.exec_cmd("waybar & awww-daemon")   -- 状态栏 + 动态壁纸守护进程
	hl.exec_cmd("swaync")                 -- 通知中心
	hl.exec_cmd("fcitx5")                 -- 中文输入法
	hl.exec_cmd("clash-verge")            -- 代理客户端
end)

-- ---------------------------------------------------------------------------
-- 5. 环境变量
-- ---------------------------------------------------------------------------

-- 语言与区域
hl.env("LANG", "zh_CN.UTF-8")
hl.env("LC_ALL", "zh_CN.UTF-8")

-- 字体与渲染相关
hl.env("XFT_DPI", "96")
hl.env("XFT_ANTIALIAS", "1")
hl.env("XFT_HINTING", "1")
hl.env("XFT_HINTSTYLE", "hintfull")
hl.env("XFT_RGBA", "rgb")

-- Wayland 缩放与 DPI
hl.env("GDK_SCALE", "1")
hl.env("GDK_DPI_SCALE", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1") -- Qt 应用不绘制标题栏（边框由合成器统一处理）
hl.env("MOZ_ENABLE_WAYLAND", "1")                  -- Zen/Firefox 强制使用原生 Wayland
hl.env("WLR_NO_HARDWARE_CURSORS", "1")              -- 禁用硬件光标（部分 Intel 核显下硬件光标有闪烁问题）

-- 游标 & 图标大小（可选）
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Breeze")

-- ---------------------------------------------------------------------------
-- 6. 通用与生态设置
-- ---------------------------------------------------------------------------
hl.config({
	debug = {
		disable_logs = false,      -- 保留日志便于排查问题
		enable_stdout_logs = true, -- 同时输出到终端
	},
	ecosystem = {
		no_update_news = true, -- 禁用Hyprland更新后弹出的更新新闻窗口
		no_donation_nag = true, -- 禁用每年两次的捐赠提示窗口
	},
	misc = {
		disable_hyprland_logo = false, -- 禁用随机出现的动漫女孩或者LOGO
		force_default_wallpaper = -1, -- 强制使用三块壁纸之一，-1随机，0与1可禁用动漫壁纸
	},
})

-- ---------------------------------------------------------------------------
-- 7. 布局与窗口外观
-- ---------------------------------------------------------------------------

-- 通用配置与布局选择
hl.config({
	-- 窗口基本样式
	general = {
		gaps_out = 5, -- 窗口与显示器之间空隙
		border_size = 2, -- 窗口边框宽度
		-- 窗口边框颜色（ARGB 十六进制）
		col = {
			active_border = 0xffb48ead,   -- 活动窗口边框：Catppuccin 淡紫
			inactive_border = 0x94a38c9e, -- 非活动窗口边框：半透明灰
		},
		-- 按下窗口边框拖动改变大小
		resize_on_border = true,
		extend_border_grab_area = 40, -- 可点击拖动范围
		-- 画面撕裂，实验阶段，游戏玩家考虑选择
		allow_tearing = false,
		-- 布局算法：dwindle 为「螺旋分屏」布局
		layout = "dwindle",

		-- 浮动窗口吸附
		snap = {
			enabled = true, -- 功能开启
			window_gap = 20, -- 窗口间最小吸附间隙
			monitor_gap = 20, -- 窗口屏幕间最小吸附间隙
			border_overlap = false, -- 吸附后的俩个窗口边框是否重叠
		},
	},
	-- 布局设置（dwindle 专属参数）
	dwindle = {
		force_split = 0,              -- 强制分割比例（0 表示不强制）
		preserve_split = true,        -- 关闭其它窗口后保持分割比例
		smart_split = false,          -- 智能分割（按新窗口类型决定方向）
		smart_resizing = true,        -- 新窗口智能填充剩余空间
		permanent_direction_override = false, -- 允许临时反转分割方向
		special_scale_factor = 1,     -- special 工作区的缩放系数
		split_width_multiplier = 1.0, -- 分割宽度系数
		use_active_for_splits = true, -- 以当前活动窗口为基准进行分割
		default_split_ratio = 1.0,    -- 默认对半分屏比例
		split_bias = 0,               -- 分割偏好（正值偏 favor current）
		precise_mouse_move = false,   -- 精确鼠标移动（需开启相关的实验特性）
	},
})

-- ---------------------------------------------------------------------------
-- 窗口装饰：圆角、透明度、阴影与模糊
-- 说明：本节控制整个桌面的「观感」，是 Hyprland 相比其它合成器的亮点。
-- ---------------------------------------------------------------------------
hl.config({
	-- 窗口样式配置
	decoration = {
		rounding = 10, -- 圆角半径
		rounding_power = 2.0, -- 圆角曲线，2.0圆形，4.0圆角矩形
		-- 窗口不透明及亮度调整
		active_opacity = 0.95, -- 当前活动窗口不透明度
		inactive_opacity = 0.95, -- 非活动窗口不透明度
		fullscreen_opacity = 1, -- 全屏窗口不透明度
		dim_inactive = true, -- 非活动窗口是否变暗
		dim_strength = 0.2, -- 变暗强度
		dim_special = 0.2, -- 特殊功能工作区打开时候，调整其他屏幕变暗
		dim_around = 0.4, -- 周围窗口变暗，强调突出窗口
		-- 阴影效果
		shadow = {
			enabled = true, -- 启用窗口阴影投影效果
			range = 10, -- 设置阴影范围尺寸，px
			render_power = 2, -- 渲染功率，数值越大负载越大
			color = 0x70000000, -- 阴影颜色
			color_inactive = 0x50000000, -- 非活动窗口阴影
			offset = { 4, 4 }, -- 阴影偏移
		},
		-- 模糊效果
		blur = {
			-- 窗口模糊设置
			enabled = true, -- 开启窗口模糊效果
			size = 8, -- 模糊范围
			passes = 2, -- 模糊处理次数，至少为1，高数值会增加GPU负载
			brightness = 1.2, -- 模糊区域亮度，范围[0.0,2.0]
			vibrancy = 0.3, -- 模糊区域的色彩饱和度，效果颜色更鲜艳
			new_optimizations = true, -- 模糊效果优化，提高性能，建议开启
			-- 特殊工作区及弹出窗口模糊设置
			popups = true, -- 弹出窗口模糊，统一窗口效果，如右键菜单
			-- 输入法菜单模糊设置
			input_methods = true, -- 输入法窗口模糊设置
			input_methods_ignorealpha = 0, -- 忽略透明像素
			ignore_opacity = true, -- 模糊层是否忽略窗口不透明度
			xray = true, -- 浮动窗口忽略平铺窗口模糊效果，提升性能，仅在new_optimizations开启是时可用
		},
	},
})

-------------------------------------------------
-- 8. 动画
-- 说明：
--   hl.curve() 定义缓动曲线（CSS 风格的三次贝塞尔）
--   hl.animation{} 为某类动画设定开关、速度、曲线与样式
--     speed 越大动画越快；style 决定位移方向与缩放效果
-- 下面先定义一组命名曲线，再在各处动画中引用，便于统一调整手感。

-- 自定义贝塞尔曲线
hl.curve("gentle", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } }) -- 温和缓动，平缓自然
hl.curve("natural", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } }) -- 标准流畅。类似于css的ease-out
hl.curve("smoothOut", { type = "bezier", points = { { 0.25, 0.46 }, { 0.45, 0.94 } } }) -- 平缓自然
hl.curve("spring", { type = "bezier", points = { { 0.175, 0.885 }, { 0.32, 1.155 } } }) -- 弹簧效果
hl.curve("rocket", { type = "bezier", points = { { 0.55, 0 }, { 0.1, 1 } } }) -- 火箭效果，慢进快出
hl.curve("brake", { type = "bezier", points = { { 0.9, 0 }, { 0.45, 1 } } }) -- 刹车效果，慢->快->刹停
hl.curve("rubber", { type = "bezier", points = { { 0.68, -0.15 }, { 0.265, 1 } } }) -- 橡胶带效果，先快后回拉
hl.curve("organic", { type = "bezier", points = { { 0.645, 0.045 }, { 0.355, 1 } } }) -- 呼吸感，平缓自然
hl.curve("robotic", { type = "bezier", points = { { 0.42, 0 }, { 0.58, 1 } } }) -- 通用过度，对称加减速，平滑启停

-- 工作区贝塞尔曲线变量(回弹，动感)
hl.curve("easeInExpoSharp", { type = "bezier", points = { { 0.25, 1.0 }, { 0.5, 1.13 } } })
hl.curve("easeOutElastic", { type = "bezier", points = { { 0.3, 0.3 }, { 0.5, 1.12 } } })

-- 默认
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
-- 边框动画设置
hl.animation({ leaf = "border", enabled = true, speed = 15, bezier = "easeOutQuint" })
-- 窗口动画设置
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.6, bezier = "gentle", style = "popin 70%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 49, bezier = "spring", style = "popin 70%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.8, bezier = "spring" })
-- 图层动画
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "rubber", style = "slide top" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "robotic", style = "slide top" })
-- 窗口的淡入淡出
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "smoothOut" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "smoothOut" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 2.3, bezier = "smoothOut" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 2.6, bezier = "smoothOut" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 2.6, bezier = "smoothOut" })
-- 弹窗的淡入淡出
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2.79, bezier = "organic" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "organic" })
-- 工作区
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.8, bezier = "organic", style = "slidefadevert" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 3.4, bezier = "organic", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3.6, bezier = "organic", style = "slide" })

-------------------------------------------------
-- 9. 窗口规则与图层规则
-- 说明：
--   hl.window_rule{} 按 class/title 等条件给窗口附加属性（浮动/居中/尺寸等）
--   hl.layer_rule{}    按 layer namespace 控制该图层的模糊等效果
-- -------------------------------------------------
hl.window_rule({
	match = {
		class = ".*", -- 匹配所有窗口
	},
	suppress_event = "maximize", -- 抑制窗口自行发送的 maximize 事件（避免部分程序抢焦点）
})

-- 规则：XWayland 下 class 与 title 均为空的「幽灵窗口」一律浮动
hl.window_rule({
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
	},
	float = true,
	fullscreen = false,
	pin = false,
})

-- 规则：由快捷键标记为 floating-term 的终端窗口 → 居中 + 60% 屏幕大小 + 浮动
hl.window_rule({
	match = {
		class = "floating-term",
	},
	center = true,
	size = { "(monitor_w*0.6)", "(monitor_h*0.6)" },
	float = true,
})

-- 图层规则：注销对话框（背景模糊）
hl.layer_rule({
	match = {
		namespace = "logout_dialog",
	},
	blur = true,
})

-- 图层规则：通知中心（swaync）
hl.layer_rule({
	match = {
		namespace = "notifications",
	},
	blur = true,
	blur_popups = true,
	xray = true,
})

-- 图层规则：rofi 启动器
hl.layer_rule({
	match = {
		namespace = "rofi",
	},
	blur = true,
	blur_popups = true,
	xray = true,
	ignore_alpha = false,
})

-------------------------------------------------
-- 10. 快捷键
-- 说明：hl.bind(按键, dispatcher)
--   dispatcher 常见类别：
--     hl.dsp.exec_cmd(cmd)         执行命令
--     hl.dsp.window.*              针对窗口的操作（关闭/全屏/浮动/移动/缩放）
--     hl.dsp.focus({...})          移动焦点（方向或工作区）
--     hl.dsp.layout("togglesplit") 切换分割方向
--     hl.dsp.workspace.*           工作区操作
--
-- 修饰键速查：
--   SUPER         = Win 键（mainMod）
--   SUPER+SHIFT   = super_shift
--   SUPER+ALT     = super_alt
--
-- 鼠标按键代码（用于 mouse:XXX 绑定）：
--   272 = 左键    273 = 右键    274 = 中键
--
-- ---- 启动程序 ----
hl.bind(mainMod .. "return", hl.dsp.exec_cmd(terminal)) -- 打开默认终端
hl.bind(super_shift .. "return", hl.dsp.exec_cmd(terminal .. " --class floating-term")) -- 标记浮动终端，在窗口规则设置浮动终端样式
hl.bind(mainMod .. "b", hl.dsp.exec_cmd(google_browser)) -- 打开谷歌浏览器
hl.bind(super_shift .. "b", hl.dsp.exec_cmd(zen_browser))
hl.bind(mainMod .. "m", hl.dsp.exec_cmd(music))
hl.bind(mainMod .. "d", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. "e", hl.dsp.exec_cmd("EDITOR=nvim kitty " .. yazi_filemanager))
hl.bind(mainMod .. "n", hl.dsp.exec_cmd("neovide"))
hl.bind(mainMod .. "l", hl.dsp.exec_cmd("hyprlock"))
hl.bind(super_shift .. "ESCAPE", hl.dsp.exec_cmd("wlogout -b 4"))

-- ---- 重载配置并重启状态栏与远程桌面（改完配置后立即生效）----
hl.bind(
	super_shift .. "r",
	hl.dsp.exec_cmd("hyprctl reload && \
    if pidof waybar > /dev/null; then pkill waybar; fi && waybar & \
    if pidof wayvnc > /dev/null; then pkill wayvnc; fi && wayvnc 0.0.0.0 &")
)

-- ---- 窗口操作 ----
hl.bind(mainMod .. "q", hl.dsp.window.kill()) -- 关闭窗口
hl.bind(
	super_shift .. "g",
	hl.dsp.exec_cmd('\
    file=~/screenshot/$(date +\'%Y-%m-%d-%H%M%S\').png && \
    grim -g "$(slurp)" $file && \
    wl-copy < $file && \
    satty --filename $file --output-filename $file && \
    wl-copy < $file && \
    notify-send "区域截图,已保存至~/screenshot并打开编辑器"')
) -- 区域截图
hl.bind(mainMod .. "g", hl.dsp.exec_cmd("~/.config/hypr/scripts/capture.sh")) -- 捕获功能
hl.bind(super_shift .. "w", hl.dsp.exec_cmd("~/.config/wallpaper/script/awww-rofi.sh")) -- 壁纸切换快捷键

-- ---- 窗口布局 ----
hl.bind(mainMod .. "f", hl.dsp.window.fullscreen_state({ internal = 2, client = 0, action = "toggle" })) -- 全屏
hl.bind(super_shift .. "f", hl.dsp.window.fullscreen_state({ internal = 1, client = 0, action = "toggle" })) -- 假全屏（最大化但保留状态栏）
hl.bind(mainMod .. "p", hl.dsp.window.float({ action = "toggle" })) -- 切换当前窗口的布局模式为浮动模式或平铺模式
hl.bind(super_shift .. "p", hl.dsp.window.pin({ action = "toggle" })) -- 固定浮动窗口
hl.bind(super_shift .. "a", hl.dsp.window.center()) -- 窗口居中
hl.bind(mainMod .. "v", hl.dsp.window.pseudo({ action = "toggle" })) --  伪窗口模式（pseudo 模式），常用来布局微调，配合改变窗口大小使用
hl.bind(mainMod .. "j", hl.dsp.layout("togglesplit")) --  切换当前窗口的分割方向（水平/垂直）

-- ---- 焦点移动 ----
-- 使用主修饰键（mainMod）加方向键来移动焦点
-- 从浮窗 / 当前窗口回到上一个窗口（通常是平铺主窗口）
hl.bind(mainMod .. "tab", hl.dsp.window.cycle_next())
hl.bind(mainMod .. "left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. "right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. "up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. "down", hl.dsp.focus({ direction = "d" }))
-- ---- 移动窗口交换位置 ----
hl.bind(super_shift .. "left", hl.dsp.window.swap({ direction = "l" }))
hl.bind(super_shift .. "right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(super_shift .. "up", hl.dsp.window.swap({ direction = "u" }))
hl.bind(super_shift .. "down", hl.dsp.window.swap({ direction = "d" }))

-- ---- 调整窗口大小 ----
-- 右箭头：向右下扩大（正数）
hl.bind(super_alt .. "right", hl.dsp.window.resize({ x = 10, y = 10, relative = true }))
-- 左箭头：向左上缩小（负数）
hl.bind(super_alt .. "left", hl.dsp.window.resize({ x = -10, y = -10, relative = true }))

-- 鼠标拖动：移动 / 调整窗口（bindm）
-- 鼠标左键（272）拖动窗口
hl.bind(mainMod .. "mouse:272", hl.dsp.window.drag())
-- 鼠标右键（273）调整窗口大小
hl.bind(mainMod .. "mouse:273", hl.dsp.window.resize())

-- ---- 工作区切换（workspace）----
-- 鼠标滚轮在工作区之间循环（e-1/e+1 表示相对当前工作区的上一个/下一个）
hl.bind(mainMod .. "mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. "mouse_down", hl.dsp.focus({ workspace = "e+1" }))

-- 主修饰键 + 数字键 0~9 切换到对应工作区（0 对应 10）
hl.bind(mainMod .. "1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. "2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. "3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. "4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. "5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. "6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. "7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. "8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. "9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. "0", hl.dsp.focus({ workspace = 10 }))
-- 主修饰键 + [ / ] 切换到上一个/下一个工作区
hl.bind(mainMod .. "bracketleft", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. "bracketright", hl.dsp.focus({ workspace = "e+1" }))
-- 移动到最近的空工作区
hl.bind(mainMod .. "z", hl.dsp.focus({ workspace = "empty" }))

-- ---- 将当前窗口移动到指定工作区（movetoworkspace）----
-- 移动到数字工作区 1~10（把窗口「送走」而非仅切换焦点）
hl.bind(super_shift .. "1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(super_shift .. "2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(super_shift .. "3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(super_shift .. "4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(super_shift .. "5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(super_shift .. "6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(super_shift .. "7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(super_shift .. "8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(super_shift .. "9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(super_shift .. "0", hl.dsp.window.move({ workspace = 10 }))
-- 移动到上一个/下一个工作区（相对移动）
hl.bind(super_shift .. "bracketleft", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(super_shift .. "bracketright", hl.dsp.window.move({ workspace = "r+1" }))
-- 将窗口移动到空工作区（empty 目标）
hl.bind(super_shift .. "z", hl.dsp.window.move({ workspace = "empty" }))

-- 特殊工作区（"隐藏桌面" 功能）
-- 注意：特殊工作区名称 "special:" 中的图标需与你的字体兼容
hl.bind(mainMod .. "s", hl.dsp.workspace.toggle_special("")) -- 切换特殊工作区
hl.bind(super_shift .. "s", hl.dsp.window.move({ workspace = "special:" })) -- 当前窗口移入特殊工作区

-- 额外：将窗口移动到 +0 工作区（可能用于快速移回？保留原样）
hl.bind(super_shift .. "x", hl.dsp.window.move({ workspace = 0 }))
