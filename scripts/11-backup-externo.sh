#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user
[[ $# -eq 1 ]] || die 'Uso: ./11-backup-externo.sh /ruta/al/PUNTO_DE_MONTAJE_EXTERNO'
mountpoint -q "$1" || die 'El argumento debe ser un punto de montaje real (preferiblemente un SSD/USB externo).'
[[ -w "$1" ]] || die 'El usuario necesita permisos de escritura en el disco externo.'
say 'Respaldo cifrado de HOME con Restic (contraseña interactiva; no se guarda en scripts)'
pac_install restic
repo="$1/restic-arch-${USER}"
if [[ ! -f "$repo/config" ]]; then
  say 'Inicializando repositorio. Guarda la contraseña de backup de forma independiente y segura.'
  restic -r "$repo" init
fi
say "Respaldando $HOME (se excluyen caches e imágenes de contenedores)"
restic -r "$repo" backup "$HOME" \
  --exclude "$HOME/.cache" \
  --exclude "$HOME/.local/share/containers" \
  --exclude '**/node_modules' \
  --exclude '**/.venv' \
  --exclude '**/target'
restic -r "$repo" snapshots
warn 'No cubre datos de contenedores/BD ni configuración de /etc; exporta y respalda esos datos por separado.'
warn 'Comprueba que el punto de montaje corresponda a un dispositivo físico DIFERENTE del NVMe de sistema.'
