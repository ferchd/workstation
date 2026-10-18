"""Profile computation uses the standard library; no root or network needed."""
from __future__ import annotations

import datetime as dt
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
from typing import Any


def cmd(*args: str, timeout: float = 3) -> str:
    try:
        p = subprocess.run(args, capture_output=True, text=True, timeout=timeout, check=False)
        return p.stdout.strip() if p.returncode == 0 else ""
    except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return ""


def read(path: str, default: str = "") -> str:
    try:
        return Path(path).read_text(encoding="utf-8", errors="replace").strip()
    except (OSError, UnicodeError):
        return default


def os_release() -> dict[str, str]:
    pairs = {}
    for line in read("/etc/os-release").splitlines():
        if "=" in line and not line.startswith("#"):
            key, value = line.split("=", 1)
            pairs[key] = value.strip().strip('"').strip("'")
    return pairs


def mem_total_mb() -> int:
    for line in read("/proc/meminfo").splitlines():
        if line.startswith("MemTotal:"):
            return int(line.split()[1]) // 1024
    return 0


def storage() -> dict[str, Any]:
    try:
        du = shutil.disk_usage("/")
        root = {"size_gib": round(du.total / 2**30, 1), "free_gib": round(du.free / 2**30, 1), "free_pct": round(100 * du.free / max(du.total, 1), 1)}
    except OSError:
        root = {"size_gib": 0, "free_gib": 0, "free_pct": 0}
    raw = cmd("lsblk", "-J", "-b", "-o", "NAME,TYPE,SIZE,ROTA,TRAN")
    disks = []
    if raw:
        try:
            for block in json.loads(raw).get("blockdevices", []):
                if block.get("type") == "disk":
                    disks.append({"name": block.get("name"), "gib": round(int(block.get("size") or 0) / 2**30, 1),
                                  "rotational": bool(int(block.get("rota") or 0)), "transport": block.get("tran")})
        except (ValueError, TypeError, KeyError):
            pass
    return {"root": root, "physical_disks": disks, "root_fs": cmd("findmnt", "-n", "-o", "FSTYPE", "/") or "unknown"}


def detect() -> dict[str, Any]:
    osr = os_release()
    batteries = [p for p in Path("/sys/class/power_supply").glob("*") if read(str(p / "type")).lower() == "battery"]
    # Hyper-V guests may expose synthetic battery devices; virtualization takes precedence.
    vm = cmd("systemd-detect-virt", "--vm") or "none"
    chassis = read("/sys/class/dmi/id/chassis_type")
    laptop = bool(batteries) or chassis in {"8", "9", "10", "11", "14", "30", "31", "32"}
    logical = os.cpu_count() or 1
    cpu_name = ""
    for line in read("/proc/cpuinfo").splitlines():
        if line.lower().startswith("model name"):
            cpu_name = line.partition(":")[2].strip()
            break
    swap = cmd("swapon", "--noheadings", "--show=NAME")
    active_zram = any("zram" in line for line in swap.splitlines())
    configured_zram = any(Path(p).exists() for p in (
        "/etc/systemd/zram-generator.conf", "/usr/lib/systemd/zram-generator.conf", "/usr/local/lib/systemd/zram-generator.conf"
    )) or bool(list(Path("/etc/systemd/zram-generator.conf.d").glob("*.conf")))
    desktop = os.environ.get("XDG_CURRENT_DESKTOP", "") or os.environ.get("DESKTOP_SESSION", "") or "no detectado"
    gpu = cmd("lspci", "-mm")
    gpu_lines = [ln[:220] for ln in gpu.splitlines() if any(x in ln.lower() for x in ("vga compatible", "3d controller", "display controller"))]
    distro_id = osr.get("ID", "unknown").lower()
    return {
        "os": {"id": distro_id, "pretty_name": osr.get("PRETTY_NAME", "Linux"), "kernel": platform.release()},
        "cpu": {"model": cpu_name or platform.processor() or "unknown", "logical_threads": logical},
        "memory": {"total_mib": mem_total_mb()},
        "storage": storage(),
        "machine": {"vm": vm, "laptop": laptop and vm == "none", "desktop_session": desktop},
        "gpu": gpu_lines,
        "current_system": {
            "zram_active": active_zram, "zram_configured": configured_zram,
            "power_profiles_daemon": cmd("systemctl", "is-active", "power-profiles-daemon.service") == "active",
            "tuned": cmd("systemctl", "is-active", "tuned.service") == "active",
            "tlp": cmd("systemctl", "is-active", "tlp.service") == "active",
            "ananicy_cpp": cmd("systemctl", "is-active", "ananicy-cpp.service") == "active",
            "scx_loader": cmd("systemctl", "is-active", "scx_loader.service") == "active",
        }
    }


