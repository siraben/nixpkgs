{
  lib,
  stdenv,
  fetchurl,
  flex,
  bison,
  python3,
  libtool,
  bash,
  gettext,
  ncurses,
  libusb-compat-0_1,
  freetype,
  qemu,
  lvm2,
  unifont,
  pkg-config,
  help2man,
  fetchpatch,
  buildPackages,
  nixosTests,
  fuse3, # only needed for grub-mount
  runtimeShell,
  zfs ? null,
  efiSupport ? false,
  ieee1275Support ? false,
  zfsSupport ? false,
  xenSupport ? false,
  xenPvhSupport ? false,
  kbdcompSupport ? false,
  ckbcomp,
}:

let
  pcSystems = {
    i686-linux.target = "i386";
    x86_64-linux.target = "i386";
  };

  efiSystemsBuild = {
    i686-linux.target = "i386";
    x86_64-linux.target = "x86_64";
    armv7l-linux.target = "arm";
    aarch64-linux.target = "aarch64";
    loongarch64-linux.target = "loongarch64";
    riscv32-linux.target = "riscv32";
    riscv64-linux.target = "riscv64";
  };

  # For aarch64, we need to use '--target=aarch64-efi' when building,
  # but '--target=arm64-efi' when installing. Insanity!
  efiSystemsInstall = {
    i686-linux.target = "i386";
    x86_64-linux.target = "x86_64";
    armv7l-linux.target = "arm";
    aarch64-linux.target = "arm64";
    loongarch64-linux.target = "loongarch64";
    riscv32-linux.target = "riscv32";
    riscv64-linux.target = "riscv64";
  };

  ieee1275SystemsBuild = {
    x86_64-linux.target = "i386";
    powerpc64-linux.target = "powerpc";
  };

  xenSystemsBuild = {
    i686-linux.target = "i386";
    x86_64-linux.target = "x86_64";
  };

  xenPvhSystemsBuild = {
    i686-linux.target = "i386";
    x86_64-linux.target = "i386"; # Xen PVH is only i386 on x86.
  };

  inPCSystems = lib.any (system: stdenv.hostPlatform.system == system) (lib.attrNames pcSystems);

in

assert zfsSupport -> zfs != null;
assert lib.asserts.assertMsg (
  lib.lists.length (
    lib.lists.filter (x: x) [
      efiSupport
      ieee1275Support
      xenSupport
      xenPvhSupport
    ]
  ) <= 1 # (0 == pc)
) "Only <= 1 of grub2's platform-related *Support options may be enabled at the same time";

