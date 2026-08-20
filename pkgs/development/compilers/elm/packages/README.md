# Elm packages

A mixture of useful Elm tooling containing both Haskell and Node.js-based utilities.

## Upgrades

Haskell parts of the ecosystem use [cabal2nix](https://github.com/NixOS/cabal2nix).
Please refer to the [Nix documentation](https://nixos.org/nixpkgs/manual/#how-to-create-nix-builds-for-your-own-private-haskell-packages)
and [cabal2nix README](https://github.com/NixOS/cabal2nix#readme) for more information. Elm-format [update scripts](https://github.com/avh4/elm-format/tree/master/package/nix)
are part of its repository.

Node dependencies are defined with [`buildNpmPackage`](https://nixos.org/manual/nixpkgs/stable/#javascript-buildNpmPackage).
