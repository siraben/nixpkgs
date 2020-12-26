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
         then [ name ]
         else [ ]))
      pkgs);

  hasDesc = pkg: builtins.hasAttr "description" pkg.meta;
  hasName = pkg: builtins.hasAttr "name" pkg;
  lastChar = x: builtins.substring (builtins.stringLength x - 1) (-1) x;
  report = desc: l:
    builtins.trace (pkgs.lib.concatStringsSep "\n" l) "";
in
{
  name =
    report "have a period at the end of their description"
      (packagesWith
        (name: pkg: hasName pkg));

}
