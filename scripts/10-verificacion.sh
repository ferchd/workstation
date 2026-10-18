#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user
say 'Estado de recursos y servicios (solo lectura)'
printf 'RAM/swap:\n'; free -h
printf 'ZRAM:\n'; zramctl 2>/dev/null || true
printf 'Disco:\n'; df -h / /home 2>/dev/null || true
printf 'Btrfs:\n'; if [[ "$(findmnt -no FSTYPE /)" == 'btrfs' ]]; then btrfs filesystem usage / 2>/dev/null || true; fi
printf 'Firewall:\n'; sudo ufw status verbose 2>/dev/null || true
printf 'Serv. relevantes:\n'; for s in fstrim.timer paccache.timer ufw.service lightdm.service snapper-timeline.timer snapper-cleanup.timer; do printf '%-27s ' "$s"; report_service "$s"; done
printf 'Contenedores:\n'; if command -v podman >/dev/null; then podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null || true; fi
printf 'Carga de recursos:\n'; uptime
printf 'Errores de arranque:\n'; journalctl -b -p err --no-pager -n 15 2>/dev/null || true
warn 'Lee los errores: algunos no son críticos y otros requieren intervención según hardware.'
