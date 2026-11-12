{ forcePkgConfig ? false }:
let
  pkgs = import /home/siraben/i686-iso-work/refresh-20261111/nixpkgs {
    system = "i686-linux";
  };
  minizip = pkgs.minizip-ng;
  pkgConfigOnly = pkgs.runCommand "minizip-ng-pkg-config-only" { } ''
    mkdir -p "$out/lib"
    ln -s ${minizip}/include "$out/include"
    ln -s ${minizip}/lib/pkgconfig "$out/lib/pkgconfig"
    for library in ${minizip}/lib/libminizip-ng.so*; do
      ln -s "$library" "$out/lib/"
    done
  '';
  dependency = if forcePkgConfig then pkgConfigOnly else minizip;
  mode = if forcePkgConfig then "pkgconfig" else "config";
in
(pkgs.opencolorio.override { minizip-ng = dependency; }).overrideAttrs (old: {
  doCheck = true;
  nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.pkg-config ];
  cmakeFlags = old.cmakeFlags ++ [ "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" ];
  # CPU comparison only: keep #536904's SSE2 approach separate from the public
  # filesystem ABI repair. There is deliberately NO private large-file flag.
  env = old.env // {
    CXXFLAGS = old.env.CXXFLAGS + " -mfpmath=sse -msse2";
  };
  postBuild = (old.postBuild or "") + ''
    ${pkgs.python3.interpreter} ${./audit/assert-ocio-file-abi.py} ${mode} \
      > "$TMPDIR/file-abi-compile-evidence.json"
    cat "$TMPDIR/file-abi-compile-evidence.json"
  '';
  postInstall = (old.postInstall or "") + ''
    mkdir -p "$out/nix-support"
    cp "$TMPDIR/file-abi-compile-evidence.json" "$out/nix-support/"
  '';
})
