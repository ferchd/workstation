import unittest
from workstation.profiler import calculate


def hardware(ram=24, cpu=8, space=140, size=250, vm="none", laptop=True, zram=True, desktop="XFCE"):
    return {
        "os": {"id": "cachyos", "pretty_name": "CachyOS", "kernel": "linux-cachyos"},
        "cpu": {"logical_threads": cpu, "model": "Generic"},
        "memory": {"total_mib": ram * 1024},
        "storage": {"root": {"size_gib": size, "free_gib": space}},
        "machine": {"vm": vm, "laptop": laptop, "desktop_session": desktop},
        "current_system": {"zram_active": zram, "zram_configured": zram,
                           "tuned": False, "tlp": False, "power_profiles_daemon": True},
    }


class ProfileTests(unittest.TestCase):
    def test_laptop_i5_24gb(self):
        p = calculate(hardware())
        self.assertEqual(p["tier"], "capaz")
        self.assertEqual(p["build_jobs"], 6)
        self.assertEqual(p["container_parallel_limit_advisory"], 3)
        self.assertEqual(p["journal_limit_mib"], 256)

    def test_tiny_vm(self):
        p = calculate(hardware(4, 2, 6, 40, vm="microsoft", laptop=False, zram=False))
        self.assertEqual(p["tier"], "compacto")
        self.assertEqual(p["build_jobs"], 1)
        self.assertEqual(p["container_parallel_limit_advisory"], 1)
        self.assertTrue(any("VM" in w for w in p["warnings"]))

    def test_no_duplicate_zram_config(self):
        p = calculate(hardware())
        self.assertFalse(any("No se detecta ZRAM" in w for w in p["warnings"]))

    def test_conflicting_power_managers(self):
        h = hardware()
        h["current_system"]["tuned"] = True
        p = calculate(h)
        self.assertTrue(any("tuned" in w for w in p["warnings"]))

    def test_small_disk(self):
        p = calculate(hardware(space=8))
        self.assertEqual(p["journal_limit_mib"], 128)
        self.assertEqual(p["container_parallel_limit_advisory"], 1)


if __name__ == "__main__":
    unittest.main()
