{
  newlib,
  stdenvNoLibc,
  xtensaOverlays,
}:

# Mainline newlib for xtensa-*-elf, configured for ESP32 (LX6). The
# Xtensa ISA is configurable per chip, so the core-isa.h config header
# is vendored from Espressif's MIT-licensed xtensa-overlays.
newlib.overrideAttrs (old: {
  pname = "xtensa-newlib";
  postPatch = (old.postPatch or "") + ''
    coreIsa=${xtensaOverlays}/xtensa_esp32/newlib/newlib/libc/sys/xtensa/include/xtensa/config/core-isa.h
    install -D -m 0644 $coreIsa newlib/libc/include/xtensa/config/core-isa.h

    # We don't pass -mdynconfig, so force the ESP board selection.
    substituteInPlace libgloss/configure \
      --replace-fail "XTENSA_BOARD_ESP=\`echo \$CC | sed 's/.*-mdynconfig=xtensa_\(.*\)\.so.*/\1/;s/.*-mcpu=\(^ *\).*/\1/;s/.* .*/unknown/'\`" \
      'XTENSA_BOARD_ESP=esp32'

    # The esp32 board CPPFLAGS misses libgloss/xtensa/include.
    cp libgloss/xtensa/include/register_access.h \
       libgloss/xtensa/boards/esp32/include/register_access.h

    # libpthread_stubs only exists in Espressif's newlib fork.
    substituteInPlace libgloss/xtensa/board.elf.specs libgloss/xtensa/sim.elf.specs \
      --replace-fail ' -lpthread_stubs' ""
  '';

  # libgloss's generated Makefile.in omits clibrary_init.c (declared in
  # Makefile.inc), and _isatty_r needs libnosys's _isatty; fold both
  # into libgloss.a.
  postBuild = (old.postBuild or "") + ''
    src=$PWD
    libgloss="$src/${stdenvNoLibc.targetPlatform.config}/libgloss"

    # newlib's preConfigure sets CC to the build-host compiler; use the
    # cross cc directly.
    ${stdenvNoLibc.cc.targetPrefix}cc -D_LIBGLOSS \
      -I"$src/libgloss/xtensa/include" \
      -isystem "$src/${stdenvNoLibc.targetPlatform.config}/newlib/targ-include" \
      -isystem "$src/newlib/libc/include" \
      -c "$src/libgloss/xtensa/clibrary_init.c" \
      -o "$NIX_BUILD_TOP/clibrary_init.o"
    "$AR" rs "$libgloss/xtensa/libgloss.a" "$NIX_BUILD_TOP/clibrary_init.o"

    ( cd $NIX_BUILD_TOP \
      && "$AR" x "$libgloss/libnosys/libnosys.a" isatty.o \
      && "$AR" rs "$libgloss/xtensa/libgloss.a" isatty.o )
  '';
})
