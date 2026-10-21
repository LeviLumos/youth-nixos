# pipewire-audio.nix —— PipeWire 音频栈（现代 Wayland 方案）。
# 作用：以 PipeWire 统一替换 PulseAudio/JACK，提供 ALSA（含 32 位兼容）
#   与 PulseAudio 协议桥接，覆盖全系统（非按用户）。
# 导入：由 system/default.nix 显式导入。
# 机制：services.pipewire 启用 pipewire/pipewire-alsa/pipewire-pulse 的用户级
#   systemd 服务（通过 sockets 激活）；rtkit 允许 PipeWire 无需 root 即可获得
#   实时调度优先级，降低爆音/延迟抖动。
# --- audio ---
# Audio: PipeWire with ALSA/Pulse bridging (modern Wayland stack).
#
# System layer: the NixOS module configures the audio stack once for the whole
# machine, so it is not tied to a per-user profile. A TTY-only install could
# drop it, but this host always runs a graphical session.
_: {
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
