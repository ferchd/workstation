#!/usr/bin/env bash
# Perfil estético ligero inspirado en un escritorio minimalista (un panel superior).
# Se ejecuta como usuario normal dentro de Xfce; no elimina paneles ni widgets.
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user

if [[ "${XDG_CURRENT_DESKTOP:-}" != *XFCE* && "${XDG_CURRENT_DESKTOP:-}" != *Xfce* ]]; then
  die 'Inicia una sesión Xfce y ejecuta como usuario normal (sin sudo).'
fi
[[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] || die 'Necesitas D-Bus de la sesión Xfce.'
command -v xfconf-query >/dev/null || die 'Falta xfconf-query; instala xfconf.'

# Para no asumir qué panel es el principal, mover el panel es opcional y explícito.
panel_id=''
case "${1:-}" in
  '') ;;
  --panel=*) panel_id="${1#--panel=}" ;;
  -h|--help)
    echo 'Uso: bash scripts/13-estilo-minimal.sh [--panel=N]'
    echo 'Sin --panel solo aplica tema, tipografía e iconos.'
    echo 'Con --panel=N coloca ESE panel existente arriba, ancho 100%, alto 32 px.'
    exit 0 ;;
  *) die 'Argumento inválido; usa --panel=N o --help.' ;;
esac
[[ -z "$panel_id" || "$panel_id" =~ ^[0-9]+$ ]] || die 'ID de panel inválido.'
(( $# <= 1 )) || die 'Solo se admite un argumento.'

backup="$HOME/.local/share/arch-workstation/backups/minimal/$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$backup"
for f in xsettings.xml xfwm4.xml xfce4-panel.xml; do
  target="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/$f"
  [[ ! -f "$target" ]] || cp -a -- "$target" "$backup/$f"
done
for channel in xsettings xfwm4 xfce4-panel; do
  xfconf-query -c "$channel" -lv > "$backup/${channel}.txt" 2>/dev/null || true
done
if command -v xfce4-panel-profiles >/dev/null; then
  xfce4-panel-profiles save "$backup/panel-layout.tar.bz2" \
    || warn 'No se pudo exportar el perfil completo del panel; quedan respaldos XML y TXT.'
fi
say "Respaldo en: $backup"

set_prop() {
  local ch="$1" prop="$2" type="$3" value="$4"
  if xfconf-query -c "$ch" -p "$prop" >/dev/null 2>&1; then
    xfconf-query -c "$ch" -p "$prop" -s "$value"
  else
    xfconf-query -c "$ch" -p "$prop" -n -t "$type" -s "$value"
  fi
}

# Arch extra/orchis-theme incluye tanto gtk-3.0 como xfwm4 para este nombre.
theme='Orchis-Dark-Compact'
if [[ -d "/usr/share/themes/$theme/gtk-3.0" && -d "/usr/share/themes/$theme/xfwm4" ]]; then
  set_prop xsettings /Net/ThemeName string "$theme"
  set_prop xfwm4 /general/theme string "$theme"
else
  warn "Tema $theme no encontrado: instala orchis-theme y vuelve a ejecutar."
fi

if [[ -d /usr/share/icons/Papirus-Dark ]]; then
  set_prop xsettings /Net/IconThemeName string Papirus-Dark
fi
if command -v fc-match >/dev/null && fc-match -f '%{family}\n' 'Inter' | head -n 1 | grep -qi '^Inter'; then
  set_prop xsettings /Gtk/FontName string 'Inter 10'
  set_prop xfwm4 /general/title_font string 'Inter Medium 10'
fi
set_prop xsettings /Net/PreferDarkTheme bool true
set_prop xsettings /Xft/Antialias int 1
set_prop xsettings /Xft/HintStyle string hintslight

# Mantener ventanas totalmente controlables con mouse; nunca ocultar la barra.
set_prop xfwm4 /general/click_to_focus bool true
set_prop xfwm4 /general/raise_on_click bool true
set_prop xfwm4 /general/double_click_action string maximize
set_prop xfwm4 /general/titleless_maximize bool false
set_prop xfwm4 /general/tile_on_move bool true
set_prop xfwm4 /general/wrap_windows bool false
set_prop xfwm4 /general/wrap_workspaces bool false
set_prop xfwm4 /general/use_compositing bool true
set_prop xfwm4 /general/show_dock_shadow bool false
set_prop xfwm4 /general/show_frame_shadow bool true
# Botones: minimizar, maximizar, cerrar a la derecha (barra de título arrastrable).
set_prop xfwm4 /general/button_layout string '|HMC'

if [[ -n "$panel_id" ]]; then
  base="/panels/panel-$panel_id"
  if ! xfconf-query -c xfce4-panel -p "$base/position" >/dev/null 2>&1; then
    die "El panel $panel_id no existe. Consulta los IDs con: xfconf-query -c xfce4-panel -lv | grep '/position'"
  fi
  set_prop xfce4-panel "$base/position" string 'p=6;x=0;y=0'
  set_prop xfce4-panel "$base/length" uint 100
  set_prop xfce4-panel "$base/size" uint 32
  set_prop xfce4-panel "$base/nrows" uint 1
  set_prop xfce4-panel "$base/position-locked" bool true
  set_prop xfce4-panel "$base/dark-mode" bool true
  say "Panel $panel_id ajustado arriba, ancho completo, altura 32 px."
else
  say 'No se movieron paneles. Puedes seleccionar uno con --panel=N.'
fi

cat <<'INSTRUCCIONES'

Estilo minimalista aplicado.
- Configura en el panel superior: Whisker | aplicaciones | espacio | red/volumen | reloj.
- Si aparece un dock inferior que no quieres, desactívalo desde Preferencias del panel
  después de confirmar qué panel es. Este script no elimina paneles.
- Mantén una barra de título discreta para arrastrar ventanas con el mouse.
- Selecciona un fondo suave desde Configuración > Escritorio; no lo sobrescribimos.
- Para restaurar ajustes: consulta el respaldo impreso más arriba y el README.
- Algunas apps GTK4/libadwaita o Qt pueden no obedecer exactamente el tema GTK3.

INSTRUCCIONES
