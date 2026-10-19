#!/usr/bin/env python3
"""Perfil Xfce Workstation: previsualización, aplicar y restaurar con respaldos.
Sin sudo, sin AUR, sin tocar kernel ni configuraciones de CachyOS.
"""
from __future__ import annotations
import argparse
import datetime
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

THEME = 'Orchis-Dark-Compact'
ICON_THEME = 'Papirus-Dark'
FONT = 'Inter 10'
STATE = Path.home()/'.local/state/workstation/appearance'
WALLPAPER = Path.home()/'.local/share/backgrounds/workstation-sage.png'
ASSET = Path(__file__).resolve().parents[1]/'assets/workstation-sage.png'


def command(args: list[str], *, required: bool = True) -> str:
    p = subprocess.run(args, capture_output=True, text=True)
    if required and p.returncode:
        raise RuntimeError(f'Error ({p.returncode}) al ejecutar {args[0]}: {p.stderr.strip()}')
    return p.stdout.strip() if p.returncode == 0 else ''


def xfget(channel: str, prop: str) -> str | None:
    p = subprocess.run(['xfconf-query','-c',channel,'-p',prop], capture_output=True, text=True)
    return p.stdout.strip() if p.returncode == 0 else None


def xfset(channel: str, prop: str, kind: str, value: object, remembered: list[dict]):
    before=xfget(channel,prop)
    remembered.append({'channel':channel,'property':prop,'type':kind,'value':before,'existed':before is not None})
    args=['xfconf-query','-c',channel,'-p',prop]
    if before is None: args.extend(['-n','-t',kind])
    args.extend(['-s',str(value).lower() if isinstance(value,bool) else str(value)])
    command(args)


def arrayset(prop: str, values: list[int]):
    if not values: raise RuntimeError(f'No se permite lista vacía para {prop}')
    args=['xfconf-query','-c','xfce4-panel','-p',prop,'-a']
    if xfget('xfce4-panel',prop) is None: args.append('-n')
    for v in values:
        args.extend(['-t','int','-s',str(v)])
    command(args)


def ensure_env():
    if os.geteuid()==0: raise RuntimeError('Ejecuta desde tu usuario normal, sin sudo.')
    if 'XFCE' not in os.environ.get('XDG_CURRENT_DESKTOP','').upper():
        raise RuntimeError('Inicia sesión en Xfce antes de aplicar este estilo.')
    if os.environ.get('XDG_SESSION_TYPE','').lower()=='wayland':
        raise RuntimeError('Este perfil está diseñado para Xfce + X11; Wayland no está validado.')
    if not os.environ.get('DBUS_SESSION_BUS_ADDRESS'):
        raise RuntimeError('No se encontró D-Bus de tu sesión Xfce.')
    for executable in ['xfconf-query','xfce4-panel','xfce4-panel-profiles']:
        if not shutil.which(executable):
            raise RuntimeError(f'Falta {executable}. Instala el módulo xfce-style de Workstation.')
    if not (Path('/usr/share/themes')/THEME/'xfwm4').exists():
        raise RuntimeError('Falta orchis-theme o el tema para Xfwm4: '+THEME)
    if not (Path('/usr/share/icons')/ICON_THEME).exists():
        raise RuntimeError('Falta papirus-icon-theme.')
    for plugin in ['whiskermenu','docklike']:
        descriptor=Path('/usr/share/xfce4/panel/plugins')/(plugin+'.desktop')
        module=Path('/usr/lib/xfce4/panel/plugins')/('lib'+plugin+'.so')
        if not descriptor.exists() and not module.exists():
            raise RuntimeError(f'Falta plugin del panel: {plugin}. Instala el módulo xfce-style con ws.py.')
    if not ASSET.is_file():
        raise RuntimeError('No se encuentra el wallpaper incluido en el proyecto: '+str(ASSET))


def panel_current():
    raw=xfget('xfce4-panel','/panels')
    ids=[int(s) for s in (raw or '').splitlines() if re.fullmatch(r'\d+',s.strip())]
    if not ids:
        raise RuntimeError('No se detectaron paneles existentes: el script no creará uno a ciegas.')
    # Respect the panel that currently lives at the top where possible.
    main=next((i for i in ids if (xfget('xfce4-panel',f'/panels/panel-{i}/position') or '').startswith('p=6;')),ids[0])
    return ids,main


def known_plugins():
    data=command(['xfconf-query','-c','xfce4-panel','-lv'])
    mapping={}
    for line in data.splitlines():
        m=re.match(r'^/plugins/plugin-(\d+)\s+(\S+)\s*$',line)
        if m: mapping.setdefault(m.group(2),[]).append(int(m.group(1)))
    return mapping


