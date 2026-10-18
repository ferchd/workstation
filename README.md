# Workstation v4 — CachyOS Personal Edition

> Un perfil adaptativo **conservador** para CachyOS orientado a desarrollo y DevOps. No es una distro nueva, ni un optimizador mágico de FPS o CPU. Conserva las optimizaciones de CachyOS.

## Importante: ya no uses el `01-base.sh` de Arch Workstation v3

Ese script **sobrescribe** `/etc/systemd/zram-generator.conf`, instala microcódigo Intel sin detección y añade otros ajustes que pueden duplicar los de CachyOS. En CachyOS **NO lo ejecutes**. Tampoco ejecutes automáticamente los scripts de kernel, bootloader o Snapper de Arch v3: primero evalúa cómo instaló CachyOS el sistema y qué soluciones ya trae.

**No ejecuta** cambios de kernel, ZRAM, swappiness, governor, sched-ext, initramfs, EFI, particiones, sistema de archivos, firewall o servicios. Los cambios del perfil de compilación ocurren solo en tu HOME y pueden revertirse. No agrega repositorios ni AUR.

## 1. Generar perfil del equipo

Ejecuta desde la sesión instalada de CachyOS y como usuario normal (NO como root ni desde la ISO Live):

```bash
cd cachy-workstation-v4
python3 ws.py plan
python3 ws.py scan
```

`plan` muestra una vista previa sin escribir nada. `scan` genera `~/.local/state/workstation/profile.json` con características y recomendaciones. No incluye nombre de host, IP, MAC ni número de serie; **antes de publicar el JSON, revísalo** porque contiene modelo CPU, GPU, kernel y otras características del equipo.

Detección: `/proc/meminfo`, `os.cpu_count`, almacenamiento y FS de `/`, discos físicos de `lsblk` si está disponible, GPU de `lspci`, VM de `systemd-detect-virt`, baterías y chasis, sesión gráfica, servicio de ZRAM, power-profiles-daemon, tuned y TLP. Todas las herramientas adicionales son opcionales; sin ellas el perfil conserva datos parciales.

**Reglas dinámicas heurísticas (no benchmarks):**

- Perfil **compacto**: RAM <= 8 GiB o <= 2 hilos lógicos.
- Perfil **equilibrado**: RAM < 16 GiB o < 4 hilos.
- Perfil **capaz**: recursos superiores.
- `build_jobs`: mínimo entre hilos menos uno, una estimación de ~2 GiB por trabajo (dejando 2 GiB al SO), y un techo de 4/6/10 para compacta/portátil o VM/escritorio. No sustituye las mediciones de consumo de una compilación real.
- `container_parallel_limit_advisory`: sugerencia basada en CPU, RAM y espacio, no un límite de Podman ni Docker configurado globalmente.
- `journal_limit_mib`: **propuesta** calculada para el tamaño del disco; v4 no la aplica automáticamente porque CachyOS puede tener sus propios límites.

Cada ejecución vuelve a detectar recursos. El perfil no modifica el governor ni persigue el uso de CPU minuto a minuto. En Hyper-V el perfil representa la **VM**, no los recursos reales del host Windows.

## 2. Aplicar perfil de compilación seguro

```bash
python3 ws.py apply
# Alternativamente, recalcular JSON + ajustes de usuario tras cambiar de hardware:
python3 ws.py refresh
```

Genera únicamente:

- `~/.config/workstation/build.env`: `MAKEFLAGS`, `CMAKE_BUILD_PARALLEL_LEVEL`, `CARGO_BUILD_JOBS`.
- `~/.local/bin/ws-build`: ejecuta comandos **con ese límite**, por ejemplo `~/.local/bin/ws-build make` o `~/.local/bin/ws-build cargo build`.

Es intencional: no exportamos variables globales que afecten silenciosamente a todos tus proyectos ni cambiamos el scheduler por sistema. El wrapper aplica límites únicamente al proceso lanzado desde él; algunas herramientas pueden ignorar dichas variables.

Antes de sobrescribir una versión anterior se crea una copia en `~/.local/state/workstation/backups/`. Para deshacer el último cambio:

```bash
python3 ws.py rollback         # vista previa
python3 ws.py rollback --yes   # restaura solo si nadie editó después el archivo
```

## 3. Instalar tus herramientas por módulos (opcional)

El modo normal es **solo previsualización**. Se usa `sudo pacman -Syu --needed` exclusivamente con `--yes` desde un usuario normal.

