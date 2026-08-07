{
  lib,
  mkKdeDerivation,
}:
mkKdeDerivation {
  pname = "kate";

  # GCC produces nondeterministic DWARF when reusing precompiled headers,
  # which also makes the build IDs of the stripped binaries differ.
  # https://gcc.gnu.org/bugzilla/show_bug.cgi?id=124811
  extraCmakeFlags = [ (lib.cmakeBool "ENABLE_PCH" false) ];
}