def backup() -> Path:
    stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    target=STATE/stamp
    target.mkdir(parents=True, exist_ok=False)
    target.chmod(0o700)
    print('Guardando panel original...', flush=True)
    command(['xfce4-panel-profiles','save',str(target/'panel.tar.bz2')])
    return target


def apply():
    ensure_env()
    existing,main=panel_current()
    print(f'Panel principal: {main} | Paneles actuales: {existing}')
    directory=backup()
    changes=[]
    try:
        # Guardar el archivo existente antes de cambiarlo, para restaurar en el futuro.
        directory.joinpath('wallpaper-was-present.txt').write_text('yes' if WALLPAPER.exists() else 'no')
        if WALLPAPER.exists():
            shutil.copy2(WALLPAPER,directory/'wallpaper-original.png')
        WALLPAPER.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(ASSET,WALLPAPER)

        xfset('xsettings','/Net/ThemeName','string',THEME,changes)
        xfset('xsettings','/Net/IconThemeName','string',ICON_THEME,changes)
        xfset('xsettings','/Gtk/FontName','string',FONT,changes)
        xfset('xsettings','/Net/PreferDarkTheme','bool',True,changes)
        xfset('xfwm4','/general/theme','string',THEME,changes)
        xfset('xfwm4','/general/title_font','string','Inter Medium 10',changes)
        xfset('xfwm4','/general/button_layout','string','|HMC',changes)
        xfset('xfwm4','/general/click_to_focus','bool',True,changes)
        xfset('xfwm4','/general/raise_on_click','bool',True,changes)
        xfset('xfwm4','/general/tile_on_move','bool',True,changes)
        xfset('xfwm4','/general/wrap_windows','bool',False,changes)
        xfset('xfwm4','/general/wrap_workspaces','bool',False,changes)
        xfset('xfwm4','/general/double_click_action','string','maximize',changes)
        xfset('xfwm4','/general/titleless_maximize','bool',False,changes)
        # Sin iconos de escritorio gigantes: acceso mediante Whisker y Thunar.
        xfset('xfce4-desktop','/desktop-icons/style','int',0,changes)
        all_desktop_properties=command(['xfconf-query','-c','xfce4-desktop','-lv'],required=False)
        wallpaper_keys=[]
        for line in all_desktop_properties.splitlines():
            m=re.match(r'^(/backdrop/\S+/last-image)\s+',line)
            if m: wallpaper_keys.append(m.group(1))
        if not wallpaper_keys:
            print('AVISO: no hay ruta de fondo conocida en xfconf; selección manual necesaria desde Escritorio.')
        for key in sorted(set(wallpaper_keys)):
            xfset('xfce4-desktop',key,'string',str(WALLPAPER),changes)
            style=key.rsplit('/',1)[0]+'/image-style'
            xfset('xfce4-desktop',style,'int',5,changes)  # Zoomed, fill display.

        # Panel: prefer existing plugins so systray and clock keep their preferences.
        plugins=known_plugins()
        occupied={i for vals in plugins.values() for i in vals}
        next_id=max(occupied|{0})+1
        def widget(name):
            nonlocal next_id
            if plugins.get(name): return plugins[name][0]
            i=next_id; next_id+=1
            # Add the plugin mapping before the panel's plugin-ids list references it.
            command(['xfconf-query','-c','xfce4-panel','-p',f'/plugins/plugin-{i}',
                     '-n','-t','string','-s',name])
            plugins[name]=[i]
            return i

        items=['whiskermenu','pager','docklike','separator']
        items.append('systray' if not plugins.get('statusnotifier') else 'statusnotifier')
        items.extend(['pulseaudio','clock','actions'])
        panel_ids=[widget(n) for n in items]
        # an expanding separator pushes widgets to the right
        separator_id=panel_ids[items.index('separator')]
        xfset('xfce4-panel',f'/plugins/plugin-{separator_id}/expand','bool',True,changes)
        wm_id=panel_ids[0]
        xfset('xfce4-panel',f'/plugins/plugin-{wm_id}/show-button-title','bool',False,changes)
        panelpath=f'/panels/panel-{main}'
        xfset('xfce4-panel',panelpath+'/position','string','p=6;x=0;y=0',changes)
        xfset('xfce4-panel',panelpath+'/length','uint',100,changes)
        xfset('xfce4-panel',panelpath+'/length-adjust','bool',False,changes)
        xfset('xfce4-panel',panelpath+'/size','uint',34,changes)
        xfset('xfce4-panel',panelpath+'/nrows','uint',1,changes)
        xfset('xfce4-panel',panelpath+'/autohide-behavior','uint',0,changes)
        xfset('xfce4-panel',panelpath+'/dark-mode','bool',True,changes)
        xfset('xfce4-panel',panelpath+'/background-style','uint',0,changes)
        xfset('xfce4-panel',panelpath+'/position-locked','bool',True,changes)
        # Panel content is intentionally reconstructed, not merely themed.
        arrayset(panelpath+'/plugin-ids',panel_ids)
        if len(existing)>1:
            arrayset('/panels',[main])
            print('Se ocultaron los paneles adicionales (se recuperan con --restore).')
        (directory/'changes.json').write_text(json.dumps(changes,ensure_ascii=False,indent=2))
        (directory/'metadata.json').write_text(json.dumps({'main_panel':main,'wallpaper_keys':wallpaper_keys,'old_panels':existing},indent=2))
        command(['xfce4-panel','-r'],required=False)
        print('\nApariencia aplicada: tema, iconos, barra, widgets, fondo y ventanas.')
        print('Para recuperar el escritorio anterior: python3 scripts/15-escritorio-completo.py --restore')
        print('Respaldo:',directory)
    except Exception:
        (directory/'changes.json').write_text(json.dumps(changes,ensure_ascii=False,indent=2))
        print('\nLa instalación se interrumpió. Ejecuta --restore para recuperar preferencias.',file=sys.stderr)
        raise


