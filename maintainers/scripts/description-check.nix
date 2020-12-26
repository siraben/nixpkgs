let
  pkgs = import ./../../default.nix {};

  safeEval = e: let result = builtins.tryEval e;
                in
                  if result.success
                  then result.value
                  else [ ];

  packagesWith = cond:
    pkgs.lib.concatLists (pkgs.lib.mapAttrsToList
      (name: pkg: safeEval
        (if pkgs.lib.isDerivation pkg && cond name pkg
         then [ (builtins.elemAt (pkgs.lib.splitString ":" pkg.meta.position) 0) ]
         else [ ]))
      pkgs);

  hasDesc = pkg: builtins.hasAttr "description" pkg.meta;
  lastChar = x: builtins.substring (builtins.stringLength x - 1) (-1) x;
  report = desc: l:
    builtins.trace (pkgs.lib.concatStringsSep "\n" l) "";
in
{
  prefixDescCaseInsen =
    report "start with the package name in the description (case insensitive)"
      (packagesWith
        (name: pkg:
          hasDesc pkg && pkgs.lib.hasPrefix (pkgs.lib.toLower name) (pkgs.lib.toLower pkg.meta.description)));
  periodDesc =
    report "have a period at the end of their description"
      (packagesWith
        (name: pkg:
          if hasDesc pkg && builtins.stringLength pkg.meta.description != 0
          then lastChar pkg.meta.description == "."
          else false));
}
