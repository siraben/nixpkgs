let
  pkgs = import ./../../default.nix {};
in

rec {
  safeEval = e: let result = builtins.tryEval e;
                in
                  if result.success
                  then result.value
                  else [ ];

  # Query packages with a condition, then return the file name
  packagesWith = cond:
    pkgs.lib.concatLists (pkgs.lib.mapAttrsToList
      (name: pkg: safeEval
        (if pkgs.lib.isDerivation pkg && cond name pkg && builtins.hasAttr "position" pkg.meta
         then [ pkg ]
         else [ ]))
      pkgs);

  pkgPos = pkg: builtins.elemAt (pkgs.lib.splitString ":" pkg.meta.position) 0;
  # Check if a package has a description
  hasDesc = pkg: builtins.hasAttr "description" pkg.meta;

  # Last character of a string
  lastChar = x: builtins.substring (builtins.stringLength x - 1) (-1) x;

  # Report
  report = l: builtins.trace (pkgs.lib.concatStringsSep "\n" l) "";
}

# Example: getting packages with no build dependencies
# x = packagesWith (name: pkg: let n = safeEval (pkg.buildInputs == []); in if builtins.hasAttr "buildInputs" pkg then if [] == n then false else n else false)

# Print out the path of ones that don't have darwin in the platforms
# report (builtins.map pkgPos (builtins.filter (p: !(builtins.hasAttr "platforms" p.meta) || !(lib.elem "x86_64-darwin" p.meta.platforms)) (builtins.map safeEval x)))
