#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user

say 'Xfce/Xfwm4: escritorio ligero con mouse como control principal'
# Paquetes de los repositorios oficiales. No hay ajustes de ventana desde TTY:
# el perfil personalizado se aplica tras iniciar sesión gráfica, con 12-*.sh.
pac_install \
  xorg-server xorg-xinit xorg-xset xorg-xrandr \
  xfce4 xfce4-whiskermenu-plugin xfce4-docklike-plugin \
  xfce4-notifyd xfce4-screensaver xfce4-screenshooter \
  xfce4-taskmanager xfce4-pulseaudio-plugin \
  thunar-archive-plugin file-roller gvfs udisks2 \
  lightdm lightdm-gtk-greeter \
  networkmanager network-manager-applet nm-connection-editor \
  mate-polkit xdg-user-dirs xdg-utils xdg-desktop-portal-gtk \
  materia-gtk-theme orchis-theme papirus-icon-theme inter-font \
  noto-fonts noto-fonts-emoji ttf-dejavu \
  pipewire pipewire-pulse wireplumber pavucontrol

install_root_from_stdin /etc/lightdm/lightdm.conf.d/50-workstation-greeter.conf <<'CONF'
[Seat:*]
greeter-session=lightdm-gtk-greeter
CONF

if systemctl is-enabled --quiet display-manager.service; then
  warn 'Ya existe un gestor de acceso gráfico: no se cambiará automáticamente.'
else
  sudo systemctl enable lightdm.service
  say 'LightDM habilitado para el próximo arranque; no se inicia a mitad de esta sesión.'
fi

if ! systemctl is-active --quiet NetworkManager.service; then
  warn 'NetworkManager no está activo; no se reemplaza automáticamente la red actual.'
fi

say 'Próximo paso: entra a la sesión Xfce desde LightDM y ejecuta:'
printf '  bash scripts/12-personalizar-xfce.sh\n'
warn 'El script no toca particiones, EFI, bootloader, ni borra Awesome o escritorios instalados.'
warn 'Si utilizabas PulseAudio, pacman podría solicitar la sustitución por PipeWire.'
