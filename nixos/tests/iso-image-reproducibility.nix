# Regression test for ISO dependence on hardlinks in the input filesystem.
# Fixtures are created inside the test, so NAR copying or store optimisation
# cannot silently change their inode topology before the comparison.
{
  pkgs ? import ../.. { },
  isoBuilder ? ../lib/make-iso9660-image.sh,
}:

pkgs.runCommand "iso-image-hardlink-independence"
  {
    nativeBuildInputs = [
      pkgs.xorriso
      pkgs.libossp_uuid
    ];
  }
  ''
    mkdir hardlinked copied
    printf 'identical file content\n' > hardlinked/a
    ln hardlinked/a hardlinked/b
    ln -s a hardlinked/symlink
    cp -R --no-preserve=links hardlinked/. copied/
    test "$(stat -c %h hardlinked/a)" = 2
    test "$(stat -c %h copied/a)" = 1

    hardlinked="$PWD/hardlinked"
    copied="$PWD/copied"
    make_image() (
      mkdir "$1"
      cd "$1"
      sources=("$2" "$2/symlink")
      targets=(data top-symlink)
      objects=()
      symlinks=()
      isoName=test.iso
      volumeID=NIXOS_ORDER_TEST
      bootable=""
      bootImage=""
      usbBootable=""
      efiBootable=""
      compressImage=""
      squashfsCommand=""
      closureInfo=${pkgs.closureInfo { rootPaths = [ ]; }}
      out="$PWD/result"
      source ${isoBuilder}
    )

    make_image image-hardlinked "$hardlinked"
    make_image image-copied "$copied"
    cmp image-hardlinked/result/iso/test.iso image-copied/result/iso/test.iso
    xorriso -osirrox on -indev image-hardlinked/result/iso/test.iso -extract / extracted
    cmp "$hardlinked/a" extracted/data/a
    cmp "$hardlinked/b" extracted/data/b
    test "$(readlink extracted/data/symlink)" = a
    test "$(readlink extracted/top-symlink)" = a
    mkdir "$out"
    sha256sum image-hardlinked/result/iso/test.iso > "$out/iso-sha256"
  ''
