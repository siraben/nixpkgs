{
  newlib,
  xtensaOverlays,
}:

# Mainline newlib for xtensa-*-elf, configured for ESP32 (LX6). The
# Xtensa ISA is configurable per chip, so the core-isa.h config header
# is vendored from Espressif's MIT-licensed xtensa-overlays.
newlib.overrideAttrs (old: {
  pname = "xtensa-newlib";
  postPatch = (old.postPatch or "") + ''
    install -D -m 0644 \
      ${xtensaOverlays}/xtensa_esp32/newlib/newlib/libc/sys/xtensa/include/xtensa/config/core-isa.h \
      newlib/libc/include/xtensa/config/core-isa.h
  '';
})
