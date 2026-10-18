#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user
say 'Gestor cifrado de contraseñas, navegador, auditoría y cortafuegos'
pac_install keepassxc firefox ufw arch-audit

# Evitar interferencia silenciosa con gestores de firewall preexistentes.
if systemctl is-active --quiet firewalld.service || systemctl is-active --quiet nftables.service; then
  die 'Hay otro firewall activo. Configura uno solo manualmente; UFW no fue habilitado.'
fi
if [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_TTY:-}" ]]; then
  die 'Detectada sesión SSH. No se aplicarán reglas que puedan cortar la conexión.'
fi
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw --force enable
sudo systemctl enable --now ufw.service
sudo systemctl enable --now arch-audit.timer
say 'Cortafuegos activado; no se abrió ningún puerto entrante ni se habilitó sshd.'
warn 'KeePassXC necesita crear manualmente una bóveda KDBX, una frase maestra y su copia de seguridad fuera del equipo.'
warn 'Si necesitas permitir SSH remoto, primero define una regla restringida desde acceso local.'
warn 'Las reglas UFW no garantizan proteger puertos que Docker rootful publique directamente.'
