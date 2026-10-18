# Arch Workstation v3 — Minimal, cómoda y orientada a desarrollo

**Objetivo:** Arch x86_64, Intel Core i5-10210U, 24 GiB de RAM y NVMe ~250 GB.
**Diseño:** Xfce + Xfwm4 sobre X11, LightDM, tema minimalista Orchis-Dark-Compact, KeePassXC, Btrfs/Snapper, ZRAM y Podman rootless. **Las ventanas se mueven con el mouse desde la barra de título sin ninguna tecla.**
**Alcance:** configuración **posterior** a la instalación base. No toca particiones, claves de cifrado, cargador de arranque ni EFI.

> ⚠️ No existe un script que haga Arch tan conservadora como Debian Stable. Actualiza todo el sistema de forma coherente; confirma noticias oficiales antes; conserva copias externas y un medio de rescate. El hardware híbrido Nvidia requiere evaluación aparte.

## 0. Antes de instalar Arch: decisiones que importan

1. Copia tus datos y claves de recuperación de Windows/BitLocker. Decide antes si vas a borrar Windows o necesitas arranque dual. No reformatees la partición EFI de Windows si lo conservas.
2. Arranca la ISO oficial de Arch en **UEFI**. Para reducir complejidad, usa `archinstall` y selecciona una instalación **Minimal** (sin entorno gráfico), NetworkManager y usuario normal con `sudo`.
3. En una instalación nueva que **sustituye** Windows, considera GPT/EFI + **LUKS2** (cifrado en reposo) + **Btrfs** con compresión `zstd` y subvolúmenes raíz `@` y hogar `@home`. Reserva espacio suficiente en EFI para los kernels e initramfs y los posibles UKI, especialmente si usarás kernel LTS. No reparticiones por scripts sin confirmar el escenario. **Habilitar LUKS2 y gestionar Secure Boot correctamente se hace durante la instalación**, no se agrega mágicamente después.
4. Si conservas Windows: haz copia de la clave de recuperación de BitLocker, suspende su protección cuando corresponda a modificaciones del arranque, desactiva Inicio rápido de Windows y decide la configuración Secure Boot con cuidado. En UEFI con claves personalizadas, no elimines certificados de Microsoft si necesitas Windows. Los pasos exactos varían por bootloader y firmware.
5. Usa repositorios oficiales estables (no `[testing]`); no agregues AUR ni repositorios de terceros al comienzo. **No emplees `pacman -Sy paquete`**: Arch no admite actualizaciones parciales.

Referencias oficiales: https://wiki.archlinux.org/title/Installation_guide ; https://wiki.archlinux.org/title/Snapper ; https://wiki.archlinux.org/title/System_maintenance ; https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot

## 1. Ejecutar los scripts

Copia el directorio completo al nuevo Arch, entra a su directorio y corre como **usuario normal**, nunca `sudo ./script.sh`. Cada script solicita privilegios solo donde los necesita.

```bash
cd arch-workstation
bash scripts/00-diagnostico.sh
bash scripts/01-base.sh
bash scripts/02-escritorio.sh
# Inicia sesión gráfica Xfce antes de ejecutar el siguiente paso:
bash scripts/12-personalizar-xfce.sh
bash scripts/13-estilo-minimal.sh    # Tema, tipografía, iconos, bordes discretos
# Después de verificar cuál es tu panel principal, p. ej.:
# bash scripts/13-estilo-minimal.sh --panel=1
bash scripts/03-seguridad.sh
bash scripts/04-desarrollo.sh
bash scripts/05-backend.sh       # opcional: PHP/.NET
bash scripts/06-devops.sh        # opcional: Podman, K8s, Ansible
bash scripts/07-snapshots-btrfs.sh # SOLO si / es Btrfs
bash scripts/10-verificacion.sh
```

