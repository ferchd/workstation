#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user
say 'Base ligera: utilidades, mantenimiento, microcódigo y RAM comprimida'
pac_install base-devel git curl wget rsync unzip 7zip openssh sudo man-db man-pages \
  pciutils usbutils smartmontools nvme-cli pacman-contrib \
  intel-ucode zram-generator

install_root_from_stdin /etc/systemd/zram-generator.conf <<'CONF'
[zram0]
zram-size = min(ram / 3, 8192)
compression-algorithm = zstd
swap-priority = 100
CONF

install_root_from_stdin /etc/systemd/journald.conf.d/20-workstation.conf <<'CONF'
[Journal]
SystemMaxUse=200M
RuntimeMaxUse=80M
CONF

sudo systemctl daemon-reload
sudo systemctl try-restart systemd-journald.service || true
sudo systemctl enable --now paccache.timer
if findmnt -nr -o SOURCE / | grep -q .; then
  sudo systemctl enable --now fstrim.timer
fi
warn 'ZRAM quedará disponible tras reiniciar (o al iniciar la unidad generada manualmente).'
warn 'No se modificó fstab, el bootloader, la tabla de particiones ni tu configuración gráfica.'
