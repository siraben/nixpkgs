{
  lib,
  stdenvNoLibc,
  fetchurl,
  automake,
  autoconf,
}:

stdenvNoLibc.mkDerivation (finalAttrs: {
  pname = "avr-libc";
  version = "2.3.2";

  tag_version = builtins.replaceStrings [ "." ] [ "_" ] finalAttrs.version;
  src = fetchurl {
    url = "https://github.com/avrdudes/avr-libc/releases/download/avr-libc-${finalAttrs.tag_version}-release/avr-libc-${finalAttrs.version}.tar.bz2";
    hash = "sha256-kuslPTDOyU8oYagtQNCxetecDZX84yt0/8zCanCvsVA=";
  };

  nativeBuildInputs = [
    automake
    autoconf
  ];

  # Make sure we don't strip the libraries in lib/gcc/avr.
  stripDebugList = [ "bin" ];
  dontPatchELF = true;

  enableParallelBuilding = true;

  passthru = {
    incdir = "/avr/include";
  };

  meta = {
    description = "C runtime library for AVR microcontrollers";
    homepage = "https://github.com/avrdudes/avr-libc";
    changelog = "https://github.com/avrdudes/avr-libc/blob/avr-libc-${finalAttrs.tag_version}-release/NEWS.md";
    license = lib.licenses.bsd3;
    platforms = [ "avr-none" ];
    maintainers = with lib.maintainers; [
      mguentner
      emilytrau
    ];
  };
})
