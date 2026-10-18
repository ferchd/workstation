# Perfil Xfce: principios de diseño

- **Mouse first**: mover ventanas desde la barra de título sin teclas; cambiar tamaño desde el borde.
- **Ventanas flotantes como comportamiento normal**: mosaico solo cuando las arrastras a los bordes.
- **Tiling opcional**: `xfwm4` tiene ajuste `tile_on_move=true`. No hay gestores tiling obligatorios.
- **Sin dependencia del AUR** para la interfaz.
- **Autonomía**: preferencias editables en la GUI de Xfce, almacenadas por usuario, copiables a un repositorio privado de dotfiles.
- **Sin gestión destructiva** de panel: añadir Whisker y Docklike con el editor gráfico evita depender de ID de plugins cambiantes.
- **No instalar otro compositor** sobre el de `xfwm4` salvo diagnóstico concreto.

## Comandos de referencia

```bash
xfwm4-settings
xfwm4-tweaks-settings
xfce4-panel --preferences
xfconf-query -c xfwm4 -lv
```

## Para el futuro

Versionar scripts y configuración pública en Git. NUNCA versionar bases KDBX, contraseñas, claves SSH, certificados privados, tokens, archivos `.env` con secretos ni valores concretos de respaldos. Separar `profile-desktop`, `profile-dev`, `profile-privacy`, etc.
