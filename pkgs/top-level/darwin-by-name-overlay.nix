# Like ./by-name-overlay.nix, but for ../os-specific/darwin/by-name.
# Takes no arguments so Nix's import-value cache shares one copy across all
# package-set instantiations.
import ./make-by-name-overlay.nix ../os-specific/darwin/by-name