Para kernel de respaldo: `bash scripts/09-kernel-lts-opcional.sh`. **Este script no edita el bootloader**, así que debes garantizar que existe entrada válida LTS e initramfs/UKI antes de contar con él como alternativa. Para actualizar cada semana o cuando haya avisos de seguridad: `bash scripts/08-actualizar-seguro.sh` (pregunta antes y crea snapshots si existe configuración).

Para respaldar HOME a un medio externo montado, por ejemplo `/run/media/tuusuario/EXTERNO`: `bash scripts/11-backup-externo.sh /run/media/tuusuario/EXTERNO`. Revisa que sea otro disco físico. Las contraseñas de Restic se introducen interactivamente y nunca se dejan en scripts.

### Riesgos evitados expresamente

- **Nunca:** `pacman -Sy` aislado, `-Rdd`, borrados de caché `pacman -Scc`, eliminación masiva de paquetes huérfanos sin revisión, cambios automáticos de arranque/particiones, AUR ejecutado como root, servicios SSH abiertos por defecto.
- **No desactivamos:** mitigaciones Spectre/Meltdown, journald, verificaciones de firmas, ASLR, IPv6, SELinux/AppArmor a ciegas ni servicios indispensables.
- **No se hace:** autologin, contraseña vacía, configuración insegura de sudo, actualización desatendida automática, script `curl | bash`, Docker rootful obligatorio.

## 2. Escritorio personal: interacción como Windows 11, sin exigir teclas

**La opción anterior AwesomeWM queda sustituida por Xfce + Xfwm4.** El paquete no desinstala ningún escritorio existente; permite elegir «Xfce Session» desde LightDM. La elección X11 prioriza madurez del stack en este equipo. X11 no tiene el mismo aislamiento de aplicaciones que Wayland.

### Gestos cotidianos (todos con mouse)

- **Mover:** arrastra la barra de título de una ventana normal. **Sin Super**, Alt ni otro modificador.
- **Cambiar tamaño:** arrastra un borde o esquina de la ventana.
- **Maximizar/restaurar:** doble clic sobre la barra de título.
- **Organizar lado a lado:** arrastra la ventana hacia el borde izquierdo/derecho para ajustarla, sin modo especial ni tecla.
- **Menú Inicio:** Whisker Menu en el panel.
- **Barra de tareas:** Docklike Taskbar, permite agrupar ventanas y fijar aplicaciones.
- **Archivos:** Thunar; preferencias gráficas normales; notificaciones, volumen, red y suspender sesión mediante interfaz.

`02-escritorio.sh` instala todos los componentes; `12-personalizar-xfce.sh` configura comportamientos del gestor de ventanas **desde dentro de una sesión gráfica Xfce**, con respaldos previos y sin reemplazar el panel del usuario. Para asegurar compatibilidad entre versiones, la colocación de Whisker y Docklike se hace mediante Preferencias del panel (menú contextual → Panel → Preferencias → Elementos); el script imprime una guía clara. No fuerza el cambio del gestor de acceso ni de la red si están configurados.

La configuración por usuario se almacena en `~/.config/xfce4/` y se administra con `xfconf-query` o desde Configuración. En adelante mantenla como una colección de perfiles de dotfiles en Git, separando ajustes personales de los datos secretos. El directorio `config/xfce/` resume el enfoque.

Si algún día prefieres transiciones visuales o funciones nativas de tiling más extensas que las de Xfwm4, KDE Plasma es alternativa legítima con más componentes y mayor superficie de configuración, pero Xfce es un mejor punto de partida para tu objetivo minimalista.

## 2.1. Perfil visual minimalista inspirado en la referencia

La intención es una interfaz limpia y **manejable con mouse**, no una imitación de los administradores de ventanas con atajos obligatorios. Base: Xfce + Xfwm4, tema **Orchis-Dark-Compact** (GTK3 y decoración Xfwm4), iconos **Papirus-Dark**, tipografía **Inter**, panel horizontal superior de **32 px**, botones minimizar/maximizar/cerrar visibles y fondos discretos.

