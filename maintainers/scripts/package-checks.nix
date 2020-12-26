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

  packagesWithf = cond: f:
    pkgs.lib.concatLists (pkgs.lib.mapAttrsToList
      (name: pkg: safeEval
        (if pkgs.lib.isDerivation pkg && cond name pkg
         then safeEval (f pkg)
         else [ ]))
      pkgs);

  hasDesc = pkg: builtins.hasAttr "description" pkg.meta;
  hasLicense = pkg: builtins.hasAttr "license" pkg.meta;
  lastChar = x: builtins.substring (builtins.stringLength x - 1) (-1) x;
  report = desc: l:
    builtins.trace (pkgs.lib.concatStringsSep "\n" l) "";
in
{
  inherit pkgs report packagesWith packagesWithf;
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
  licenses =
    report "licenses of all packages" ((packagesWithf (name: pkg: builtins.hasAttr "license" pkg.meta)) (pkg: pkgs.lib.optional (pkgs.lib.isAttrs pkg.meta.license && builtins.hasAttr "shortName" pkg.meta.license) pkg.meta.license.shortName));
   
} 

# (packagesWithf (name: pkg: builtins.hasAttr "license" pkg.meta)) (pkg: [pkg.meta.license.shortName])
# (packagesWith (name: pkg: builtins.hasAttr "description" pkg.meta));
# (packagesWithf (name: pkg: builtins.hasAttr "license" pkg.meta)) (pkg: pkgs.lib.optional (pkgs.lib.isAttrs pkg.meta.license && builtins.hasAttr "shortName" pkg.meta.license) pkg.meta.license.shortName)
