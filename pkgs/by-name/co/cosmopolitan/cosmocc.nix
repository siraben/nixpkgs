{
  runCommand,
  cosmopolitan,
  unzip,
  cosmocc-zip,
  stdenv,
  callPackage,
  wrapCCWith,
  wrapBintoolsWith,
  overrideCC,
}:

let
  cosmocc =
    runCommand "cosmocc-${cosmopolitan.version}"
      {
        pname = "cosmocc";
        inherit (cosmopolitan) version;

        nativeBuildInputs = [ unzip ];

        passthru =
          {
            tests = {
              cc = runCommand "c-test" { nativeBuildInputs = [ unzip ]; } ''
                ${cosmocc}/bin/cosmocc ${./hello.c}
                ./a.out > $out
              '';
            };
          }
          // callPackage ../../../development/compilers/cosmocc/passthru.nix {
            inherit
              cosmocc
              stdenv
              callPackage
              wrapCCWith
              wrapBintoolsWith
              overrideCC
              ;
          };

        meta = cosmopolitan.meta // {
          description = "Compilers for Cosmopolitan C/C++ programs";
        };
      }
      ''
        mkdir -p $out
        unzip -qo ${cosmocc-zip} -d $out
      '';
in
cosmocc