**Cómo aplicarlo:** `bash scripts/13-estilo-minimal.sh`. Este paso aplica apariencia sin mover ni eliminar paneles. Para colocar el panel principal arriba, primero identifica su ID con `xfconf-query -c xfce4-panel -lv | grep '/position'`; entonces ejecuta, por ejemplo, `bash scripts/13-estilo-minimal.sh --panel=1`. Este ajuste cambia solamente el panel existente cuyo ID seleccionaste, lo coloca arriba, a ancho completo y 32 px. **No elimina un segundo dock**; hazlo manualmente si no lo deseas. Elige los plugins del panel con clic derecho → Panel → Preferencias → Elementos: Whisker Menu, botones de ventana / Docklike, separador expansible, notificaciones, red, volumen y reloj. Reordénalos con el mouse y evita información de diagnóstico constante que solo produce ruido visual.

El script guarda copias de preferencias XML, listados xfconf y, cuando está disponible, un perfil exportado por `xfce4-panel-profiles` antes de los cambios. Para recuperar el panel desde la copia: `xfce4-panel-profiles load /ruta/al/respaldo/panel-layout.tar.bz2`. Si solo hay XML, restaura después de cerrar sesión y con xfconf inactivo. Para las otras preferencias puedes revertir con la interfaz gráfica o comparar los XML respaldados. Esta recuperación debe comprobarse en tu versión de Xfce antes de asumir que funciona en todos los casos.

**Limitaciones:** temas de GTK no se aplican uniformemente a apps Qt/GTK4 con libadwaita; Xfwm4 tampoco produce esquinas redondeadas universales. No añadimos Picom porque Xfwm4 ya trae un compositor básico. No descargamos fondos ni sobrescribimos el escritorio actual. Todo está en repositorios oficiales; no AUR.

## 3. Contraseñas y secretos

**KeePassXC** almacena contraseñas distintas y largas en una base cifrada KDBX **local**, sin sincronización automática a nube. Solo necesitas recordar una frase maestra robusta para la bóveda y conservar un método de recuperación independiente; LUKS y tu cuenta del sistema pueden necesitar credenciales separadas. No existe seguridad real «sin conocer ni poder recuperar ninguna credencial».

1. Crea una bóveda `Vault.kdbx` con contraseña maestra fuerte. Guarda una copia **externa cifrada** y prueba restaurarla.
2. En Firefox, instala **KeePassXC-Browser** desde el sitio oficial de complementos; luego activa la integración con navegadores dentro de KeePassXC. Confirma manualmente la conexión.
3. Activa el bloqueo automático de KeePassXC por inactividad/suspensión, vaciado periódico del portapapeles, y si te interesa, el soporte de llaves SSH con `ssh-agent` (requiere configurar agente de usuario y su socket).
4. Para una mejora opcional, considera una llave de seguridad física compatible con las funciones de KeePassXC. Mantén copia de recuperación por si se pierde.
5. No guardes tokens en repositorios Git ni en `.env` versionados; no uses `git config --global credential.helper store` para secretos (puede conservarlos en texto claro).

**Opciones alternativas:** Bitwarden ofrece sincronización entre dispositivos, pero su aplicación de escritorio añade recursos al usar tecnología Electron. KeePassXC es deliberadamente local y mínimo en dependencias de servicios.

## 4. Contenedores y desarrollo

- `04-desarrollo.sh`: Helix, Git, ripgrep, fd, fzf, Bun, Go, Python, Node/npm, herramientas CLI.
- `05-backend.sh`: SDK .NET, ASP.NET y PHP/Composer; sin servidores activados automáticamente.
- `06-devops.sh`: Podman sin daemon root obligatorio, Buildah, Skopeo, Ansible, kubectl, Helm.

Para servicios de desarrollo limita los puertos al loopback cuando no necesites acceso por LAN:

```bash
podman run --rm -p 127.0.0.1:8080:80 docker.io/library/nginx:stable
```

