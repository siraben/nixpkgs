# To update Elm:

Modify the revision in `./update.sh` and run it.

# Notes about the build process:

The Elm binary embeds a piece of precompiled Elm code used by
`elm reactor`. This means that the build process for Elm effectively
executes `elm make`. That, in turn, expects to retrieve the Elm
dependencies of that code (`elm/core`, etc.) from
package.elm-lang.org, as well as a cached bit of metadata
(`versions.dat`).

The `makeDotElm` function lets us retrieve these dependencies in the
standard Nix way. We have to copy them in (rather than symlink them) and
make them writable because the Elm compiler writes other `.dat` files
alongside the source code. `versions.dat` was produced during an
impure build of this same code; the build complains that it can't
update this cache, but continues past that warning.

Finally, we set `ELM_HOME` to point to these prefetched artifacts so
that the default of `~/.elm` isn't used.

More: https://blog.hercules-ci.com/elm/2019/01/03/elm2nix-0.1/
