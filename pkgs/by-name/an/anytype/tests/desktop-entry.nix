{
  testers,
  desktop-file-utils,
  package,
}:

testers.runCommand {
  name = "anytype-desktop-entry-test";
  nativeBuildInputs = [ desktop-file-utils ];
  script = ''
    migrate="${package}/libexec/anytype-migrate-desktop-entry"
    test -x "$migrate"
    grep -Fq "$migrate || true" "${package}/bin/anytype"

    writeGeneratedEntry() {
      local file=$1
      local ozoneFlag=$2
      mkdir -p "$(dirname "$file")"
      cat > "$file" <<EOF
    [Desktop Entry]
    Name=Anytype
    Comment=Project management and knowledge workspace
    Exec="/nix/store/00000000000000000000000000000000-electron-unwrapped-41.2.0/libexec/electron/electron"$ozoneFlag %u
    Terminal=false
    Type=Application
    Icon=anytype
    Categories=Utility;Office;Calendar;ProjectManagement;
    StartupWMClass=anytype
    Keywords=project management;
    MimeType=x-scheme-handler/anytype;
    EOF
    }

    canonical="${package}/share/applications/com.anytype.anytype.desktop"
    compatibility="${package}/share/applications/anytype.desktop"

    resolveDesktopId() {
      local desktopId=$1
      local dataDir
      for dataDir in "$PWD/legacy" "${package}/share"; do
        if [[ -e "$dataDir/applications/$desktopId" ]]; then
          printf '%s\n' "$dataDir/applications/$desktopId"
          return 0
        fi
      done
      return 1
    }

    legacy="$PWD/legacy/applications/anytype.desktop"
    writeGeneratedEntry "$legacy" ""
    # Upstream generated this entry without a trailing newline.
    truncate -s -1 "$legacy"
    cp "$legacy" "$PWD/legacy.expected"
    test "$(resolveDesktopId anytype.desktop)" = "$legacy"
    test "$(resolveDesktopId com.anytype.anytype.desktop)" = "$canonical"

    XDG_DATA_HOME="$PWD/legacy" "$migrate"
    test ! -e "$legacy"
    cmp "$PWD/legacy.expected" "$legacy.anytype-generated.bak"
    test "$(resolveDesktopId anytype.desktop)" = "$compatibility"

    writeGeneratedEntry "$legacy" " --ozone-platform-hint=auto"
    XDG_DATA_HOME="$PWD/legacy" "$migrate"
    test ! -e "$legacy"
    test -e "$legacy.anytype-generated.bak.1"

    homeLegacy="$PWD/home/.local/share/applications/anytype.desktop"
    writeGeneratedEntry "$homeLegacy" ""
    env -u XDG_DATA_HOME HOME="$PWD/home" "$migrate"
    test ! -e "$homeLegacy"
    test -e "$homeLegacy.anytype-generated.bak"

    custom="$PWD/custom/applications/anytype.desktop"
    writeGeneratedEntry "$custom" ""
    substituteInPlace "$custom" --replace-fail 'Name=Anytype' 'Name=My Anytype launcher'
    cp "$custom" "$PWD/custom.expected"
    XDG_DATA_HOME="$PWD/custom" "$migrate"
    cmp "$PWD/custom.expected" "$custom"
    test ! -e "$custom.anytype-generated.bak"

    nonNix="$PWD/non-nix/applications/anytype.desktop"
    writeGeneratedEntry "$nonNix" ""
    substituteInPlace "$nonNix" \
      --replace-fail \
        '/nix/store/00000000000000000000000000000000-electron-unwrapped-41.2.0/libexec/electron/electron' \
        '/home/user/Applications/Anytype.AppImage'
    cp "$nonNix" "$PWD/non-nix.expected"
    XDG_DATA_HOME="$PWD/non-nix" "$migrate"
    cmp "$PWD/non-nix.expected" "$nonNix"
    test ! -e "$nonNix.anytype-generated.bak"

    target="$PWD/symlink-target.desktop"
    writeGeneratedEntry "$target" ""
    mkdir -p "$PWD/symlink/applications"
    ln -s "$target" "$PWD/symlink/applications/anytype.desktop"
    XDG_DATA_HOME="$PWD/symlink" "$migrate"
    test -L "$PWD/symlink/applications/anytype.desktop"

    env -u HOME -u XDG_DATA_HOME "$migrate"

    desktop-file-validate "$canonical"
    desktop-file-validate "$compatibility"
    grep -Fqx 'Exec=anytype %U' "$canonical"
    grep -Fqx 'StartupWMClass=anytype' "$canonical"
    if grep -Fqx 'NoDisplay=true' "$canonical"; then
      exit 1
    fi
    grep -Fqx 'NoDisplay=true' "$compatibility"

    touch "$out"
  '';
}
