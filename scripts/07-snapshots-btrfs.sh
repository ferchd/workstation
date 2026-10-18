#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user
[[ "$(findmnt -no FSTYPE /)" == 'btrfs' ]] || die 'La raíz no es Btrfs: no se instalará Snapper con configuración de raíz.'
say 'Snapper para Btrfs: snapshots limitados por tiempo (no sustituyen backup)'
pac_install snapper btrfs-progs btrfs-assistant
if sudo test -e /etc/snapper/configs/root; then
  say 'Configuración Snapper root ya existe. Se respetará su política actual.'
elif mountpoint -q /.snapshots || sudo test -e /.snapshots; then
  warn 'Ya hay un montaje/ruta /.snapshots. No se modificará para evitar dañar el esquema de subvolúmenes.'
  warn 'Revisa ArchWiki Snapper: archinstall moderno y diseño de @snapshots.'
  exit 0
else
  sudo snapper -c root create-config /
  cfg='/etc/snapper/configs/root'
  sudo cp -a "$cfg" "${cfg}.backup-$(date +%Y%m%d-%H%M%S)"
  for pair in 'TIMELINE_CREATE=yes' 'TIMELINE_LIMIT_HOURLY=0' 'TIMELINE_LIMIT_DAILY=3' 'TIMELINE_LIMIT_WEEKLY=2' 'TIMELINE_LIMIT_MONTHLY=1' 'TIMELINE_LIMIT_YEARLY=0'; do
    key="${pair%%=*}"
    val="${pair#*=}"
    sudo sed -i -E "s@^${key}=.*@${key}=\"${val}\"@" "$cfg"
  done
fi
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
sudo snapper -c root create --description 'Configuración inicial Workstation'
warn 'Solo el subvolumen raíz se captura. /home u otros subvolúmenes NO quedan dentro; el rollback depende del layout de bootloader.'
warn 'En 250GB revisa regularmente el espacio de snapshots con btrfs filesystem usage /.'
