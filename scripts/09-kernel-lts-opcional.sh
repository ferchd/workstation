#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user
say 'Kernel LTS como ruta de rescate, sin modificar el cargador de arranque'
echo 'Este paso instala linux-lts pero NO crea entradas en GRUB/systemd-boot/UKI.'
echo 'Tu configuración de arranque puede necesitar una entrada LTS adicional.'
read -r -p '¿Continuar instalando Linux LTS y sus headers? [s/N] ' answer
[[ "$answer" =~ ^[sS]$ ]] || exit 0
pac_install linux-lts linux-lts-headers
warn 'NO reinicies hasta confirmar que el initramfs/UKI y el bootloader de LTS están correctamente configurados.'