def restore():
    ensure_env()
    backups=sorted((p for p in STATE.glob('*') if p.is_dir()),reverse=True)
    if not backups: raise RuntimeError('No hay respaldos de este script.')
    target=backups[0]
    changes_path=target/'changes.json'
    if not changes_path.exists(): raise RuntimeError('Respaldo incompleto, revisa: '+str(target))
    print('Restaurando:',target)
    # Panel profile is authoritative for all panel properties (including arrays).
    panel_archive=target/'panel.tar.bz2'
    if not panel_archive.exists(): raise RuntimeError('Falta respaldo del panel.')
    command(['xfce4-panel-profiles','load',str(panel_archive)])
    props=json.loads(changes_path.read_text())
    for ch in reversed(props):
        if ch['channel']=='xfce4-panel': continue
        cmd=['xfconf-query','-c',ch['channel'],'-p',ch['property']]
        if ch['existed']:
            if xfget(ch['channel'],ch['property']) is None: cmd.extend(['-n','-t',ch['type']])
            cmd.extend(['-s',ch['value']]); command(cmd)
        else:
            command(cmd+['-r'],required=False)
    existed=(target/'wallpaper-was-present.txt').read_text()=='yes'
    saved=target/'wallpaper-original.png'
    if existed and saved.exists(): shutil.copy2(saved,WALLPAPER)
    elif not existed and WALLPAPER.exists(): WALLPAPER.unlink()
    command(['xfce4-panel','-r'],required=False)
    (target/'restored.txt').write_text('Restaurado '+datetime.datetime.now(datetime.timezone.utc).isoformat())
    print('Diseño anterior restaurado. Cierra e inicia sesión si algún widget no se actualiza.')


def main():
    parser=argparse.ArgumentParser(description='Workstation: personalización total Xfce/X11')
    actions=parser.add_mutually_exclusive_group(required=True)
    actions.add_argument('--plan',action='store_true',help='No cambia nada; muestra acciones')
    actions.add_argument('--apply',action='store_true',help='Aplica y respalda la apariencia completa')
    actions.add_argument('--restore',action='store_true',help='Recupera el último respaldo')
    args=parser.parse_args()
    if args.plan:
        print('Perfil Sage: Orchis-Dark-Compact + Papirus-Dark + Inter; fondo geométrico;')
        print('panel único superior de 34px con Whisker/pager/docklike/reloj; ocultar iconos')
        print('del escritorio; Xfwm4 con título y controles. Se genera respaldo reversible.')
        print('Instala dependencias: python3 ws.py tools xfce-style --yes')
        print('Ejecuta desde Xfce/X11 con tu usuario normal:')
        print('  python3 scripts/15-escritorio-completo.py --apply')
        return
    try:
        if args.apply: apply()
        elif args.restore: restore()
    except (RuntimeError,OSError,subprocess.CalledProcessError) as e:
        print('ERROR:',e,file=sys.stderr)
        sys.exit(1)

if __name__=='__main__': main()
