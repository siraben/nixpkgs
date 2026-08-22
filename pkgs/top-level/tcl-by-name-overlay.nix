# Like ./by-name-overlay.nix, but for ../development/tcl-modules/by-name.
# Takes no arguments so Nix's import-value cache shares one copy across all
# package-set instantiations.
import ./make-by-name-overlay.nix ../development/tcl-modules/by-name