def calculate(hardware: dict[str, Any]) -> dict[str, Any]:
    cpu = max(1, int(hardware["cpu"]["logical_threads"]))
    ram_mib = max(0, int(hardware["memory"]["total_mib"]))
    ram_gib = ram_mib / 1024
    root = hardware["storage"]["root"]
    disk_free = float(root.get("free_gib", 0))
    total_disk = float(root.get("size_gib", 0))
    portable = bool(hardware["machine"]["laptop"])
    is_vm = hardware["machine"].get("vm", "none") != "none"

    if ram_gib <= 8 or cpu <= 2:
        tier = "compacto"
    elif ram_gib < 16 or cpu < 4:
        tier = "equilibrado"
    else:
        tier = "capaz"

    # Conservative heuristic, not a benchmark: ~2 GiB per concurrent heavy compile;
    # reserve 2 GiB for desktop and don't fully saturate laptop CPUs.
    ram_budget = max(1, int(max(0, ram_gib - 2) // 2))
    max_cpu = max(1, cpu - 1) if cpu > 2 else cpu
    cap = 4 if tier == "compacto" else (6 if portable or is_vm else 10)
    build_jobs = max(1, min(max_cpu, ram_budget, cap))
    container_jobs = max(1, min(max(1, cpu // 2), max(1, int(ram_gib // 4)), 3))
    if disk_free and disk_free < 15:
        container_jobs = min(container_jobs, 1)

    if total_disk <= 128:
        journal_mb = 128
    elif total_disk <= 512:
        journal_mb = 256
    else:
        journal_mb = 512
    if disk_free and disk_free < 10:
        journal_mb = min(journal_mb, 128)

    warnings = []
    current = hardware.get("current_system", {})
    if current.get("tuned") and current.get("power_profiles_daemon"):
        warnings.append("tuned y power-profiles-daemon aparecen activos: revisa el conflicto antes de cambiar perfiles.")
    if current.get("tlp") and current.get("power_profiles_daemon"):
        warnings.append("TLP y power-profiles-daemon aparecen activos: revisa el conflicto.")
    if not current.get("zram_active") and not current.get("zram_configured"):
        warnings.append("No se detecta ZRAM: inspecciona su configuración antes de modificar swap.")
    if disk_free and disk_free < 20:
        warnings.append("Queda poco espacio libre para imágenes OCI, SDK y cachés de compilación.")
    if is_vm:
        warnings.append("Se detectó una VM: este perfil refleja recursos asignados, NO los del equipo físico.")
    if hardware["os"]["id"] != "cachyos":
        warnings.append("Esta máquina no se identifica como CachyOS; generar es seguro, aplicar requiere CachyOS.")
    if "XFCE" not in hardware["machine"].get("desktop_session", "").upper():
        warnings.append("No hay sesión Xfce detectada: no aplicar configuración visual Xfce aquí.")

    return {
        "tier": tier,
        "workload": "desarrollo-devops",
        "build_jobs": build_jobs,
        "container_parallel_limit_advisory": container_jobs,
        "journal_limit_mib": journal_mb,
        "editor_graphical": "opcional",
        "recommended_install_modules": ["core", "desktop"] if tier != "compacto" else ["core"],
        "preserve_cachyos": ["kernel", "scheduler", "zram", "sysctl", "power_manager", "bootloader", "firewall"],
        "warnings": warnings,
    }


def profile(hardware: dict[str, Any] | None = None) -> dict[str, Any]:
    h = hardware if hardware is not None else detect()
    return {"schema": 1, "generated_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "hardware": h, "recommendations": calculate(h)}
