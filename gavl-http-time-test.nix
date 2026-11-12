{ system ? "i686-linux" }:
let
  pkgs = import /home/siraben/i686-iso-work/refresh-20261111/nixpkgs { inherit system; };
in
pkgs.runCommandCC "gavl-http-time-regression" {
  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [ pkgs.gavl ];
} ''
  $CC -Wall -Wextra -Werror ${./gavl-http-time-test.c} -o test-gavl $(pkg-config --cflags --libs gavl)
  ./test-gavl
  touch "$out"
''
