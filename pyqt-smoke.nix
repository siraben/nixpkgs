{ system ? "i686-linux" }:
let
  pkgs = import /home/siraben/i686-iso-work/refresh-20261111/nixpkgs { inherit system; };
in
pkgs.python3.withPackages (ps: [ ps.pyqt6 ])
