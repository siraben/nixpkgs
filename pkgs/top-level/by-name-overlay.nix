# This file turns the pkgs/by-name directory (see its README.md) into an
# overlay that adds all the defined packages.
# It takes no arguments on purpose: thanks to Nix's import-value cache, this
# way the resulting overlay is evaluated only once per process and shared by
# every package-set instantiation, instead of each instantiation redoing the
# expensive scan of ../by-name. The generic constructor lives in
# ./make-by-name-overlay.nix.
import ./make-by-name-overlay.nix ../by-name
