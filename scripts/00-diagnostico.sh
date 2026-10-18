#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user
say 'Identificación de hardware y montaje (solo lectura)'
printf 'Equipo: '; hostnamectl --static 2>/dev/null || hostname
printf 'Kernel: '; uname -r
printf 'Memoria:\n'; free -h
printf 'Discos:\n'; lsblk -o NAME,SIZE,FSTYPE,FSVER,MOUNTPOINTS
printf 'Partición raíz:\n'; findmnt -no SOURCE,FSTYPE,OPTIONS /
printf 'Arranque: '; [[ -d /sys/firmware/efi ]] && echo UEFI || echo BIOS/Legacy
printf 'GPU(s):\n'; if command -v lspci >/dev/null; then lspci | grep -Ei 'VGA|3D|Display' || true; else echo 'Instala pciutils para ver la GPU'; fi
printf 'Sistema gráfico actual: %s\n' "${XDG_CURRENT_DESKTOP:-No detectado}"
printf 'Interfaces:\n'; ip -brief link
printf 'Servicio de red: '; systemctl is-active NetworkManager.service 2>/dev/null || true
printf 'Gestor de inicio: '; systemctl is-enabled display-manager.service 2>/dev/null || true
printf 'Secure Boot: '; if command -v bootctl >/dev/null; then bootctl status --no-pager 2>/dev/null | grep -i 'Secure Boot' | head -1 || true; fi
printf 'Espacio libre:\n'; df -h / /home 2>/dev/null || df -h /
say 'Anota si usas Btrfs, si existe otro gestor de inicio y qué GPU tienes antes de ejecutar los demás scripts.'
