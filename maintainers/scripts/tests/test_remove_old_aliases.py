import importlib.util
import unittest
from datetime import datetime
from pathlib import Path
from types import ModuleType
from unittest import mock


class FixedDatetime(datetime):
    @classmethod
    def today(cls) -> "FixedDatetime":
        return cls(2026, 1, 2)


def load_script() -> ModuleType:
    script = Path(__file__).parents[1] / "remove-old-aliases.py"
    spec = importlib.util.spec_from_file_location("remove_old_aliases", script)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ConvertTests(unittest.TestCase):
    def setUp(self) -> None:
        self.module = load_script()
        self.datetime_patch = mock.patch.object(
            self.module, "datetime", FixedDatetime
        )
        self.datetime_patch.start()
        self.addCleanup(self.datetime_patch.stop)

    def test_keeps_qualified_target_when_creating_warning(self) -> None:
        line = "  gtimelog = pkgs.gtimelog; # Added 2025-01-01"

        converted = self.module.convert([line], "warnings")[line]

        self.assertEqual(
            converted,
            "  gtimelog = warnAlias \"'gtimelog' has been renamed to/replaced by "
            "'pkgs.gtimelog'\" pkgs.gtimelog; # Converted to warning 2026-01-02",
        )

    def test_keeps_qualified_target_from_inherit(self) -> None:
        line = "  inherit (pkgs) gtimelog; # Added 2025-01-01"

        converted = self.module.convert([line], "warnings")[line]

        self.assertIn("'pkgs.gtimelog'", converted)
        self.assertIn('" pkgs.gtimelog;', converted)

    def test_preserves_warning_message_when_creating_throw(self) -> None:
        line = (
            "  gtimelog = warnAlias \"'python3Packages.gtimelog' has moved to "
            "'pkgs.gtimelog'\" pkgs.gtimelog; # Converted to warning 2025-01-01"
        )

        converted = self.module.convert([line], "throws")[line]

        self.assertEqual(
            converted,
            "  gtimelog = throw \"'python3Packages.gtimelog' has moved to "
            "'pkgs.gtimelog'\"; # Converted to throw 2026-01-02",
        )

    def test_preserves_escaped_quotes_in_warning_message(self) -> None:
        line = (
            '  old = warnAlias "Use \\"new\\" instead" pkgs.new; '
            "# Converted to warning 2025-01-01"
        )

        converted = self.module.convert([line], "throws")[line]

        self.assertIn('throw "Use \\"new\\" instead";', converted)
        self.assertNotIn("renamed to/replaced by", converted)


if __name__ == "__main__":
    unittest.main()
