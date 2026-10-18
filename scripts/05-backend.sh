#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_arch_user
say 'SDKs para backend: .NET, ASP.NET, PHP y Composer'
pac_install dotnet-sdk aspnet-targeting-pack php php-fpm composer
warn 'Arch ofrece la versión .NET de sus repositorios. Para proyectos que requieran fijar versión, revisa global.json y el soporte de SDK paralelo.'
warn 'No se habilitó php-fpm automáticamente: instala/configura un servidor web solo para el proyecto que lo necesite.'
