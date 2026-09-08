import csv
import os
from pathlib import Path
from types import SimpleNamespace

import pytest

from updater import (
    CSV_FIELDNAMES,
    LuaEditor,
    LuaPlugin,
    generated_package_specs,
    load_package_specs,
    render_neovim_plugins,
)


def write_specs(path: Path, rows: list[dict[str, str]]) -> None:
    with path.open("w", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=CSV_FIELDNAMES, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def row(name: str, *, neovim: str = "", manual: str = "") -> dict[str, str]:
    return {
        "name": name,
        "rockspec": "",
        "ref": "",
        "server": "",
        "version": "",
        "luaversion": "",
        "maintainers": "",
        "neovim": neovim,
        "manual": manual,
    }


def plugin(name: str, *, neovim: bool = False, manual: bool = False) -> LuaPlugin:
    return LuaPlugin(
        name=name,
        rockspec="",
        ref=None,
        server=None,
        version=None,
        luaversion=None,
        maintainers=None,
        neovim=neovim,
        manual=manual,
    )


def test_load_package_specs_parses_plugin_metadata(tmp_path: Path) -> None:
    csv_path = tmp_path / "packages.csv"
    write_specs(
        csv_path,
        [
            row("plain"),
            row("plugin.nvim", neovim="true"),
            row("manual.nvim", neovim="true", manual="true"),
        ],
    )

    specs = load_package_specs(csv_path)

    assert [(spec.normalized_name, spec.neovim, spec.manual) for spec in specs] == [
        ("plain", False, False),
        ("plugin-nvim", True, False),
        ("manual-nvim", True, True),
    ]
    assert [spec.name for spec in generated_package_specs(specs)] == ["plain", "plugin.nvim"]


@pytest.mark.parametrize("field", ["neovim", "manual"])
def test_load_package_specs_rejects_invalid_boolean(tmp_path: Path, field: str) -> None:
    csv_path = tmp_path / "packages.csv"
    invalid_row = row("invalid")
    invalid_row[field] = "yes"
    write_specs(csv_path, [invalid_row])

    with pytest.raises(ValueError, match=rf"Invalid {field} value for invalid"):
        load_package_specs(csv_path)


def test_load_package_specs_rejects_normalized_name_collisions(tmp_path: Path) -> None:
    csv_path = tmp_path / "packages.csv"
    write_specs(csv_path, [row("same.nvim"), row("same-nvim")])

    with pytest.raises(ValueError, match="Duplicate normalized package name: same-nvim"):
        load_package_specs(csv_path)


@pytest.mark.parametrize("neovim", [False, True])
def test_add_records_neovim_marker(tmp_path: Path, neovim: bool) -> None:
    csv_path = tmp_path / "packages.csv"
    write_specs(csv_path, [row("existing")])

    class Editor:
        default_in = csv_path

        def get_update(self, *_args, **_kwargs):
            return lambda: ({}, [("new-nvim", "init", "1.0")])

    args = SimpleNamespace(
        add_plugins=["new.nvim"],
        proc=1,
        github_token=None,
        maintainers="maintainer",
        neovim=neovim,
        outfile=tmp_path / "generated.nix",
        no_commit=True,
    )

    LuaEditor.add(Editor(), args)

    specs = load_package_specs(csv_path)
    added = next(spec for spec in specs if spec.name == "new.nvim")
    assert added.neovim is neovim
    assert added.manual is False


def test_render_neovim_plugins_is_sorted_and_includes_manual_packages() -> None:
    rendered = render_neovim_plugins(
        [
            plugin("z.nvim", neovim=True),
            plugin("ignored.nvim"),
            plugin("a.nvim", neovim=True, manual=True),
        ]
    )

    assert '    "a-nvim"\n    "z-nvim"' in rendered
    assert "ignored-nvim" not in rendered
    assert "luaAttr = luaPackages.${name};" in rendered


def test_checked_in_neovim_plugins_are_generated() -> None:
    package_list = os.environ.get("NIXPKGS_LUAROCKS_PACKAGES")
    generated_file = os.environ.get("NIXPKGS_NEOVIM_PLUGINS")
    if package_list is None or generated_file is None:
        pytest.skip("checked-in source paths are provided by the Nix package check")

    specs = load_package_specs(package_list)

    assert Path(generated_file).read_text() == render_neovim_plugins(specs)
