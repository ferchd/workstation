#!/usr/bin/env bash
set -Eeuo pipefail
say() { printf '\n\033[1;36m%s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mAVISO: %s\033[0m\n' "$*" >&2; }
die() { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }
require_arch_user() {  # Compatibilidad de los scripts visuales heredados de v3.
  [[ -r /etc/os-release ]] && grep -Eq '^ID="?cachyos"?$' /etc/os-release || die 'Solo CachyOS instalado; no archiso.'
  [[ "$EUID" -ne 0 ]] || die 'Ejecuta como usuario normal, nunca como root.'
  [[ -n "${DISPLAY:-}" && "${XDG_SESSION_TYPE:-x11}" != wayland ]] || die 'Este perfil Xfwm4 necesita una sesión gráfica X11.'
}
