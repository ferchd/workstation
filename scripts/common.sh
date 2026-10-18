#!/usr/bin/env bash
# Utilidades compartidas. Los scripts deben ejecutarse como usuario normal.
set -Eeuo pipefail

say()  { printf '\n\033[1;36m%s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mAVISO: %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

require_arch_user() {
  [[ -r /etc/arch-release ]] || die 'Esto se diseñó para Arch Linux.'
  [[ "$EUID" -ne 0 ]] || die 'No ejecutes scripts con sudo: usan sudo solo donde es necesario.'
  command -v sudo >/dev/null || die 'Debes tener sudo configurado para tu usuario.'
  command -v pacman >/dev/null || die 'No se encontró pacman.'
}

# Nunca sincronizar DB de pacman sin realizar una actualización completa.
pac_install() {
  say "Actualización completa + instalación: $*"
  sudo pacman -Syu --needed "$@"
}

# Crea/actualiza SOLO archivos propiedad de este kit; respalda si existían.
install_root_from_stdin() {
  local dest="$1" tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  if ! sudo test -f "$dest" || ! sudo cmp -s "$tmp" "$dest"; then
    if sudo test -e "$dest"; then
      sudo cp -a "$dest" "${dest}.backup-$(date +%Y%m%d-%H%M%S)"
    fi
    sudo install -D -m 0644 "$tmp" "$dest"
    say "Archivo instalado: $dest"
  else
    say "Sin cambios: $dest"
  fi
  rm -f "$tmp"
}

report_service() { systemctl is-enabled "$1" 2>/dev/null || true; }
