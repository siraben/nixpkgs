{
  /**
    This should be used when there is a choice of which license expression to use.
    This is a disjunctive binary "OR" operator.

    # Example

    ```nix
    OR [ lib.licenses.mit lib.licenses.asl20 ]
    => { licenseType = "compound"; operator = "OR"; licenses = [ lib.licenses.mit lib.licenses.asl20 ] };
    ```

    # Type

    ```
    OR :: List -> AttrSet
    ```

    # Arguments

    - [licenses] Possible licenses to choose from
  */
  OR = licenses: {
    licenseType = "compound";
    operator = "OR";
    inherit licenses;
  };

  /**
     Create a compound license where the user needs to follow both licenses,
     equivalent of the SPDX `and` modifier.

    # Example

    ```nix
    AND [ lib.licenses.mit lib.licenses.asl20 ]
    => { licenseType = "compound"; operator = "AND"; licenses = [ lib.licenses.mit lib.licenses.asl20 ] };
    ```

    # Type

    ```
    AND :: List -> AttrSet
    ```

    # Arguments

    - [licenses] Licenses required to use
  */
  AND = licenses: {
    licenseType = "compound";
    operator = "AND";
    inherit licenses;
  };

  /**
     Create a license exception where a license has a license exception,
     equivalent of the SPDX `with` modifier.

    # Example

    ```nix
    WITH lib.licenses.lgpl21Only lib.licenses.ocamlLgplLinkingException
    => { licenseType = "exception"; operator = "WITH"; license = lib.licenses.lgpl21Only; exception = lib.licenses.ocamlLgplLinkingException; };
    ```

    # Type

    ```
    WITH :: AttrSet -> AttrSet -> AttrSet
    ```

    # Arguments

    - [license] License to which the exception applies
    - [exception] Exception to apply
  */
  WITH = license: exception: {
    licenseType = "exception";
    operator = "WITH";
    inherit license exception;
  };

  /**
     Create a license which can be upgraded to any later version of itself,
     equivalent of the SPDX `+` modifier.

    # Example

    ```nix
    PLUS lib.licenses.eupl11
    => { licenseType = "plus"; operator = "+"; license = lib.licenses.eupl11; };
    ```

    # Type

    ```
    PLUS :: AttrSet -> AttrSet
    ```

    # Arguments

    - [license] License to which to apply the exception
  */
  PLUS = license: {
    licenseType = "plus";
    operator = "+";
    inherit license;
  };
}
