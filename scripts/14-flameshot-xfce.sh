#!/usr/bin/env bash
# Cambia el atajo SOLO en Xfce con confirmación explícita y respaldo recuperable.
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user
[[ "${XDG_CURRENT_DESKTOP:-}" == *XFCE* || "${XDG_CURRENT_DESKTOP:-}" == *Xfce* ]] || die 'Se requiere sesión Xfce.'
command -v xfconf-query >/dev/null || die 'Falta xfconf-query.'
command -v flameshot >/dev/null || die 'Primero instala: python3 ws.py tools desktop --yes'
[[ "${1:-}" == --yes ]] || { echo 'Vista previa: se asignaría Impr Pant a flameshot gui en Xfce.'; echo 'Ejecuta con --yes para aplicar y conservar respaldo.'; exit 0; }
channel='xfce4-keyboard-shortcuts'; prop='/commands/custom/Print'
backup="$HOME/.local/state/workstation/flameshot-keybinding-$(date -u +%Y%m%dT%H%M%SZ)-$$.txt"
mkdir -p "$(dirname "$backup")"
if xfconf-query -c "$channel" -p "$prop" >/dev/null 2>&1; then
  printf 'exists\n%s\n' "$(xfconf-query -c "$channel" -p "$prop")" > "$backup"
  xfconf-query -c "$channel" -p "$prop" -s 'flameshot gui'
else
  printf 'absent\n' > "$backup"
  xfconf-query -c "$channel" -p "$prop" -n -t string -s 'flameshot gui'
fi
chmod 600 "$backup"
echo "Asignado Print → flameshot gui. Respaldo: $backup"
echo 'Revisa en Configuración > Teclado > Atajos de aplicaciones si existe otra asignación conflictiva.'
