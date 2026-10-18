#!/usr/bin/env bash
# Perfil no destructivo, versionable e idempotente de ventanas Xfce.
# SOLO en una sesión gráfica Xfce del usuario normal.
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user

if [[ "${XDG_CURRENT_DESKTOP:-}" != *XFCE* && "${XDG_CURRENT_DESKTOP:-}" != *Xfce* ]]; then
  die 'Inicia sesión gráfica XFCE y ejecuta este script desde su terminal (sin sudo).'
fi
[[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] || die 'No detecto el bus D-Bus de tu sesión gráfica.'
command -v xfconf-query >/dev/null || die 'No se encontró xfconf-query.'

backup="$HOME/.local/share/arch-workstation/backups/xfce/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"
# Copia archivos existentes y vuelca estado para inspección/reversión manual.
for item in xfwm4.xml xfce4-panel.xml xsettings.xml; do
  if [[ -f "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/$item" ]]; then
    cp -a "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/$item" "$backup/"
  fi
done
for channel in xfwm4 xfce4-panel xsettings; do
  xfconf-query -c "$channel" -lv > "$backup/$channel.txt" 2>/dev/null || true
done
say "Respaldo previo de preferencias: $backup"

# Cambia propiedades existentes o las crea, según el tipo. Ni xfwm4 ni Xfce
# se reinician a la fuerza. La mayoría de propiedades se aplican en vivo.
set_property() {
  local channel="$1" prop="$2" type="$3" value="$4"
  if xfconf-query -c "$channel" -p "$prop" >/dev/null 2>&1; then
    xfconf-query -c "$channel" -p "$prop" -s "$value"
  else
    xfconf-query -c "$channel" -p "$prop" -n -t "$type" -s "$value"
  fi
}

# Las ventanas se manipulan directamente con el mouse, por su barra y bordes.
set_property xfwm4 /general/click_to_focus bool true
set_property xfwm4 /general/raise_on_click bool true
set_property xfwm4 /general/double_click_action string maximize
set_property xfwm4 /general/snap_to_border bool true
set_property xfwm4 /general/snap_to_windows bool true
set_property xfwm4 /general/snap_width int 16
set_property xfwm4 /general/tile_on_move bool true
# Al alcanzar un borde, la ventana NO salta al escritorio virtual vecino.
set_property xfwm4 /general/wrap_windows bool false
set_property xfwm4 /general/wrap_workspaces bool false
set_property xfwm4 /general/box_move bool false
set_property xfwm4 /general/box_resize bool false
set_property xfwm4 /general/titleless_maximize bool false
set_property xfwm4 /general/use_compositing bool true

# Tema oficial sobrio; si no está disponible, xfwm4 utilizará su predeterminado.
if [[ -d /usr/share/themes/Materia-dark/gtk-3.0 ]]; then
  set_property xsettings /Net/ThemeName string Materia-dark
fi
if [[ -d /usr/share/icons/Papirus-Dark ]]; then
  set_property xsettings /Net/IconThemeName string Papirus-Dark
fi

cat <<'NEXT'

Perfil aplicado. Ahora personaliza visualmente el panel una sola vez:
  1. Clic derecho en el panel → Panel → Preferencias del panel.
  2. En «Elementos», agrega «Whisker Menu» y «Docklike Taskbar».
  3. Para el estilo minimalista coloca el panel principal arriba.
  4. Si duplicas la lista de ventanas, quita «Botones de ventana».

Podrás arrastrar cualquier ventana normal por su barra de título sin Super,
redimensionar por sus bordes y encajarla contra un borde de la pantalla.
Para el tema compacto ejecuta: bash scripts/13-estilo-minimal.sh
Para ver o editar más opciones abre: xfwm4-settings y xfwm4-tweaks-settings.
El respaldo de preferencias permite comparar ajustes, pero restaura los XML
SOLO después de cerrar la sesión Xfce, para evitar que xfconf los sobrescriba.
NEXT
