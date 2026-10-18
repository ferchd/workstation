#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user
say 'Herramientas de desarrollo, terminal y compilación'
pac_install git git-lfs helix ripgrep fd fzf bat jq yq htop btop \
  python python-pipx nodejs npm bun go
say 'Instala SDKs específicos con 05-backend.sh; no se instala AUR ni se ejecutan scripts remotos.'
