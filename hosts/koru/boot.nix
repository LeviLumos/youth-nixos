# boot.nix —— koru 主机的引导配置：systemd-boot 引导器、initrd、内核参数与
# 驱动黑名单。
# 由 flake.nix 的 mkHost 以目录 ./hosts/koru 导入，并经 hosts/koru/default.nix
#   汇总生效。
# 本文件大量取值来自实际排查：ESP 容量、iTPM 响应延迟、GSP 固件失败刷屏、
#   xe/i915 抢占等，注释均说明取舍理由。
# koru: systemd-boot, initrd, kernel parameters and driver exclusions.
{
  boot.loader.systemd-boot.enable = true;  # 用 systemd-boot 而非 GRUB 作为 EFI 引导器
  boot.loader.efi.canTouchEfiVariables = true;  # 安装/升级时自动把引导项写入主板 EFI 变量（NVRAM）
  boot.loader.timeout = 0;  # 引导菜单不倒计时，直接启动默认项，加快开机
  # Tiny 256M ESP: keep only the 5 newest generations (each initrd is ~44M) or
  # rebuilds fail with "No space left on device".
  boot.loader.systemd-boot.configurationLimit = 5;  # ESP 分区仅 256M，每个 initrd 约 44M，只留最近 5 代，否则重建报空间不足

  # --- Kernel ---
  # Quiet boot: less console spam. nowatchdog disables the kernel lockup
  # watchdog timers (NMI/scheduler), saving a bit of boot and idle CPU time.
  # 内核启动参数：
  # - quiet: 压制控制台日志刷屏；
  # - 8250.nr_uarts=0: 不探测传统串口（本机无此需求）；
  # - nowatchdog + nmi_watchdog=0: 关闭内核软锁看门狗（NMI/调度器定时器），
  #   省下少量启动与待机 CPU 时间。
  boot.kernelParams = [
    "quiet"
    "video=1920x1080" # Internal panel mode from boot.
    "8250.nr_uarts=0"
    "nowatchdog"
    "nmi_watchdog=0"
  ];

  # No LUKS/cryptenroll/PCR usage, so drop TPM probing from the initrd: the
  # tpm2.target wait on the (slow) Intel iTPM was adding ~1-3s to boot.
  boot.initrd.systemd.tpm2.enable = false;  # 不使用 LUKS/TPM，跳过 initrd 的 tpm2.target 等待——Intel iTPM 响应慢，曾拖慢开机 1-3 秒

  # Driver blacklist:
  # - tpm_crb/tpm_tis: the Intel iTPM (INTC6001, tpm_crb) takes ~3s to respond
  #   during udev coldplug, blocking the whole device queue (even NVMe gets
  #   delayed). No TPM usage at all, so stop probing it in initrd + userspace.
  # - iTCO_wdt: Intel TCO hardware watchdog: can't be stopped at power-off, so
  #   the kernel prints "watchdog did not stop!" every shutdown. Unused anyway.
  # - nouveau: drives the unused RTX 4060 dGPU (display runs on the Intel
  #   iGPU). nouveau must talk to the GSP firmware on this chip, which fails
  #   every boot and spams ~33 identical "gsp ... ctrl cmd failed" errors.
  # - xe: the new Intel GPU driver also matches the Raptor Lake-S iGPU
  #   (8086:a78b) but refuses to drive it ("not officially supported"). It can
  #   win the PCI modalias race against i915: xe then declines the device and
  #   i915 never binds, leaving only simpledrm, so niri starts with no render
  #   node and the screen stays black at the tty1 autologin. Force i915.
  boot.blacklistedKernelModules = [  # 逐项理由见上方英文注释：iTPM 探测阻塞、TCO 看门狗关机报错、nouveau GSP 失败刷屏、xe 抢占 i915 致黑屏
    "tpm_crb"
    "tpm_tis"
    "iTCO_wdt"
    "nouveau"
    "xe"
  ];

  # systemd-initrd: parallel device probing, faster and more robust.
  boot.initrd.systemd.enable = true;  # systemd 化 initrd：并行探测设备，更快更稳
  # Load crc32c before btrfs mounts /sysroot: without it btrfs fails with
  # "error allocating crc32c hash for checksum" (systemd-initrd module order).
  # initrd 额外内核模块：
  # - crc32c_cryptoapi: 必须在 btrfs 挂载 /sysroot 前加载，否则报
  #   crc32c hash 分配错误（systemd-initrd 的模块顺序问题）；
  # - autofs4: 支持自动挂载。
  boot.initrd.kernelModules = [
    "crc32c_cryptoapi"
    "autofs4"
  ];
  # availableKernelModules is intentionally left to hardware-configuration.nix:
  # overriding it (even to "trim" modules) silently drops whatever the generated
  # list gains on a kernel or hardware change.
}