| Módulo | Herramientas | Activación |
|---|---|---|
| `core` | Git, Git LFS, Helix, ripgrep, fd, fzf, bat, jq/yq, btop, htop, Lazygit, SQLite, Python/pipx, Go, Bun, Node/npm | `python3 ws.py tools core --yes` |
| `desktop` | Flameshot | `python3 ws.py tools desktop --yes` |
| `editor` | Code - OSS (`code`), basado en Electron; relativamente pesado | `python3 ws.py tools editor --yes` |
| `backend` | .NET SDK, ASP.NET targeting, PHP, Composer | `python3 ws.py tools backend --yes` |
| `devops` | Podman, Buildah, Skopeo, Ansible Core, kubectl, Helm | `python3 ws.py tools devops --yes` |
| `passwords` | KeePassXC | `python3 ws.py tools passwords --yes` |
| `xfce-style` | Orchis, Papirus, Inter, Whisker Menu, Docklike | `python3 ws.py tools xfce-style --yes` |

Solo paquetes de repositorios visibles para Pacman; **nada de AUR**, scripts remotos, servicios activados, cambios de grupo Docker ni apertura de puertos. Un `pacman -Syu` puede actualizar kernels y paquetes como parte de la actualización completa normal; revisa la transacción antes de confirmarla y ten respaldo. No instala Docker rootful. Las herramientas grandes son opcionales para ahorrar SSD.

Para ver el contenido sin instalar:

```bash
python3 ws.py tools core
```

## 4. Personalidad minimalista (solo si usas Xfce + Xfwm4/X11)

No se cambia tu entorno gráfico actual; CachyOS puede venir con KDE Plasma, GNOME u otro escritorio. **No sustituyas KDE por Xfce sin decidirlo tú.** Si ya utilizas una sesión Xfce sobre X11:

```bash
python3 ws.py tools xfce-style --yes
bash scripts/12-personalizar-xfce.sh
bash scripts/13-estilo-minimal.sh
```

Ventanas movibles con el **mouse directamente desde la barra de título**; decoraciones ligeras, tema Orchis oscuro compacto, iconos Papirus, letra Inter, botones visibles y panel configurable. Para mover un panel existente arriba, indica su ID conscientemente con `bash scripts/13-estilo-minimal.sh --panel=ID`. Respaldos en `~/.local/share/arch-workstation/backups/`.

Flameshot en Xfce/X11:

```bash
python3 ws.py tools desktop --yes
bash scripts/14-flameshot-xfce.sh           # vista previa
bash scripts/14-flameshot-xfce.sh --yes     # vincula tecla Impr Pant
```

Los atajos de Xfce pueden variar según versión o preconfiguración; revisa si hay un atajo duplicado. En **Wayland (p. ej. KDE)** no se aplica este script: las capturas dependen del compositor, portal y permisos de captura y requieren configuración específica. X11 permite más interoperabilidad entre ventanas, pero también ofrece menos aislamiento entre aplicaciones.

## 5. Seguridad, mantenimiento y confiabilidad

- **Credenciales:** KeePassXC (crear la bóveda, frase maestra, copias cifradas e integración con navegador son acciones manuales). No desactives el bloqueo de sesión ni guardes contraseñas en el repositorio.
- **Snapshots:** comprueba la estructura de subvolúmenes y si ya existe Snapper/Timeshift antes de crear otro sistema de snapshots. Las copias Btrfs NO reemplazan un backup externo.
- **Actualizaciones:** repositorios de CachyOS, transacciones completas Pacman; revisar noticias de CachyOS/Arch y archivos `.pacnew`. CachyOS tiene soluciones propias de actualización, incluido el mecanismo offline.
- **Energía:** no mezcles TLP, tuned y power-profiles-daemon sin investigar incompatibilidades. Si existen varios activos, el perfil genera un aviso; **no los deshabilita**.
- **ZRAM:** CachyOS ya suele proporcionar ZRAM vía `cachyos-settings`; no dupliques configuraciones de swap.
- **Kernel:** el de CachyOS está ajustado para rendimiento; no lo sustituyas sin un motivo real. Para respaldo estable, CachyOS distribuye un kernel LTS propio, sujeto a configuración de arranque.

## 6. Validaciones / límites

- Código Python compatible con 3.10+; no requiere pip ni dependencias externas.
- Pruebas locales de políticas: `python3 -m unittest discover -s tests -v`.
- Validación sintáctica shell: `bash -n scripts/*.sh`.
- **No se ha probado aplicando cambios sobre tu Hyper-V ni sobre una instalación real de CachyOS**. Siempre revisa el `plan` y prueba antes de usarlo en el PC físico.
- La v4 es un nuevo núcleo de configuración; **no ejecuta ni reemplaza automáticamente todo v3**. Los scripts visuales Xfce 12/13 se conservaron explícitamente, ahora protegidos para su uso en CachyOS.

Referencias:
- https://wiki.cachyos.org/es/features/cachyos_settings/
- https://wiki.cachyos.org/es/features/kernel/
- https://wiki.cachyos.org/es/configuration/general_system_tweaks/
- https://wiki.cachyos.org/es/configuration/post_install_setup/
