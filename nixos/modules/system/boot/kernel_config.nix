{ lib, config, ... }:

with lib;
let
  # A single structured kernel configuration item: an attribute set with the
  # (all optional) members `tristate`, `freeform` and `optional`.
  #
  # This is deliberately *not* a `types.submodule`: kernel configurations
  # contain hundreds of items and every kernel in nixpkgs evaluates its own
  # configuration, so the submodule used to instantiate the whole module
  # system once per item per kernel (~700 nested evalModules calls per
  # kernel attribute). The type below computes the identical merged value —
  # same member defaults, same conflict errors, and the same handling of
  # mkIf/mkMerge/mkOverride/mkOrder, which it mirrors from
  # `lib.modules.mergeDefinitions` — without any nested module evaluation.
  # Behaviour is pinned by pkgs/test/kernel.nix.
  kernelItem =
    let
      knownKeys = [
        "tristate"
        "freeform"
        "optional"
      ];

      tristateType = types.enum [
        "y"
        "m"
        "n"
        null
      ];
      freeformType = types.nullOr types.str;

      # Local equivalents of the module system's per-definition processing
      # (`lib.modules.dischargeProperties`, `filterOverrides'` and
      # `sortProperties`, which are deprecated for external use). These mirror
      # their behaviour exactly for the property wrappers that can occur in
      # configuration items: mkIf, mkMerge, mkOverride, mkOrder.
      discharge =
        value:
        if value._type or "" == "merge" then
          concatMap discharge value.contents
        else if value._type or "" == "if" then
          if isBool value.condition then
            if value.condition then discharge value.content else [ ]
          else
            throw "‘mkIf’ called with a non-Boolean condition"
        else
          [ value ];

      filterOverrides =
        defs:
        let
          getPrio = def: if def.value._type or "" == "override" then def.value.priority else 100;
          strip =
            def:
            if def.value._type or "" == "override" then
              def // { value = def.value.content; }
            else
              def;
        in
        if length defs == 1 then
          map strip defs
        else
          let
            highestPrio = foldl' (prio: def: min (getPrio def) prio) 9999 defs;
          in
          filter (def: getPrio def == highestPrio) defs;

      sortByOrder =
        defs:
        let
          strip =
            def:
            if def.value._type or "" == "order" then
              def
              // {
                value = def.value.content;
                inherit (def.value) priority;
              }
            else
              def;
        in
        sort (a: b: (a.priority or 1000) < (b.priority or 1000)) (map strip defs);

      # Process the definitions of one member the way the module system
      # processes option definitions before calling the type's merge:
      # discharge mkIf/mkMerge wrappers, drop lower-priority mkOverride
      # definitions, then apply mkOrder.
      processMember =
        key: defs:
        let
          discharged = concatMap (
            def:
            map (value: {
              inherit (def) file;
              inherit value;
            }) (discharge def.value.${key})
          ) (filter (def: def.value ? ${key}) defs);
          filtered = filterOverrides discharged;
        in
        if any (def: def.value._type or "" == "order") filtered then
          sortByOrder filtered
        else
          filtered;
    in
    types.mkOptionType {
      name = "kernelConfigItem";
      description = "kernel configuration item";
      descriptionClass = "noun";
      # Validation happens in `merge`, after the per-definition processing
      # above has unwrapped property values; `check` only guards the root so
      # that non-attribute-set definitions produce a sane error message.
      check = isAttrs;
      merge =
        loc: defs:
        let
          result = {
            tristate =
              let
                memberDefs = processMember "tristate" defs;
              in
              if memberDefs == [ ] then null else tristateType.merge (loc ++ [ "tristate" ]) memberDefs;
            freeform =
              let
                memberDefs = processMember "freeform" defs;
              in
              if memberDefs == [ ] then null else freeformType.merge (loc ++ [ "freeform" ]) memberDefs;
            optional =
              let
                vals = map (def: def.value) (processMember "optional" defs);
              in
              if vals == [ ] then false else !elem false vals;
          };
        in
        # Reject unknown members and non-attribute-set items with the same
        # strictness as the module system's `_module.check`.
        seq (
          foldl' (
            acc: def:
            if !isAttrs def.value then
              throw
                "The definition of `${showOption loc}' is not a kernel configuration item (attribute set), but a value of type `${builtins.typeOf def.value}'"
            else
              let
                extra = subtractLists knownKeys (attrNames def.value);
              in
              if extra != [ ] then
                throw
                  "The kernel configuration item `${showOption loc}' does not support the option${if length extra > 1 then "s" else ""} ${concatStringsSep ", " (map (k: "`${k}'") extra)}"
              else
                acc
          ) 0 defs
        ) result;
    };

  mkValue =
    with lib;
    val:
    let
      isNumber =
        c:
        elem c [
          "0"
          "1"
          "2"
          "3"
          "4"
          "5"
          "6"
          "7"
          "8"
          "9"
        ];

    in
    if (val == "") then
      "\"\""
    else if val == "y" || val == "m" || val == "n" then
      val
    else if all isNumber (stringToCharacters val) then
      val
    else if substring 0 2 val == "0x" then
      val
    else
      val; # FIXME: fix quoting one day

  # generate nix intermediate kernel config file of the form
  #
  #       VIRTIO_MMIO m
  #       VIRTIO_BLK y
  #       VIRTIO_CONSOLE n
  #       NET_9P_VIRTIO? y
  #
  # Borrowed from copumpkin https://github.com/NixOS/nixpkgs/pull/12158
  # returns a string, expr should be an attribute set
  # Use mkValuePreprocess to preprocess option values, aka mark 'modules' as 'yes' or vice-versa
  # use the identity if you don't want to override the configured values
  generateNixKConf =
    exprs:
    let
      mkConfigLine =
        key: item:
        let
          val = if item.freeform != null then item.freeform else item.tristate;
        in
        optionalString (val != null) (
          if (item.optional) then "${key}? ${mkValue val}\n" else "${key} ${mkValue val}\n"
        );

      mkConf = cfg: concatStrings (mapAttrsToList mkConfigLine cfg);
    in
    mkConf exprs;

in
{

  options = {

    intermediateNixConfig = mkOption {
      readOnly = true;
      type = types.lines;
      example = ''
        USB? y
        DEBUG n
      '';
      description = ''
        The result of converting the structured kernel configuration in settings
        to an intermediate string that can be parsed by generate-config.pl to
        answer the kernel `make defconfig`.
      '';
    };

    settings = mkOption {
      type = types.attrsOf kernelItem;
      example = literalExpression ''
        with lib.kernel; {
               "9P_NET" = yes;
               USB = option yes;
               MMC_BLOCK_MINORS = freeform "32";
             }'';
      description = ''
        Structured kernel configuration.
      '';
    };
  };

  config = {
    intermediateNixConfig = generateNixKConf config.settings;
  };
}