stdenv.mkDerivation rec {
  pname = "grub";
  version = "2.14";

  src = fetchurl {
    url = "mirror://gnu/grub/grub-${version}.tar.xz";
    hash = "sha256-vI08c1NbiDjYyOJlTXPtxOaujIrNtF1d9dyaFUdEbUM=";
  };

  patches = [
    # NixOS installer media use hidden entries for alternate boot modes.
    ./add-hidden-menu-entries.patch

    # Required to build grub2_efi with GCC 16, or fails with "error: 'regparm'
    # attribute ignored [-Werror=attributes]"
    (fetchpatch {
      name = "gcc16_make_regparm_attribute_more_conditional.patch";
      url = "https://git.savannah.gnu.org/cgit/grub.git/patch/?id=9922ed133c2c754ec9f37198da2b3e3e8a4fd5ff";
      hash = "sha256-V2vffDxL/qQ14YN5scc3CFPBFBWvkh57dc5/hWd/6F4=";
    })
  ];

  postPatch = ''
    # GRUB 2.14's --image-base probe produces mislinked BIOS and Xen images
    # with current linkers. This is the release-tarball equivalent of the
    # upstream post-2.14 revert 1dc2986c7e8480d955f87d276d31400116a21fac.
    substituteInPlace configure \
      --replace-fail 'TARGET_IMG_BASE_LDOPT="-Wl,--image-base"' \
      'TARGET_IMG_BASE_LDOPT="-Wl,-Ttext"'
  ''
  + (
    if kbdcompSupport then
      ''
        sed -i util/grub-kbdcomp.in -e 's@\bckbcomp\b@${ckbcomp}/bin/ckbcomp@'
      ''
    else
      ''
        echo '#! ${runtimeShell}' > util/grub-kbdcomp.in
        echo 'echo "Compile grub2 with { kbdcompSupport = true; } to enable support for this command."' >> util/grub-kbdcomp.in
      ''
  );

  depsBuildBuild = [
    buildPackages.stdenv.cc
    pkg-config
  ];
  nativeBuildInputs = [
    bison
    flex
    python3
    pkg-config
    gettext
    freetype
    help2man
  ];
  buildInputs = [
    ncurses
    libusb-compat-0_1
    freetype
    lvm2
    fuse3
    libtool
    bash
  ]
  ++ lib.optional doCheck qemu
  ++ lib.optional zfsSupport zfs;

  strictDeps = true;

  hardeningDisable = [ "all" ];

  separateDebugInfo = !xenSupport;

  preConfigure = ''
     for i in "tests/util/"*.in
     do
       sed -i "$i" -e's|/bin/bash|${stdenv.shell}|g'
     done

     # Apparently, the QEMU executable is no longer called
     # `qemu-system-i386', even on i386.
     #
     # In addition, use `-nodefaults' to avoid errors like:
     #
     #  chardev: opening backend "stdio" failed
     #  qemu: could not open serial device 'stdio': Invalid argument
     #
     # See <http://www.mail-archive.com/qemu-devel@nongnu.org/msg22775.html>.
     sed -i "tests/util/grub-shell.in" \
         -e's/qemu-system-i386/qemu-system-x86_64 -nodefaults/g'

    unset CPP # setting CPP intereferes with dependency calculation

    patchShebangs .

    substituteInPlace ./configure --replace '/usr/share/fonts/unifont' '${unifont}/share/fonts'
  ''
  # build-grub-mkfont is built & run during build, need to find freetype for buildPlatform
  + lib.optionalString (!lib.systems.equals stdenv.buildPlatform stdenv.hostPlatform) ''
    configureFlagsArray+=(
      "BUILD_PKG_CONFIG=$PKG_CONFIG_FOR_BUILD"
    )
  '';

  configureFlags = [
    "--enable-grub-mount" # dep of os-prober
  ]
  ++ lib.optionals (stdenv.hostPlatform != stdenv.buildPlatform) [
    # grub doesn't do cross-compilation as usual and tries to use unprefixed
    # tools to target the host. Provide toolchain information explicitly for
    # cross builds.
    #
    # Ref: # https://github.com/buildroot/buildroot/blob/master/boot/grub2/grub2.mk#L108
    "TARGET_CC=${stdenv.cc.targetPrefix}cc"
    "TARGET_NM=${stdenv.cc.targetPrefix}nm"
    "TARGET_OBJCOPY=${stdenv.cc.targetPrefix}objcopy"
    "TARGET_RANLIB=${stdenv.cc.targetPrefix}ranlib"
    "TARGET_STRIP=${stdenv.cc.targetPrefix}strip"
  ]
  ++ lib.optional zfsSupport "--enable-libzfs"
  ++ lib.optionals efiSupport [
    "--with-platform=efi"
    "--target=${efiSystemsBuild.${stdenv.hostPlatform.system}.target}"
    "--program-prefix="
  ]
  ++ lib.optionals ieee1275Support [
    "--with-platform=ieee1275"
    "--target=${ieee1275SystemsBuild.${stdenv.hostPlatform.system}.target}"
  ]
  ++ lib.optionals xenSupport [
    "--with-platform=xen"
    "--target=${xenSystemsBuild.${stdenv.hostPlatform.system}.target}"
  ]
  ++ lib.optionals xenPvhSupport [
    "--with-platform=xen_pvh"
    "--target=${xenPvhSystemsBuild.${stdenv.hostPlatform.system}.target}"
  ];

  # save target that grub is compiled for
  grubTarget =
    if efiSupport then
      "${efiSystemsInstall.${stdenv.hostPlatform.system}.target}-efi"
    else if ieee1275Support then
      "${ieee1275SystemsBuild.${stdenv.hostPlatform.system}.target}-ieee1275"
    else
      lib.optionalString inPCSystems "${pcSystems.${stdenv.hostPlatform.system}.target}-pc";

  doCheck = false;
  enableParallelBuilding = true;

  postInstall = ''
    # Avoid a runtime reference to gcc
    sed -i $out/lib/grub/*/modinfo.sh -e "/grub_target_cppflags=/ s|'.*'|' '|"
    # just adding bash to buildInputs wasn't enough to fix the shebang
    substituteInPlace $out/lib/grub/*/modinfo.sh \
      --replace ${buildPackages.bash} "/usr/bin/bash"
  '';

  passthru.tests = {
    nixos-grub = nixosTests.grub;
    nixos-install-simple = nixosTests.installer.simple;
    nixos-install-grub-uefi = nixosTests.installer.simpleUefiGrub;
    nixos-install-grub-uefi-spec = nixosTests.installer.simpleUefiGrubSpecialisation;
  };

  meta = {
    description = "GNU GRUB, the Grand Unified Boot Loader";

    longDescription = ''
      GNU GRUB is a Multiboot boot loader. It was derived from GRUB, GRand
      Unified Bootloader, which was originally designed and implemented by
      Erich Stefan Boleyn.

      Briefly, the boot loader is the first software program that runs when a
      computer starts.  It is responsible for loading and transferring
      control to the operating system kernel software (such as the Hurd or
      the Linux).  The kernel, in turn, initializes the rest of the
      operating system (e.g., GNU).
    '';

    homepage = "https://www.gnu.org/software/grub/";

    license = lib.licenses.gpl3Plus;

    platforms =
      if efiSupport then
        lib.attrNames efiSystemsBuild
      else if ieee1275Support then
        lib.attrNames ieee1275SystemsBuild
      else if xenSupport then
        lib.attrNames xenSystemsBuild
      else if xenPvhSupport then
        lib.attrNames xenPvhSystemsBuild
      else
        lib.platforms.gnu ++ lib.platforms.linux;

    maintainers = [ ];
  };
}
