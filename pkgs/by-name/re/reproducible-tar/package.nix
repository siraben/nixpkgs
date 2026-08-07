{
  lib,
  autoconf-archive,
  coreutils,
  gnutar,
  reproducible-tar,
  runCommand,
  stdenvNoCC,
  writeShellApplication,
  xz,
}:

let
  reproducibleTarText = ''
    usage() {
      echo "Usage: reproducible-tar OUTPUT ROOT [MEMBER...]"
      echo
      echo "Create a reproducible tar archive from MEMBERs below ROOT."
      echo "MEMBER defaults to '.'. SOURCE_DATE_EPOCH must be set."
    }

    if [[ ''${1:-} == --help ]]; then
      usage
      exit 0
    fi

    if (( $# < 2 )); then
      usage >&2
      exit 2
    fi

    output=$1
    root=$2
    shift 2

    if [[ ! ''${SOURCE_DATE_EPOCH:-} =~ ^[0-9]+$ ]]; then
      echo "reproducible-tar: SOURCE_DATE_EPOCH must be a non-negative integer" >&2
      exit 2
    fi

    if [[ ! -d $root ]]; then
      echo "reproducible-tar: ROOT is not a directory: $root" >&2
      exit 2
    fi

    if [[ $output == - ]]; then
      echo "reproducible-tar: OUTPUT must be a file outside ROOT" >&2
      exit 2
    fi

    canonical_root=$(realpath "$root")
    canonical_output=$(realpath --canonicalize-missing "$output")
    if [[ $canonical_output == "$canonical_root" || $canonical_output == "$canonical_root"/* ]]; then
      echo "reproducible-tar: OUTPUT must be outside ROOT" >&2
      exit 2
    fi

    if (( $# == 0 )); then
      members=(.)
    else
      members=("$@")
    fi

    for member in "''${members[@]}"; do
      case "$member" in
        "" | /* | .. | ../* | */.. | */../*)
          echo "reproducible-tar: MEMBER must stay below ROOT: $member" >&2
          exit 2
          ;;
      esac
    done

    unset TAR_OPTIONS
    export LC_ALL=C
    export TZ=UTC

    tar \
      --create \
      --file="$output" \
      --directory="$root" \
      --format=gnu \
      --sort=name \
      --mtime="@$SOURCE_DATE_EPOCH" \
      --owner=0 \
      --group=0 \
      --numeric-owner \
      -- \
      "''${members[@]}"
  '';

  package = writeShellApplication {
    name = "reproducible-tar";
    text = reproducibleTarText;
    runtimeInputs = [
      coreutils
      gnutar
    ];
    inheritPath = false;

    passthru.tests = {
      archive-contract = runCommand "reproducible-tar-archive-contract" { } ''
        mkdir -p first/dir second/dir

        echo alpha > first/a
        echo beta > first/dir/b
        echo beta > second/dir/b
        echo alpha > second/a
        ln -s a first/link
        ln -s a second/link
        chmod 640 first/a second/a
        chmod 750 first/dir second/dir

        # Deliberately give the two trees different mtimes. The archive epoch is
        # 2000-01-01T00:00:00Z, while the input mtimes are later arbitrary dates.
        archiveEpoch=946684800
        firstMtime=1000000000
        secondMtime=1500000000
        ${lib.getExe' coreutils "touch"} --date="@$firstMtime" first first/a first/dir first/dir/b
        ${lib.getExe' coreutils "touch"} --date="@$secondMtime" second second/a second/dir second/dir/b

        export SOURCE_DATE_EPOCH=$archiveEpoch
        # The helper must ignore caller-supplied global tar behavior.
        export TAR_OPTIONS=--dereference
        ${lib.getExe reproducible-tar} first.tar first
        ${lib.getExe reproducible-tar} second.tar second
        cmp first.tar second.tar

        mkdir unpacked
        ${lib.getExe gnutar} --extract --file=first.tar --directory=unpacked
        test -L unpacked/link
        test "$(${lib.getExe' coreutils "stat"} --format=%Y unpacked/a)" = "$SOURCE_DATE_EPOCH"
        test "$(${lib.getExe' coreutils "stat"} --format=%Y unpacked/dir/b)" = "$SOURCE_DATE_EPOCH"
        ${lib.getExe gnutar} --numeric-owner --verbose --list --file=first.tar > listing
        if grep --invert-match --quiet ' 0/0 ' listing; then
          echo "archive contains a non-root owner or group" >&2
          cat listing >&2
          exit 1
        fi

        echo outside > outside
        if ${lib.getExe reproducible-tar} bad.tar first "$PWD/outside"; then
          echo "absolute MEMBER was accepted" >&2
          exit 1
        fi
        if ${lib.getExe reproducible-tar} bad.tar first ../outside; then
          echo "parent-traversing MEMBER was accepted" >&2
          exit 1
        fi
        if ${lib.getExe reproducible-tar} first/bad.tar first; then
          echo "OUTPUT below ROOT was accepted" >&2
          exit 1
        fi
        if SOURCE_DATE_EPOCH= ${lib.getExe reproducible-tar} bad.tar first; then
          echo "empty SOURCE_DATE_EPOCH was accepted" >&2
          exit 1
        fi

        ${lib.getExe' coreutils "touch"} "$out"
      '';

      gnutar-isolation = runCommand "reproducible-tar-gnutar-isolation" { } ''
        export GNUTAR_REPRODUCIBLE=1
        # 2000-01-01T00:00:00Z. Ordinary tar must not interpret either variable.
        export SOURCE_DATE_EPOCH=946684800

        mkdir source extracted
        echo ordinary > source/file
        ordinaryMtime=1500000000 # An arbitrary time after SOURCE_DATE_EPOCH.
        ${lib.getExe' coreutils "touch"} --date="@$ordinaryMtime" source/file

        ${lib.getExe gnutar} cf ordinary.tar source
        ${lib.getExe gnutar} tf ordinary.tar | grep --quiet '^source/file$'
        ${lib.getExe gnutar} xf ordinary.tar --directory=extracted
        test "$(${lib.getExe' coreutils "stat"} --format=%Y extracted/source/file)" = "$ordinaryMtime"

        mkdir extracted-stream
        ${lib.getExe gnutar} cf - source \
          | ${lib.getExe gnutar} xf - --warning=no-timestamp --directory=extracted-stream
        test -f extracted-stream/source/file

        ${lib.getExe' coreutils "touch"} "$out"
      '';

      source-unpack = stdenvNoCC.mkDerivation {
        pname = "reproducible-tar-source-unpack-test";
        version = "1";
        src = autoconf-archive.src;
        env.GNUTAR_REPRODUCIBLE = "1";
        nativeBuildInputs = [
          gnutar
          xz
        ];
        dontConfigure = true;
        dontBuild = true;
        installPhase = ''
          test -f configure.ac
          test -f m4/ax_check_gl.m4
          ${lib.getExe' coreutils "touch"} "$out"
        '';
      };
    };

    meta = {
      description = "Create tar archives with reproducible metadata and ordering";
      longDescription = ''
        reproducible-tar is a deliberately create-only interface for making
        deterministic GNU tar archives. It requires SOURCE_DATE_EPOCH and
        normalizes entry ordering, timestamps, owners, and groups without
        changing the behavior of the ordinary tar executable.
      '';
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [ siraben ];
      mainProgram = "reproducible-tar";
      platforms = lib.platforms.unix;
    };
  };
in
package
