#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user
say 'Actualización consciente: no existe garantía automática de estabilidad'
echo 'Antes de actualizar, revisa https://archlinux.org/news/ (avisos de intervención manual).'
read -r -p '¿Revisaste las noticias oficiales y quieres actualizar ahora? [s/N] ' answer
[[ "$answer" =~ ^[sS]$ ]] || { echo 'Cancelado sin cambios.'; exit 0; }

if [[ "$(findmnt -no FSTYPE /)" == 'btrfs' ]] && sudo test -f /etc/snapper/configs/root; then
  sudo snapper -c root create --description "PRE pacman -Syu $(date +%F)"
fi
sudo pacman -Syu
if [[ "$(findmnt -no FSTYPE /)" == 'btrfs' ]] && sudo test -f /etc/snapper/configs/root; then
  sudo snapper -c root create --description "POST pacman -Syu $(date +%F)"
fi
say 'Revisión manual: .pacnew, avisos y servicios importantes'
if command -v pacdiff >/dev/null; then
  echo 'Para resolver configuraciones .pacnew utiliza: sudo pacdiff'
fi
sudo find /etc -type f \( -name '*.pacnew' -o -name '*.pacsave' \) -print
if command -v arch-audit >/dev/null; then arch-audit || true; fi
if command -v paccache >/dev/null; then sudo paccache -rk3; fi
warn 'Si actualizaste kernel, controladores o systemd, reinicia tras guardar tu trabajo.'
