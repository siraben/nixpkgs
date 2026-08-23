# To build this derivation, run `nix-build -A nixpkgs-manual.pythonInterpreterTable`
{
  lib,
  writeText,
  pkgs,
  pythonInterpreters,
}:
let
  isPythonInterpreter =
    name:
    /*
      NB: Package names that don't follow the regular expression:
      - `python-cosmopolitan` is not part of `pkgs.pythonInterpreters`.
      - `_prebuilt` interpreters are used for bootstrapping internally.
      - `python3Minimal` contains python packages, left behind conservatively.
      - `rustpython` lacks `pythonVersion` and `implementation`.
    */
    (lib.strings.match "(pypy|python)([[:digit:]]*)" name) != null;

  interpreterName =
    pname:
    let
      cuteName = {
        cpython = "CPython";
        pypy = "PyPy";
      };
      interpreter = pkgs.${pname};
    in
    "${cuteName.${interpreter.implementation}} ${interpreter.pythonVersion}";

  interpreters = lib.reverseList (
    lib.naturalSort (lib.filter isPythonInterpreter (lib.attrNames pythonInterpreters))
  );

  # Interpreter-like names in `pkgs`. Computing this once makes `aliases`
  # linear in the number of interpreters instead of re-scanning the whole
  # package set once per interpreter.
  interpreterLikeNames = lib.filter isPythonInterpreter (lib.attrNames pkgs);

  aliases =
    pname:
    lib.filter (
      name:
      # use tryEval to handle entries in aliases.nix
      (builtins.tryEval (
        name != pname && interpreterName name == interpreterName pname
      )).value
    ) interpreterLikeNames;

  result = map (pname: {
    inherit pname;
    aliases = aliases pname;
    interpreter = interpreterName pname;
  }) interpreters;

  toMarkdown =
    data:
    let
      line = package: ''
        | ${package.pname} | ${lib.concatStringsSep ", " package.aliases or [ ]} | ${package.interpreter} |
      '';
    in
    lib.concatStringsSep "" (map line data);

in
writeText "python-interpreter-table.md" ''
  | Package | Aliases | Interpreter |
  |---------|---------|-------------|
  ${toMarkdown result}
''
