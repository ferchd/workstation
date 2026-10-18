#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user
say 'Contenedores rootless y herramientas DevOps'
pac_install podman buildah skopeo fuse-overlayfs passt slirp4netns \
  ansible-core kubectl helm
say 'Verifica luego: podman info --format "{{.Host.Security.Rootless}}"'
warn 'No se habilita Docker daemon, puertos externos ni pertenencia al grupo docker (equivalente a privilegios root).'
warn 'Podman rootless NO es totalmente compatible con Docker/Compose en todos los proyectos.'