**Docker y Podman no son idénticos**: Compose, algunos clientes de Docker Engine y montajes particulares pueden requerir Docker real. En ese caso instálalo explícitamente por proyecto, evalúa Docker rootless, los permisos del socket, las reglas de firewall y las variables de entorno. No agregues al usuario al grupo `docker` por comodidad: equivale a acceso privilegiado en una configuración estándar.

## 5. Snapshots, mantenimiento y ahorro de espacio

`07-snapshots-btrfs.sh` SOLO crea la configuración Snapper si `/` es Btrfs y no hay otra config o un `/.snapshots` previo. Si `archinstall` creó `@.snapshots` montado, el script **se abstiene**: hay que adaptar Snapper al montaje correcto; no borres subvolúmenes existentes automáticamente.

Cuando crea la configuración, limita la retención programada a 0 por hora, 3 diarias, 2 semanales y 1 mensual, y activa timers de Snapper. El espacio consumido es variable porque depende de bloques modificados; revisa `btrfs filesystem usage /`. Los snapshots **no son backups**. No incluyen otros subvolúmenes como `@home` ni garantizan restauración con un clic. El bootloader y configuración de LUKS determinan el proceso de recuperación desde una ISO.

En el NVMe de 250 GB considera separar los datos pesados (contenedores, PostgreSQL y caches de compilación) en subvolúmenes si diseñas el esquema al instalar. No desactives CoW globalmente; en bases de datos evalúa por separado las implicaciones de CoW, consistencia y snapshots. No reserves demasiado espacio para el sistema con particiones rígidas: Btrfs comparte espacio entre subvolúmenes.

`01-base.sh` instala zram-generator, configura Zstd con `min(ram/3, 8192 MiB)` (≈8 GiB con 24 GiB RAM) y limita journal en disco. **ZRAM no significa reservar 8 GiB permanentes de RAM**: ese es el tamaño lógico máximo de swap comprimido. No sustituye un swap apropiado si necesitas hibernación. Se habilita también `fstrim.timer` y la limpieza programada del caché de pacman conservando versiones útiles.

Para un ciclo de mantenimiento: lee https://archlinux.org/news/ → `bash scripts/08-actualizar-seguro.sh` → resuelve `.pacnew` → comprueba servicios y errores → reinicia si cambió kernel/driver/systemd. Evita dejar Arch meses sin actualizar.

## 6. Seguridad y límites

UFW deniega entrada y permite salida; se activa solo desde una sesión local y se niega a cambiar reglas en una sesión SSH. Si ya administras `nftables` o `firewalld`, no lo pisa. **No se abrió puerto 22** ni se habilitó `sshd`. Arch-audit programa avisos de paquetes vulnerables.

Esto **no es una auditoría o hardening total**; quedan tareas manuales: firmware actualizado, Secure Boot firmado si se requiere, verificación de periféricos, backups restaurables, control del navegador, política de suspensión, evaluación del driver NVIDIA híbrido si existe y controles de seguridad del navegador/servicios que uses.

### Enlaces de referencia (oficiales)

- https://wiki.archlinux.org/title/System_maintenance
- https://wiki.archlinux.org/title/Snapper
- https://wiki.archlinux.org/title/Btrfs
- https://wiki.archlinux.org/title/Zram
- https://wiki.archlinux.org/title/Xfce
- https://wiki.archlinux.org/title/KeePass
- https://wiki.archlinux.org/title/Podman
- https://wiki.archlinux.org/title/Uncomplicated_Firewall
- https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot

## Nota de migración desde la primera edición

El ZIP v3 mantiene la migración: reemplaza `scripts/02-escritorio.sh` e introduce `scripts/12-personalizar-xfce.sh`. No vuelvas a ejecutar el instalador Awesome de la edición anterior: las configuraciones de Awesome ya no forman parte del paquete nuevo. Si ya instalaste Awesome, puedes dejarlo mientras pruebas Xfce y elegir sesión en LightDM; retíralo **solo cuando hayas comprobado que Xfce te funciona**.
